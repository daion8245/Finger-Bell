"""SQLAlchemy 엔진과 세션. 기본은 SQLite, URL만 바꾸면 PostgreSQL을 씁니다."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import DateTime, create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.types import TypeDecorator


class Base(DeclarativeBase):
    pass


class UTCDateTime(TypeDecorator):
    """항상 UTC aware datetime으로 읽고 쓰는 컬럼 (SQLite는 시간대를 저장하지 않음)."""

    impl = DateTime
    cache_ok = True

    def process_bind_param(self, value: datetime | None, dialect):
        if value is None:
            return None
        if value.tzinfo is None:
            raise ValueError("시간대가 없는 datetime은 저장할 수 없습니다")
        return value.astimezone(timezone.utc).replace(tzinfo=None)

    def process_result_value(self, value: datetime | None, dialect):
        if value is None:
            return None
        return value.replace(tzinfo=timezone.utc)


def make_engine(url: str) -> Engine:
    if url.startswith("sqlite"):
        return create_engine(url, connect_args={"check_same_thread": False})
    return create_engine(url, pool_pre_ping=True)


def make_session_factory(engine: Engine) -> sessionmaker:
    return sessionmaker(bind=engine, expire_on_commit=False)


def begin_read_snapshot(session: Session) -> None:
    dialect = session.get_bind().dialect.name
    if dialect == "sqlite":
        # sqlite3의 기본 모드에서는 첫 SELECT로 읽기 트랜잭션이 시작되지 않습니다.
        connection = session.connection()
        if not connection.connection.driver_connection.in_transaction:
            connection.exec_driver_sql("BEGIN")
    elif dialect == "postgresql":
        session.connection(execution_options={"isolation_level": "REPEATABLE READ"})
