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

  # Tải server jar (Paper) lần đầu - dùng PaperMC API v3
  UA="mc-actions/1.0 (https://github.com/${GITHUB_REPOSITORY})"

  MC_VERSION=$(curl -s -H "User-Agent: $UA" https://fill.papermc.io/v3/projects/paper \
    | python3 -c "import sys,json;d=json.load(sys.stdin);v=d['versions'];k=list(v.keys())[0];print(v[k][0])")

  BUILDS_JSON=$(curl -s -H "User-Agent: $UA" "https://fill.papermc.io/v3/projects/paper/versions/$MC_VERSION/builds")

  DOWNLOAD_URL=$(echo "$BUILDS_JSON" | python3 -c "
import sys, json
builds = json.load(sys.stdin)
stable = [b for b in builds if b['channel'] == 'STABLE']
pick = stable[0] if stable else builds[0]
print(pick['downloads']['server:default']['url'])
")

  curl -o server.jar "$DOWNLOAD_URL"

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
    [[ "$url" == \#* ]] && continue
    filename=$(basename "$url")
    if [ ! -f "plugins/$filename" ]; then
      echo "Tải plugin: $filename"
      curl -sL -o "plugins/$filename" "$url"
    fi
  done < "../plugins.txt"
fi
