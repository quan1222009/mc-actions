#!/usr/bin/env bash
cd "$(dirname "$0")/../server"

echo "Đang thực hiện backup lần cuối trước khi phiên kết thúc..."

zip -r -q ../world-latest.zip world world_nether world_the_end 2>/dev/null || true
zip -r -q ../full-latest.zip . -x "*.zip"

rclone copyto ../world-latest.zip "$DRIVE_REMOTE/world-latest.zip"
rclone copyto ../full-latest.zip "$DRIVE_REMOTE/full-latest.zip"

if [ -d /opt/mcsmanager ]; then
  sudo zip -r -q /tmp/mcsmanager-data-latest.zip \
    /opt/mcsmanager/web/data /opt/mcsmanager/daemon/data 2>/dev/null || true
  rclone copyto /tmp/mcsmanager-data-latest.zip "$DRIVE_REMOTE/mcsmanager-data-latest.zip"
  rm -f /tmp/mcsmanager-data-latest.zip
fi

echo "Đã lưu bản cuối lên Drive: world-latest.zip, full-latest.zip và mcsmanager-data-latest.zip"
