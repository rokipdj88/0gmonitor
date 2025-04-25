#!/bin/bash

# --- Konfigurasi ---
STORAGE_RPC_PORT="5678"
STORAGE_RPC="http://localhost:$STORAGE_RPC_PORT"
PARENT_RPC="https://evmrpc-testnet.0g.ai"
CHECK_INTERVAL=300  # dalam detik (5 menit)
THRESHOLD=300       # selisih maksimal antara parent dan storage

# --- Fungsi konversi hexa ke desimal ---
hex_to_dec() {
    printf "%d" "$((16#${1#0x}))"
}

# --- Loop utama ---
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] ⏳ Mengecek block height..."

    # Ambil storage height
    STORAGE_HEIGHT=$(curl -s -X POST "$STORAGE_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}' | jq -r '.result.logSyncHeight')

    # Ambil parent height dari EVM RPC
    PARENT_HEX=$(curl -s -X POST "$PARENT_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')

    PARENT_HEIGHT=$(hex_to_dec "$PARENT_HEX")

    # Validasi angka
    if [[ ! $STORAGE_HEIGHT =~ ^[0-9]+$ ]] || [[ ! $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
        echo "[$TIMESTAMP] ❌ Gagal mendapatkan block height! | Storage: $STORAGE_HEIGHT | Parent(hex): $PARENT_HEX"
        sleep $CHECK_INTERVAL
        continue
    fi

    # Hitung selisih
    DIFF=$((PARENT_HEIGHT - STORAGE_HEIGHT))

    echo "[$TIMESTAMP] 📦 Storage: $STORAGE_HEIGHT | 🌐 Parent: $PARENT_HEIGHT | 🔁 Selisih: $DIFF"

    if (( DIFF > THRESHOLD )); then
        echo "[$TIMESTAMP] ⚠️ STORAGE_NODE TERTINGGAL! Restarting zgs..."
        systemctl restart zgs
    else
        echo "[$TIMESTAMP] ✅ STORAGE_NODE OK"
    fi

    sleep $CHECK_INTERVAL
done
