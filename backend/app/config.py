"""환경변수 기반 설정. 값은 모두 FINGERBELL_ 접두어를 씁니다."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

# flutter build web 결과물. 있으면 FINGERBELL_WEB_DIR 없이도 같은 서버에서 웹 앱을 제공합니다.
DEFAULT_WEB_BUILD = Path(__file__).resolve().parents[2] / "packages" / "app" / "build" / "web"
# 기본 DB는 실행 위치와 상관없이 backend/fingerbell.db
DEFAULT_DATABASE_URL = f"sqlite:///{(Path(__file__).resolve().parents[1] / 'fingerbell.db').as_posix()}"


def _int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or raw.strip() == "":
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ValueError(f"{name} 값은 정수여야 합니다: {raw!r}") from exc


@dataclass(frozen=True)
class Settings:
    database_url: str = DEFAULT_DATABASE_URL
    # 보호자 콜백 승인 대기 시간 (기획서 3.2: 3분)
    approval_timeout_seconds: int = 180
    # 푸시를 확인하지 않으면 ARS 전화를 거는 시점
    ars_after_seconds: int = 20
    # SOS 동결 유지 시간 (기획서 3.1: 24시간)
    freeze_hours: int = 24
    # 백그라운드 점검(타이머 만료, ARS 발신) 주기
    tick_seconds: float = 1.0
    # Flutter 웹 빌드 폴더. 지정하면 같은 서버에서 웹 앱도 제공합니다.
    web_dir: str | None = None
    cors_origins: list[str] = field(default_factory=lambda: ["*"])
    # Asterisk ARI 주소 (예: http://127.0.0.1:8088/ari). 주면 SOS 문자를 보호자 앱으로 보내고, 없으면 모의 문자.
    asterisk_ari_url: str | None = None
    # asterisk/conf/ari.conf의 시연용 계정과 같아야 합니다.
    asterisk_ari_user: str = "fingerbell"
    asterisk_ari_password: str = "fingerbell-demo"

    @classmethod
    def from_env(cls) -> "Settings":
        origins = os.getenv("FINGERBELL_CORS_ORIGINS", "*")
        return cls(
            database_url=os.getenv("FINGERBELL_DATABASE_URL", cls.database_url),
            approval_timeout_seconds=_int("FINGERBELL_APPROVAL_TIMEOUT", cls.approval_timeout_seconds),
            ars_after_seconds=_int("FINGERBELL_ARS_AFTER", cls.ars_after_seconds),
            freeze_hours=_int("FINGERBELL_FREEZE_HOURS", cls.freeze_hours),
            web_dir=os.getenv("FINGERBELL_WEB_DIR") or _default_web_dir(),
            cors_origins=[o.strip() for o in origins.split(",") if o.strip()],
            asterisk_ari_url=os.getenv("FINGERBELL_ASTERISK_ARI") or None,
            asterisk_ari_user=os.getenv("FINGERBELL_ASTERISK_ARI_USER", cls.asterisk_ari_user),
            asterisk_ari_password=os.getenv("FINGERBELL_ASTERISK_ARI_PASSWORD", cls.asterisk_ari_password),
        )


def _default_web_dir() -> str | None:
    if os.getenv("FINGERBELL_NO_WEB"):
        return None
    return str(DEFAULT_WEB_BUILD) if (DEFAULT_WEB_BUILD / "index.html").is_file() else None
