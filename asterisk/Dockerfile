# 핑거벨 인터넷 전화·문자 서버. Alpine 패키지 Asterisk 20 + WebRTC 암호화(srtp)·Opus 코덱.
FROM alpine:3.23
RUN apk add --no-cache asterisk asterisk-srtp asterisk-opus
COPY conf/ /etc/asterisk/
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
