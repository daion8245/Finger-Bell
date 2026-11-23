"""외부 연동 어댑터 (금융결제원 오픈뱅킹, FCM 푸시, SMS, ARS 음성 전화).

문자는 FINGERBELL_ASTERISK_ARI를 주면 Asterisk로 보호자 앱에 실제로 보내고(AsteriskSms),
나머지는 모의(Mock) 구현입니다. 실제 API처럼 호출 내용을 만들고 IntegrationRecord로
돌려주면, 서비스가 연동 기록(integration_logs)에 남깁니다. 실제 연동으로 바꿀 때는
같은 메서드를 가진 클래스를 만들어 `Gateways`에 넣으면 됩니다.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass, field
from typing import Any, Protocol
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


@dataclass(frozen=True)
class IntegrationRecord:
    channel: str  # OPEN_BANKING / FCM / SMS / ARS
    action: str
    target: str
    message: str
    payload: dict[str, Any] = field(default_factory=dict)


class OpenBankingGateway(Protocol):
    def stop_withdrawals(self, owner: str, accounts: list[dict[str, Any]], reason: str) -> IntegrationRecord: ...
    def resume_withdrawals(self, owner: str, accounts: list[dict[str, Any]], reason: str) -> IntegrationRecord: ...
    def transfer(self, owner: str, from_account: str, to_bank: str, to_account: str, amount: int) -> IntegrationRecord: ...


class PushGateway(Protocol):
    def send(self, to: str, title: str, body: str, data: dict[str, Any]) -> IntegrationRecord: ...


class SmsGateway(Protocol):
    def send(self, to: str, text: str) -> IntegrationRecord: ...


class ArsGateway(Protocol):
    def call(self, to: str, script: str, request_id: str) -> IntegrationRecord: ...


class MockOpenBanking:
    """금융결제원 오픈뱅킹 테스트베드 형식을 흉내냅니다 (실제 요청은 보내지 않음)."""

    def stop_withdrawals(self, owner, accounts, reason):
        return IntegrationRecord(
            "OPEN_BANKING",
            "POST /v2.0/account/withdraw_stop",
            owner,
            f"연동 계좌 {len(accounts)}개 일괄 지급정지 ({reason})",
            {"accounts": accounts, "reason": reason, "mode": "mock"},
        )

    def resume_withdrawals(self, owner, accounts, reason):
        return IntegrationRecord(
            "OPEN_BANKING",
            "POST /v2.0/account/withdraw_resume",
            owner,
            f"연동 계좌 {len(accounts)}개 지급정지 해제 ({reason})",
            {"accounts": accounts, "reason": reason, "mode": "mock"},
        )

    def transfer(self, owner, from_account, to_bank, to_account, amount):
        return IntegrationRecord(
            "OPEN_BANKING",
            "POST /v2.0/transfer/withdraw/fin_num",
            owner,
            f"{to_bank} {to_account}로 {amount:,}원 출금이체",
            {"from": from_account, "to_bank": to_bank, "to_account": to_account, "amount": amount, "mode": "mock"},
        )


class MockPush:
    def send(self, to, title, body, data):
        return IntegrationRecord("FCM", "POST /v1/projects/fingerbell/messages:send", to, f"{title} · {body}", {"data": data, "mode": "mock"})


class MockSms:
    def send(self, to, text):
        return IntegrationRecord("SMS", "POST /sms/send", to, text, {"mode": "mock"})


class AsteriskSms:
    """Asterisk ARI로 보호자 앱(SIP 내선)에 문자(SIP MESSAGE)를 보냅니다.

    shortcut: 가족이 하나라 문자는 모두 보호자 내선으로 갑니다. 보호자가 여럿이 되면 전화번호→내선 표를 두세요.
    """

    def __init__(self, ari_url: str, user: str, password: str, endpoint: str = "guardian", timeout: float = 2.0):
        self.ari_url = ari_url.rstrip("/")
        self.endpoint = endpoint
        self.timeout = timeout
        self._auth = "Basic " + base64.b64encode(f"{user}:{password}".encode()).decode()

    def send(self, to, text):
        path = f"/endpoints/PJSIP/{self.endpoint}/sendMessage"
        query = urlencode({"from": "sip:fingerbell@fingerbell", "body": text})
        request = Request(f"{self.ari_url}{path}?{query}", method="PUT", headers={"Authorization": self._auth})
        # 문자가 실패해도 SOS 동결은 그대로 진행돼야 하므로, 오류는 기록만 하고 넘깁니다.
        try:
            with urlopen(request, timeout=self.timeout) as response:
                result = f"HTTP {response.status}"
        except HTTPError as exc:
            result = f"HTTP {exc.code}"
        except (URLError, OSError) as exc:
            result = f"연결 실패: {getattr(exc, 'reason', exc)}"
        return IntegrationRecord("SMS", f"PUT /ari{path}", to, text, {"mode": "asterisk", "result": result})


class MockArs:
    def call(self, to, script, request_id):
        return IntegrationRecord(
            "ARS",
            "POST /calls (TwiML Gather 1|2)",
            to,
            script,
            {"request_id": request_id, "digits": {"1": "APPROVE", "2": "REJECT"}, "mode": "mock"},
        )


@dataclass
class Gateways:
    open_banking: OpenBankingGateway = field(default_factory=MockOpenBanking)
    push: PushGateway = field(default_factory=MockPush)
    sms: SmsGateway = field(default_factory=MockSms)
    ars: ArsGateway = field(default_factory=MockArs)
