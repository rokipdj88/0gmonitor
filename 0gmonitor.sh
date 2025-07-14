#!/bin/bash

# --- Set lingkungan UTF-8 ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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
CHECK_INTERVAL=300
WALLET_ADDRESS="ADDRESS"

# --- Token & Chat ID Telegram ---
BOT_TOKEN="${BOT_TOKEN:-}"
CHAT_ID="${CHAT_ID:-}"

# --- Escape MarkdownV2 ---
escape_markdown_v2() {
    echo "$1" | sed -e 's/\\/\\\\/g' \
                   -e 's/\./\\./g' \
                   -e 's/-/\\-/g' \
                   -e 's/(/\\(/g' \
                   -e 's/)/\\)/g' \
                   -e 's/\[/\\[/g' \
                   -e 's/\]/\\]/g' \
                   -e 's/{/\\{/g' \
                   -e 's/}/\\}/g' \
                   -e 's/=/\\=/g' \
                   -e 's/!/\\!/g' \
                   -e 's/\*/\\*/g' \
                   -e 's/_/\\_/g' \
                   -e 's/`/\\`/g' \
                   -e 's/>/\\>/g' \
                   -e 's/#/\\#/g' \
                   -e 's/\+/\\+/g' \
                   -e 's/|/\\|/g' \
                   -e 's/~\\/\\~/g'
}


# --- Kirim pesan ke Telegram ---
send_telegram_log() {
    local status_raw="$1"
    local raw_msg=$(cat <<EOF
📢 *NT-Exhaust Report*
🧠 0G Storage Node

📦 Storage: \`$STORAGE_HEIGHT\`
🌐 Parent: \`$PARENT_HEIGHT\`
🔁 Selisih: \`$DIFF\`
💰 A0GI Balance: \`$A0GI_BALANCE A0GI\`
$status_raw
EOF
)
    # Escape semua karakter untuk MarkdownV2
    local msg=$(escape_markdown_v2 "$raw_msg")

    # Filter karakter non-UTF-8 agar tidak error ke Telegram
    local msg_cleaned=$(echo "$msg" | iconv -f utf-8 -t utf-8 -c)

    if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
        echo -e "${YELLOW}[DEBUG] Mengirim pesan ke Telegram...${NC}"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            --data-urlencode "chat_id=$CHAT_ID" \
            --data-urlencode "text=$msg_cleaned" \
            -d parse_mode="MarkdownV2" \
            -w "\n[HTTP STATUS: %{http_code}]\n"
    else
        echo -e "${YELLOW}[INFO] BOT_TOKEN atau CHAT_ID belum diatur. Lewatkan kirim pesan.${NC}"
    fi
}


# --- Hex ke Desimal ---
hex_to_dec() {
    printf "%d" "$((16#${1#0x}))"
}

# --- Ambil saldo A0GI ---
get_a0gi_balance() {
    local BAL_HEX=$(curl -s -X POST "$PARENT_RPC" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$WALLET_ADDRESS\", \"latest\"],\"id\":1}" | jq -r '.result')

    if [[ "$BAL_HEX" == "null" || -z "$BAL_HEX" ]]; then
        echo "0"
    else
        local BAL_DEC=$(printf "%d" "$((16#${BAL_HEX#0x}))")
        echo "scale=6; $BAL_DEC / 1000000000000000000" | bc
    fi
}

# --- Monitoring Loop ---
LAST_DIFF=0

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

    A0GI_BALANCE=$(get_a0gi_balance)
    echo -e "[$TIMESTAMP] ${CYAN}💰 Saldo A0GI:${NC} $A0GI_BALANCE A0GI"

    if (( DIFF > 500 )); then
        if (( DIFF >= LAST_DIFF )); then
            echo -e "[$TIMESTAMP] ${RED}⚠️ STORAGE_NODE Semakin tertinggal ($DIFF ≥ $LAST_DIFF) — Restarting zgs...${NC}"
            send_telegram_log "⚠️ Status: STORAGE_NODE Semakin tertinggal ($DIFF ≥ $LAST_DIFF) — Restarting zgs..."
            systemctl restart zgs
        else
            echo -e "[$TIMESTAMP] ${YELLOW}⚠️ Tertinggal tetapi mulai mengejar ($DIFF < $LAST_DIFF) — Tidak restart.${NC}"
            send_telegram_log "🟡 Status: STORAGE_NODE Tertinggal tapi mulai mengejar ($DIFF < $LAST_DIFF) — Tidak restart"
        fi
    else
        echo -e "[$TIMESTAMP] ${GREEN}✅ STORAGE_NODE OK${NC}"
        send_telegram_log "✅ Status: STORAGE_NODE OK"
    fi

    LAST_DIFF=$DIFF
    sleep $CHECK_INTERVAL
done
