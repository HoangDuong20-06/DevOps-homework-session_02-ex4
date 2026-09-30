#!/bin/bash
# Bai 4 - Lop 1: UFW trong WSL2 Ubuntu (thay UFW tren Droplet)
# Chay trong WSL:  wsl -d Ubuntu
# Yeu cau nhap mat khau sudo cua user WSL (vd: duong)
set -e

echo "=== 1. Cai dat UFW + dich vu ==="
sudo apt update
sudo apt install -y ufw openssh-server nginx curl

echo "=== 2. Reset + chinh sach mac dinh ==="
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "=== 3. Mo cong 22/tcp (SSH) va 80/tcp (HTTP) ==="
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'

echo "=== 4. Bat firewall ==="
sudo ufw --force enable

echo "=== 5. Khoi dong dich vu demo ==="
sudo service ssh start || sudo service ssh restart
sudo service nginx start || sudo service nginx restart
ss -tlnp | grep -E ':22|:80' || ss -tln

echo "=== 6. Kiem tra ==="
sudo ufw status verbose | tee ~/ufw-status.txt
curl -I http://localhost:80 || true

echo "DONE. Copy ~/ufw-status.txt ra Windows de nop bai."
