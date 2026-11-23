# 핑거벨 인터넷 전화·문자 서버(Asterisk)를 Docker로 켭니다.
# 같은 Wi-Fi의 휴대폰 앱이 이 PC의 LAN IP로 등록(ws://<IP>:8088/ws)하고 서로 전화·문자합니다.
[CmdletBinding()]
param(
    # 휴대폰이 닿는 이 PC의 IP. 비우면 기본 게이트웨이가 있는 어댑터의 IPv4를 씁니다.
    [string]$LanIp
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop이 필요합니다: https://www.docker.com/products/docker-desktop/'
}
if (-not $LanIp) {
    $adapter = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
    if ($adapter) { $LanIp = @($adapter.IPv4Address)[0].IPAddress }
}
if (-not $LanIp) { throw 'LAN IP를 찾지 못했습니다. -LanIp 192.168.0.10 처럼 지정하세요.' }

$env:LAN_IP = $LanIp
Write-Host "Asterisk: ws://${LanIp}:8088/ws (휴대폰 앱은 FINGERBELL_API_URL=http://${LanIp}:8765 로 실행)"
Write-Host 'Windows 방화벽이 묻으면 Docker의 8088/tcp, 10000-10049/udp를 허용하세요.'
docker compose -f (Join-Path $PSScriptRoot 'asterisk\docker-compose.yml') up --build
if ($LASTEXITCODE -ne 0) { throw 'Asterisk 실행에 실패했습니다.' }
