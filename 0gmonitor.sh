#!/bin/bash

# --- Warna ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- Logo ---
echo -e '\e[34m'
echo -e '$$\   $$\ $$$$$$$$\      $$$$$$$$\           $$\                                       $$\     '
echo -e '$$$\  $$ |\__$$  __|     $$  _____|          $$ |                                      $$ |    '
echo -e '$$$$\ $$ |   $$ |        $$ |      $$\   $$\ $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$$\ $$$$$$\   '
echo -e '$$ $$\$$ |   $$ |$$$$$$\ $$$$$\    \$$\ $$  |$$  __$$\  \____$$\ $$ |  $$ |$$  _____|\_$$  _|  '
echo -e '$$ \$$$$ |   $$ |\______|$$  __|    \$$$$  / $$ |  $$ | $$$$$$$ |$$ |  $$ |\$$$$$$\    $$ |    '
echo -e '$$ |\$$$ |   $$ |        $$ |       $$  $$<  $$ |  $$ |$$  __$$ |$$ |  $$ | \____$$\   $$ |$$\ '
echo -e '$$ | \$$ |   $$ |        $$$$$$$$\ $$  /\$$\ $$ |  $$ |\$$$$$$$ |\$$$$$$  |$$$$$$$  |  \$$$$  |'
echo -e '\__|  \__|   \__|        \________|\__/  \__|\__|  \__| \_______| \______/ \_______/    \____/ '
echo -e '\e[0m'
echo -e "Join our Telegram channel: https://t.me/NTExhaust"
sleep 3

# --- Konfigurasi ---
STORAGE_RPC_PORT="5678"
STORAGE_RPC="http://localhost:$STORAGE_RPC_PORT"
PARENT_RPC="https://evmrpc-testnet.0g.ai"
CHECK_INTERVAL=300  # 5 menit
THRESHOLD=300       # Selisih maksimum

# --- Opsional: Kirim ke Telegram jika ingin ---
BOT_TOKEN=""     # ← isi jika ingin kirim ke Telegram
CHAT_ID=""       # ← isi jika ingin kirim ke Telegram

# --- Fungsi konversi hex ke desimal ---
hex_to_dec() {
    printf "%d" "$((16#${1#0x}))"
}

# --- Fungsi kirim pesan Telegram ---
send_telegram_log() {
    local status="$1"
    local msg=$(cat <<EOF
📢 *NT-Exhaust Report*
🧠 *0G Storage Node*

📦 *Storage:* \`$STORAGE_HEIGHT\`
🌐 *Parent:* \`$PARENT_HEIGHT\`
🔁 *Selisih:* \`$DIFF\`
$status
EOF
)
    if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$msg" \
            -d parse_mode="Markdown" > /dev/null
    fi
}

# --- Loop utama ---
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$TIMESTAMP] ${CYAN}⏳ Mengecek block height...${NC}"

    STORAGE_HEIGHT=$(curl -s -X POST "$STORAGE_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}' | jq -r '.result.logSyncHeight')

    PARENT_HEX=$(curl -s -X POST "$PARENT_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')

    PARENT_HEIGHT=$(hex_to_dec "$PARENT_HEX")

    if [[ ! $STORAGE_HEIGHT =~ ^[0-9]+$ ]] || [[ ! $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
        echo -e "[$TIMESTAMP] ${RED}❌ Gagal mendapatkan block height!${NC} | Storage: $STORAGE_HEIGHT | Parent(hex): $PARENT_HEX"
        sleep $CHECK_INTERVAL
        continue
    fi

    DIFF=$((PARENT_HEIGHT - STORAGE_HEIGHT))
    echo -e "[$TIMESTAMP] ${CYAN}📦 Storage:${NC} $STORAGE_HEIGHT | ${CYAN}🌐 Parent:${NC} $PARENT_HEIGHT | ${YELLOW}🔁 Selisih:${NC} $DIFF"

    if (( DIFF > THRESHOLD )); then
        echo -e "[$TIMESTAMP] ${RED}⚠️ STORAGE_NODE TERTINGGAL! Restarting zgs...${NC}"
        send_telegram_log "⚠️ *Status:* _STORAGE_NODE TERTINGGAL — Restarting zgs..._"
        systemctl restart zgs
    else
        echo -e "[$TIMESTAMP] ${GREEN}✅ STORAGE_NODE OK${NC}"
        send_telegram_log "✅ *Status:* STORAGE_NODE OK"
    fi

    sleep $CHECK_INTERVAL
done
