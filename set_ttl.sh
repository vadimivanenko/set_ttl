#!/bin/bash

# ─────────────────────────────────────────────────────────
#  Настройка сети для macOS: TTL и MTU
#  Применяется к Wi-Fi (en0) и Ethernet (en1)
# ─────────────────────────────────────────────────────────

PLIST_PATH="/Library/LaunchDaemons/set-ttl.plist"
INTERFACES=("en0" "en1")

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Запусти скрипт с sudo: sudo bash set_ttl.sh${NC}"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Настройка сети macOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── TTL ──────────────────────────────────────
read -p "Введи значение TTL [по умолчанию 65]: " TTL
TTL=${TTL:-65}

if ! [[ "$TTL" =~ ^[0-9]+$ ]] || [ "$TTL" -lt 1 ] || [ "$TTL" -gt 255 ]; then
  echo -e "${RED}❌ TTL должен быть числом от 1 до 255.${NC}"
  exit 1
fi

# ── MTU ──────────────────────────────────────
read -p "Введи значение MTU [по умолчанию 1500]: " MTU
MTU=${MTU:-1500}

if ! [[ "$MTU" =~ ^[0-9]+$ ]] || [ "$MTU" -lt 576 ] || [ "$MTU" -gt 9000 ]; then
  echo -e "${RED}❌ MTU должен быть числом от 576 до 9000.${NC}"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Применяю настройки..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Применить TTL сразу ───────────────────────
sysctl -w net.inet.ip.ttl=$TTL > /dev/null
sysctl -w net.inet6.ip6.hlim=$TTL > /dev/null
echo -e "${GREEN}✅ TTL установлен: $TTL (IPv4 и IPv6)${NC}"

# ── Применить MTU ─────────────────────────────
for IFACE in "${INTERFACES[@]}"; do
  if ifconfig "$IFACE" &>/dev/null; then
    ifconfig "$IFACE" mtu $MTU
    echo -e "${GREEN}✅ MTU установлен: $MTU → $IFACE${NC}"
  fi
done

# ── Создать Launch Daemon ─────────────────────
if [ -f "$PLIST_PATH" ]; then
  launchctl unload "$PLIST_PATH" 2>/dev/null
  rm -f "$PLIST_PATH"
fi

MTU_CMDS=""
for IFACE in "${INTERFACES[@]}"; do
  MTU_CMDS="$MTU_CMDS ifconfig $IFACE mtu $MTU 2>/dev/null;"
done

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>set-ttl</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>sysctl -w net.inet.ip.ttl=$TTL; sysctl -w net.inet6.ip6.hlim=$TTL; $MTU_CMDS</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

chown root:wheel "$PLIST_PATH"
chmod 644 "$PLIST_PATH"
launchctl load "$PLIST_PATH"
echo -e "${GREEN}✅ Launch Daemon создан (сохранится после перезагрузки)${NC}"

# ── Итог ─────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Текущие значения:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  IPv4 TTL  : $(sysctl -n net.inet.ip.ttl)"
echo "  IPv6 Hop  : $(sysctl -n net.inet6.ip6.hlim)"
for IFACE in "${INTERFACES[@]}"; do
  if ifconfig "$IFACE" &>/dev/null; then
    CURRENT_MTU=$(ifconfig "$IFACE" | grep mtu | awk '{print $NF}')
    echo "  MTU $IFACE  : $CURRENT_MTU"
  fi
done
echo ""
echo -e "${GREEN}⚡ Все настройки сохранятся после перезагрузки.${NC}"
echo ""
