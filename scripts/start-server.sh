#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../server"

HOURS="${SESSION_HOURS:-4}"
SECONDS_LIMIT=$((HOURS * 3600))

echo "Server sẽ chạy trong ${HOURS} tiếng rồi tự dừng."

# timeout gửi SIGTERM khi hết giờ -> Paper/Spigot bắt SIGTERM và tự lưu + tắt an toàn
timeout --signal=TERM "${SECONDS_LIMIT}s" java -Xmx6G -Xms2G -jar server.jar --nogui || true

echo "Server đã dừng (hết 4 tiếng hoặc crash)."
