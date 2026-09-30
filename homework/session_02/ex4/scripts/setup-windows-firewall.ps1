#Requires -RunAsAdministrator
# Bai 4 - Lop 2: Windows Defender Firewall (thay DigitalOcean Cloud Firewall)
# Chay trong PowerShell ADMIN:  powershell -ExecutionPolicy Bypass -File setup-windows-firewall.ps1
# Y tuong: DO Cloud Firewall (bien mang) -> Windows Firewall (bien/host truoc khi vao WSL)

$ErrorActionPreference = 'Stop'

Write-Host "=== 1. Thong tin WSL IP ==="
$wslIp = (wsl hostname -I).Trim().Split()[0]
Write-Host "WSL IP: $wslIp"

Write-Host "=== 2. Xoa rule cu (neu chay lai) ==="
Get-NetFirewallRule -DisplayName "Ex4-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

Write-Host "=== 3. Tao Inbound Rule: SSH 22/tcp ==="
New-NetFirewallRule -DisplayName "Ex4-Allow-SSH-22-TCP" `
  -Description "Bai4 Lop2: cho phep SSH giong DO Cloud Firewall inbound SSH" `
  -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow `
  -Profile Private,Public -Enabled True

Write-Host "=== 4. Tao Inbound Rule: HTTP 80/tcp ==="
New-NetFirewallRule -DisplayName "Ex4-Allow-HTTP-80-TCP" `
  -Description "Bai4 Lop2: cho phep HTTP giong DO Cloud Firewall inbound HTTP" `
  -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow `
  -Profile Private,Public -Enabled True

Write-Host "=== 5. Kiem tra (mac dinh Windows Firewall block neu khong khop rule) ==="
Get-NetFirewallRule -DisplayName "Ex4-*" | Get-NetFirewallPortFilter | Format-Table InstanceID, Protocol, LocalPort
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction

Write-Host "=== 6. Test ket noi ==="
Test-NetConnection $wslIp -Port 80 | Format-List TcpTestSucceeded, RemoteAddress, RemotePort
Test-NetConnection $wslIp -Port 81 -WarningAction SilentlyContinue | Format-List TcpTestSucceeded, RemoteAddress, RemotePort
Test-NetConnection $wslIp -Port 22 -WarningAction SilentlyContinue | Format-List TcpTestSucceeded, RemoteAddress, RemotePort

Write-Host "DONE. Chup man hinh wf.msc -> Inbound Rules co 2 rule Ex4-* de nop bai."
