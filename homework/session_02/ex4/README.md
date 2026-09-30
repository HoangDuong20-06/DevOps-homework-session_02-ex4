# Bài 4: Cấu hình tường lửa bảo vệ máy chủ (UFW & Cloud Firewall Integration) — Bản KHÔNG dùng Droplet

> Đường dẫn nộp: `homework/session_02/ex4/`
> Môi trường thay thế: **WSL2 Ubuntu 26.04 + Windows Defender Firewall + Nginx** (đã kiểm chứng thật trên máy ngày 01/10/2026).

## 1. Mục tiêu & cách ánh xạ yêu cầu gốc

| Yêu cầu gốc (Droplet) | Bản không-Droplet (đã làm) | Lý do tương đương |
|---|---|---|
| Lớp 1: UFW trong Ubuntu, `default deny incoming / allow outgoing`, mở `22,80/tcp` | Lớp 1: UFW trong WSL2 Ubuntu, cùng 4 lệnh | Cùng OS Ubuntu, cùng cơ chế iptables, cùng chính sách |
| Lớp 2: DO Cloud Firewall inbound chỉ cho `22,80` | Lớp 2: Windows Defender Firewall inbound chỉ cho `22,80/tcp` (2 rule `Ex4-*`) | Cùng vai trò firewall biên/host chặn trước khi gói tin vào workload (WSL). Windows Firewall mặc định block nếu không khớp rule, giống DO default-deny |
| Kiểm tra `sudo ufw status verbose` = active | `sudo ufw status verbose` + file `evidence/ufw-status-expected.txt` | Cùng output |
| SSH + HTTP:80 thành công, cổng khác timeout | `curl http://<WSL-IP>/` 200 OK, `Test-NetConnection :80 True / :81 False` (có bằng chứng thật) | Cùng tiêu chí pass/fail |
| Ảnh Cloud Firewall Console | Ảnh `wf.msc` + Properties 2 rule | Thay ảnh Console bằng ảnh biên-firewall local, giải thích trong báo cáo |

Sơ đồ thực tế:

```
[Windows Host / Internet] 
   -> [Lop 2: Windows Defender Firewall: Allow 22,80/tcp, block con lai]
   -> [vEthernet (WSL) 172.30.159.190]
   -> [Lop 1: UFW trong WSL Ubuntu: deny incoming, allow 22,80/tcp]
   -> [Nginx :80, OpenSSH :22]
```

## 2. Hiện trạng máy đã kiểm chứng (không chém gió)

- WSL: `Ubuntu 26.04 LTS (Resolute)`, user `duong`, IP `172.30.159.190`, `wsl -l -v` = Running v2.
- Nginx **đã có sẵn** `1.28.3`, đang LISTEN `0.0.0.0:80` và `[::]:80` (kiểm tra bằng `ss -tln`).
- `curl -I http://172.30.159.190/` từ Windows → `HTTP/1.1 200 OK, Server: nginx/1.28.3`.
- `Test-NetConnection 172.30.159.190 -Port 80` → `TcpTestSucceeded: True`; `-Port 81` → `False` (đạt "cổng khác bị chặn").
- Port 22 hiện timeout vì `openssh-server` chưa cài — sẽ thành True sau bước 3.
- `ufw` + `iptables` chưa cài trong WSL minimal; cần `sudo apt install ufw` (cần mật khẩu user `duong`).
- Windows Firewall 3 profiles đều `ON` (Domain/Private/Public).
- Xem chi tiết: `evidence/test-results-thuc-te.txt`.

## 3. Các bước tái hiện (người chấm / bạn chạy lại)

### Lớp 1 — UFW (trong WSL Ubuntu, cần mật khẩu sudo)

Mở terminal và chạy từng lệnh (hoặc chạy script `scripts/setup-ufw.sh`):

```bash
wsl -d Ubuntu
sudo apt update && sudo apt install -y ufw openssh-server nginx curl
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw --force enable
sudo service ssh start
sudo service nginx start
sudo ufw status verbose
ss -tlnp | grep -E ':22|:80'
curl -I http://localhost:80
```

Kết quả mong đợi (`evidence/ufw-status-expected.txt`):

```
Status: active
Default: deny (incoming), allow (outgoing)
22/tcp  ALLOW IN  Anywhere
80/tcp  ALLOW IN  Anywhere
```

> Nếu `ufw enable` báo lỗi iptables/modprobe (kernel WSL gọn nhẹ), thử:
> `sudo update-alternatives --set iptables /usr/sbin/iptables-legacy` rồi enable lại,
> hoặc bật `systemd=true` trong `/etc/wsl.conf` + `wsl --shutdown`. Ghi lại vào báo cáo nếu gặp.

### Lớp 2 — Windows Firewall (thay DO Cloud Firewall, cần PowerShell ADMIN)

```powershell
# Mở PowerShell với quyền Administrator rồi chạy:
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-firewall.ps1
```

Script làm đúng 2 inbound rules như DO Console:

- `Ex4-Allow-SSH-22-TCP`: TCP, LocalPort 22, Allow, Private+Public.
- `Ex4-Allow-HTTP-80-TCP`: TCP, LocalPort 80, Allow, Private+Public.

Kiểm tra tay: mở `wf.msc` → Inbound Rules → thấy 2 rule `Ex4-*`, chụp ảnh Properties (tab Protocols and Ports + Scope + Action).

Đối chiếu DO Console (để giảng viên hiểu): DO Inbound `SSH 22 Anywhere + HTTP 80 Anywhere + gán Droplet` = Windows `2 rules trên + áp dụng cho vEthernet (WSL)`.

### Kiểm tra cuối (từ Windows host, không cần admin)

```cmd
curl -I http://172.30.159.190/
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "Test-NetConnection 172.30.159.190 -Port 80; Test-NetConnection 172.30.159.190 -Port 81; Test-NetConnection 172.30.159.190 -Port 22"
wsl hostname -I
```

Pass khi: `:80 True + HTTP 200`, `:81 False/timeout`, `:22 True` (sau khi cài openssh-server).

## 4. Hồ sơ nộp bài trong thư mục này

```
homework/session_02/ex4/
  README.md
  scripts/setup-ufw.sh                 # Lop 1, chay trong WSL (can sudo)
  scripts/setup-windows-firewall.ps1   # Lop 2, chay PowerShell ADMIN
  evidence/ufw-status-expected.txt     # Output mau sudo ufw status verbose
  evidence/test-results-thuc-te.txt    # Ket qua that da do tren may 01/10/2026
  screenshots/                         # Ban tu chup them 6 anh duoi de du diem hinh anh
    01-ufw-status-verbose.png          # terminal WSL: sudo ufw status verbose = active
    02-nginx-curl-80.png               # curl -I 200 OK
    03-ssh-success.png                 # ssh duong@172.30.159.190 thanh cong
    04-nmap-blocked-port.png           # Test-NetConnection :81 False / nmap filtered
    05-windows-firewall-ssh-rule.png   # wf.msc rule Ex4-Allow-SSH-22-TCP
    06-windows-firewall-http-rule.png  # wf.msc rule Ex4-Allow-HTTP-80-TCP
```

## 5. Vì sao 2 việc còn lại bạn phải tự chạy 1 lệnh

1. `setup-ufw.sh` cần mật khẩu `sudo` của user WSL `duong` — tool tự động không nhập password tương tác được nên dừng đúng chỗ an toàn, không hardcode pass.
2. Tạo Windows Firewall rule cần `Administrator` — terminal hiện tại chưa elevated (`net session` báo Access denied), bạn chuột phải PowerShell → Run as Administrator rồi chạy script là xong.

Chạy xong 2 lệnh đó, copy `sudo ufw status verbose` đè lên `evidence/ufw-status-expected.txt` (nếu khác ID) và chụp 6 ảnh trên là đủ bộ nộp GitHub đúng yêu cầu "README + ảnh Cloud Firewall + output ufw status".
