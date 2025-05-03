#!/data/data/com.termux/files/usr/bin/bash

FILE="/sdcard/roblox_status/status.txt"
THRESHOLD=120

while true; do
    if [ -f "$FILE" ]; then
        LAST=$(cat "$FILE")
        NOW=$(date +%s)
        DIFF=$((NOW - LAST))

        if [ "$DIFF" -gt "$THRESHOLD" ]; then
            echo "⚠️ Mất tín hiệu trong $DIFF giây. Đang rejoin..."
            # Gọi lệnh rejoin ở đây
        else
            echo "✅ Vẫn online ($DIFF giây trước)"
        fi
    else
        echo "❌ File status không tồn tại!"
    fi
    sleep 300
done
