#!/usr/bin/env bash
# Vòng lặp backup: mỗi BACKUP_INTERVAL_SEC giây, nén world + toàn bộ server,
# đẩy đè lên Drive (1 file duy nhất mỗi loại -> không tích luỹ, tránh rate limit).

INTERVAL="${BACKUP_INTERVAL_SEC:-30}"
cd "$(dirname "$0")/../server"

do_backup() {
  # Tạm tắt auto-save để tránh nén trúng lúc file đang được ghi
  python3 ../scripts/rcon.py "save-off" >/dev/null 2>&1 || true
  python3 ../scripts/rcon.py "save-all" >/dev/null 2>&1 || true
  sleep 1

  # Zip riêng world (chỉ các thư mục world)
  zip -r -q ../world-latest.zip world world_nether world_the_end 2>/dev/null || true

  # Zip toàn bộ thư mục server (world + plugins + config + logs...)
  zip -r -q ../full-latest.zip . -x "*.zip"

  python3 ../scripts/rcon.py "save-on" >/dev/null 2>&1 || true

  # Đẩy đè lên Drive - dùng --update để chỉ upload nếu có thay đổi, giảm số request thật sự gửi đi
  rclone copyto ../world-latest.zip "$DRIVE_REMOTE/world-latest.zip" --update
  rclone copyto ../full-latest.zip "$DRIVE_REMOTE/full-latest.zip" --update

  # Backup dữ liệu MCSManager (tài khoản, instance đã tạo...) - thư mục nhỏ, ít tốn kém
  if [ -d /opt/mcsmanager ]; then
    sudo zip -r -q /tmp/mcsmanager-data-latest.zip \
      /opt/mcsmanager/web/data /opt/mcsmanager/daemon/data 2>/dev/null || true
    rclone copyto /tmp/mcsmanager-data-latest.zip "$DRIVE_REMOTE/mcsmanager-data-latest.zip" --update
    rm -f /tmp/mcsmanager-data-latest.zip
  fi
}

while true; do
  do_backup
  sleep "$INTERVAL"
done
