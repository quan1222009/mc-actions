#!/usr/bin/env bash
set -e

mkdir -p server
cd server

echo "Kiểm tra bản backup toàn bộ server trên Drive..."
if rclone lsf "$DRIVE_REMOTE/full-latest.zip" >/dev/null 2>&1; then
  echo "Tìm thấy full-latest.zip, đang tải về..."
  rclone copy "$DRIVE_REMOTE/full-latest.zip" .
  unzip -o -q full-latest.zip
  rm -f full-latest.zip
  echo "Đã khôi phục toàn bộ server."
else
  echo "Chưa có backup nào, đây là phiên khởi tạo mới."

  # Tải server jar (Paper) lần đầu - đổi URL/version theo nhu cầu
  BUILD=$(curl -s https://api.papermc.io/v2/projects/paper | python3 -c "import sys,json;print(json.load(sys.stdin)['versions'][-1])")
  LATEST_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$BUILD" | python3 -c "import sys,json;print(json.load(sys.stdin)['builds'][-1])")
  curl -o server.jar "https://api.papermc.io/v2/projects/paper/versions/$BUILD/builds/$LATEST_BUILD/downloads/paper-$BUILD-$LATEST_BUILD.jar"

  echo "eula=true" > eula.txt
  mkdir -p plugins

  cat > server.properties <<EOF
enable-rcon=true
rcon.port=25575
rcon.password=${RCON_PASSWORD}
EOF
fi

# Cài các plugin có trong danh sách plugins.txt (mỗi dòng 1 URL jar), nếu chưa có
if [ -f "../plugins.txt" ]; then
  echo "Cài plugin theo danh sách plugins.txt..."
  mkdir -p plugins
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    filename=$(basename "$url")
    if [ ! -f "plugins/$filename" ]; then
      echo "Tải plugin: $filename"
      curl -sL -o "plugins/$filename" "$url"
    fi
  done < "../plugins.txt"
fi
