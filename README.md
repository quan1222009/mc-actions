# Minecraft Server trên GitHub Actions

## Secrets cần tạo (Settings → Secrets and variables → Actions)

| Secret | Mô tả |
|---|---|
| `RCLONE_CONF_BASE64` | Nội dung file `rclone.conf` (đã cấu hình remote Google Drive) mã hoá base64 |
| `RCON_PASSWORD` | Mật khẩu RCON, dùng để script tự `save-off/save-all/save-on` và dừng server đúng giờ |
| `TS_OAUTH_CLIENT_ID` + `TS_OAUTH_SECRET` | Tailscale OAuth client (Settings → OAuth clients trên Tailscale admin console) |
| `TS_AUTHKEY` | (Thay thế cách trên) Tailscale auth key, nên bật "Ephemeral" |

> Nếu dùng `TS_AUTHKEY`: mở `.github/workflows/minecraft-server.yml`, đổi bước "Kết nối Tailscale" sang dùng `authkey: ${{ secrets.TS_AUTHKEY }}` thay vì `oauth-client-id`/`oauth-secret` (dòng ví dụ đã có sẵn dạng comment).

### Tạo `RCLONE_CONF_BASE64`
Trên máy cá nhân:
```
rclone config   # tạo remote tên "gdrive" trỏ tới Google Drive
base64 -w0 ~/.config/rclone/rclone.conf
```
Copy kết quả dán vào secret `RCLONE_CONF_BASE64`.

## Cách hoạt động

- **Tự lặp lại mỗi 4 tiếng**: cuối job gọi GitHub API `workflow_dispatch` để tự khởi động phiên tiếp theo. Vì vậy workflow gần như chạy liên tục, chỉ gián đoạn vài chục giây giữa các phiên (thời gian tải backup + khởi động lại).
- **Giới hạn 4 tiếng/phiên**: `timeout --signal=TERM 4h java ...` trong `scripts/start-server.sh`.
- **Backup định kỳ**: `scripts/backup-loop.sh` chạy nền, mỗi 60 giây (`BACKUP_INTERVAL_SEC`) sẽ `save-off` → nén → upload đè `world-latest.zip` và `full-latest.zip` lên Drive → `save-on`. Vì luôn ghi đè cùng 1 file (không tạo file mới mỗi lần) nên số lượng "file" trên Drive không tăng theo thời gian.
- **Backup lần cuối**: sau khi server chạy đủ 4 tiếng và tự dừng, `scripts/final-backup.sh` chạy thêm **1 lần nữa** (`if: always()`) để đảm bảo trạng thái mới nhất được lưu, kể cả khi lần backup định kỳ gần nhất chưa kịp bắt kịp thay đổi cuối cùng.
- **Khôi phục đầu phiên**: `scripts/restore.sh` tải `full-latest.zip` về và giải nén, nếu chưa có thì tải Paper mới và khởi tạo server mới, đồng thời cài các plugin liệt kê trong `plugins.txt`.
- **Mạng qua Tailscale**: workflow join runner vào tailnet của bạn (cổng 25565 mặc định, không đổi). Sau khi bước "In địa chỉ Tailscale" chạy xong, mở log để lấy IP dạng `100.x.x.x`, dùng IP đó (giữ nguyên cổng 25565) làm địa chỉ server trong Minecraft — chỉ máy nào đã join cùng tailnet mới kết nối được, không public ra internet.
- **Panel điều khiển: MCSManager**. Được cài tự động (`scripts/setup-mcsmanager.sh`), dữ liệu (tài khoản admin, instance đã tạo) được backup/khôi phục qua Drive giống world, nên **chỉ cần setup thủ công 1 lần duy nhất**:
  1. Chạy workflow lần đầu, mở log của step "Cài đặt / khôi phục MCSManager" để lấy mật khẩu admin và IP Tailscale.
  2. Truy cập `http://<IP-Tailscale>:23333`, đăng nhập, đổi mật khẩu.
  3. Tạo 1 instance kiểu **Universal**, working directory trỏ tới thư mục `server/` trong workspace, start command để tham khảo (không bắt buộc bấm Start — xem lưu ý bên dưới).
  4. Từ phiên thứ 2 trở đi, workflow tự khôi phục lại đúng tài khoản + instance này, không cần lặp lại.
- **Lưu ý quan trọng**: server Minecraft **vẫn do `scripts/start-server.sh` khởi động/dừng**, không phải do nút Start/Stop trong MCSManager — để đảm bảo đúng lịch 4 tiếng và không bị 2 tiến trình java tranh nhau 1 cổng. Dùng MCSManager chủ yếu cho:
  - **File Manager**: upload/xoá plugin trong `server/plugins`, sửa `server.properties`, tải file world về máy.
  - Xem log/console (một số bản MCSManager cho theo dõi log file dù process không do nó khởi động).
  Nếu muốn để hẳn MCSManager làm nơi start/stop server, có thể tắt bước `start-server.sh` và bật "auto start" cho instance trong MCSManager, nhưng khi đó cần tự thêm cơ chế dừng đúng giờ (gửi `stop` qua RCON sau 4 tiếng) vì mất phần `timeout` hiện có.

## Lưu ý quan trọng

1. **60 giây/lần backup** là hợp lý cho quota Google Drive API và không tốn CPU đáng kể để nén lại toàn bộ world liên tục.
2. **IP Tailscale đổi mỗi phiên** (mỗi 4 tiếng) vì mỗi lần workflow chạy lại là một runner/node mới. Nếu muốn hostname cố định, dùng `hostname:` cố định trong bước Tailscale (đã đặt sẵn `gh-mc-server`) kết hợp bật MagicDNS trên tailnet — khi đó có thể dùng `gh-mc-server:25565` thay vì phải tra IP mỗi lần.
3. **Chỉ thiết bị đã join cùng tailnet** (cài Tailscale, đăng nhập cùng tài khoản/tổ chức) mới kết nối được vào server hoặc panel — đây là điểm khác biệt so với ngrok: không public, nhưng cần bạn bè cùng chơi cũng cài Tailscale.
4. **Cài plugin cần jar khả dụng qua URL trực tiếp** (Spigot/Modrinth/Hangar thường cho phép). Sau khi cài qua panel, cần gửi lệnh console `reload` (nếu plugin đó hỗ trợ hot-reload) hoặc chờ phiên sau khởi động lại để plugin có hiệu lực đầy đủ.
5. Đây vẫn là **giải pháp chạy trên CI runner dùng chung**, không đảm bảo hiệu năng ổn định như VPS thật — phù hợp để test/chơi tạm, không nên dùng cho server production nhiều người chơi lâu dài.

## File plugins.txt
Đặt ở thư mục gốc repo, mỗi dòng 1 URL file `.jar` plugin sẽ được tự tải khi khởi tạo server mới.
