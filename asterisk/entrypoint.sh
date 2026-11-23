#!/bin/sh
set -e
# 휴대폰은 컨테이너 IP(172.x)에 닿지 못하므로, 음성(ICE) 후보를 이 PC의 LAN IP로 바꿔 알립니다.
: "${LAN_IP:?LAN_IP에 이 PC의 Wi-Fi IP를 넣으세요 (run-asterisk.ps1이 해 줍니다)}"
cat > /etc/asterisk/rtp.conf <<CONF
[general]
rtpstart=10000
rtpend=10049
icesupport=yes

[ice_host_candidates]
$(hostname -i | cut -d' ' -f1) => ${LAN_IP}
CONF
exec asterisk -f -vvv
