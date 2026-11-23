"""AsteriskSms: ARI로 보호자 내선에 문자를 보내고, Asterisk가 꺼져 있어도 예외 없이 기록만 남깁니다."""

from __future__ import annotations

import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

from app.integrations import AsteriskSms


def test_sends_sip_message_to_guardian_through_ari():
    seen: dict = {}

    class Ari(BaseHTTPRequestHandler):
        def do_PUT(self):
            url = urlparse(self.path)
            seen.update(path=url.path, query=parse_qs(url.query), auth=self.headers["Authorization"])
            self.send_response(202)
            self.end_headers()

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Ari)
    threading.Thread(target=server.handle_request, daemon=True).start()
    try:
        sms = AsteriskSms(f"http://127.0.0.1:{server.server_port}/ari", "fingerbell", "secret")
        record = sms.send("010-1234-5678", "[핑거벨] 긴급 SOS")
    finally:
        server.server_close()

    assert seen["path"] == "/ari/endpoints/PJSIP/guardian/sendMessage"
    assert seen["query"]["body"] == ["[핑거벨] 긴급 SOS"]
    assert seen["query"]["from"] == ["sip:fingerbell@fingerbell"]
    assert seen["auth"] == "Basic ZmluZ2VyYmVsbDpzZWNyZXQ="
    assert (record.channel, record.target, record.payload["result"]) == ("SMS", "010-1234-5678", "HTTP 202")


def test_asterisk_down_is_recorded_not_raised():
    record = AsteriskSms("http://127.0.0.1:9/ari", "u", "p", timeout=0.5).send("010", "hi")
    assert record.payload["result"].startswith("연결 실패")
