#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

MCSM_DIR="/opt/mcsmanager"
FIRST_TIME=false

if [ ! -d "$MCSM_DIR" ]; then
  echo "Chưa cài MCSManager, tiến hành cài đặt..."
  sudo su -c "wget -qO- https://script.mcsmanager.com/setup.sh | bash"
  FIRST_TIME=true
fi

# Khôi phục dữ liệu MCSManager đã lưu (tài khoản admin, instance đã tạo, v.v.) nếu có
if rclone lsf "$DRIVE_REMOTE/mcsmanager-data-latest.zip" >/dev/null 2>&1; then
  echo "Tìm thấy dữ liệu MCSManager đã lưu, đang khôi phục..."
  rclone copy "$DRIVE_REMOTE/mcsmanager-data-latest.zip" /tmp/
  sudo systemctl stop mcsm-web mcsm-daemon 2>/dev/null || true
  sudo unzip -o -q /tmp/mcsmanager-data-latest.zip -d /
  rm -f /tmp/mcsmanager-data-latest.zip
  FIRST_TIME=false
  echo "Đã khôi phục dữ liệu MCSManager (tài khoản/instance cũ vẫn còn)."
fi

sudo systemctl start mcsm-daemon
sleep 3
sudo systemctl start mcsm-web
sleep 3

TS_IP=$(tailscale ip -4 2>/dev/null || echo "chưa xác định")
echo "===================================================="
echo "Panel MCSManager: http://${TS_IP}:23333"
echo "===================================================="

if [ "$FIRST_TIME" = true ]; then
  echo ""
  echo ">>> LẦN ĐẦU CÀI ĐẶT - cần làm thủ công 1 lần <<<"
  echo "1. Mật khẩu admin mặc định được in trong log daemon bên dưới, hoặc xem:"
  sudo journalctl -u mcsm-daemon -n 50 --no-pager | grep -i -A2 "password\|admin" || true
  echo "2. Đăng nhập tại http://${TS_IP}:23333"
  echo "3. Tạo 1 instance kiểu 'Universal/Minecraft', trỏ working directory tới:"
  echo "   $(pwd)/server"
  echo "   Start command: java -Xmx6G -Xms2G -jar server.jar --nogui"
  echo "4. KHÔNG cần bấm Start trong MCSManager để chạy server - script start-server.sh"
  echo "   của workflow vẫn là nơi khởi động/dừng java để đảm bảo đúng lịch 4 tiếng."
  echo "   Dùng MCSManager chủ yếu để: quản lý file/plugin (tab File Manager) và xem log."
  echo "5. Sau khi tạo xong instance, không cần làm gì thêm - từ phiên sau workflow sẽ"
  echo "   tự khôi phục lại đúng cấu hình này."
fi
