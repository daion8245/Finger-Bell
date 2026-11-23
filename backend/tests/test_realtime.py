from concurrent.futures import ThreadPoolExecutor
from threading import Event

import pytest

from app import main, seed as seed_data

from .conftest import member, state


def test_state_snapshot_has_demo_family(client):
    snap = state(client)
    assert snap["guardian"]["name"] == "김사랑"
    senior = member(snap, "senior")
    child = member(snap, "child")
    assert senior["balance"] == 2_350_000
    assert senior["spent_today"] == 12_400
    assert child["spent_today"] == 8_500
    assert senior["avg_transfer"] == 100_000
    assert senior["caution_mode"] is False
    assert senior["caution_until"] is None
    assert child["mode"] == "school"
    assert snap["config"]["hold_seconds"] == 1800
    assert snap["config"]["reconfirm_seconds"] == 86400
    assert snap["config"]["approval_timeout_seconds"] == 180
    assert snap["config"]["caution_mode_hours"] == 24


def test_websocket_receives_freeze_event(client):
    with client.websocket_connect("/api/v1/ws") as ws:
        assert ws.receive_json()["type"] == "hello"
        client.post("/api/v1/security/sos-freeze", json={"user_id": "senior", "trigger_type": "LONG_PRESS"})
        event = ws.receive_json()
        assert event["type"] == "freeze"
        assert event["member_id"] == "senior"
        assert "동결" in event["message"]


def test_demo_reset_restores_seed(client):
    client.post("/api/v1/security/sos-freeze", json={"user_id": "senior", "trigger_type": "LONG_PRESS"})
    assert client.post("/api/v1/demo/reset").status_code == 200
    assert member(state(client), "senior")["is_frozen"] is False


def test_state_during_demo_reset_reads_complete_previous_data(client, monkeypatch):
    client.post("/api/v1/security/sos-freeze", json={"user_id": "senior", "trigger_type": "LONG_PRESS"})
    resetting = Event()
    finish_reset = Event()
    seed = seed_data.seed

    def pause_before_seed(session):
        resetting.set()
        assert finish_reset.wait(timeout=10)
        seed(session)

    monkeypatch.setattr(seed_data, "seed", pause_before_seed)
    monkeypatch.setattr(main, "seed", pause_before_seed)
    with ThreadPoolExecutor(max_workers=1) as executor:
        reset = executor.submit(client.post, "/api/v1/demo/reset")
        try:
            assert resetting.wait(timeout=5)
            snapshot = state(client)
            assert {m["id"] for m in snapshot["members"]} == {"senior", "child"}
            assert member(snapshot, "senior")["is_frozen"] is True
        finally:
            finish_reset.set()
        assert reset.result(timeout=5).status_code == 200
    assert member(state(client), "senior")["is_frozen"] is False


def test_failed_demo_reset_keeps_previous_data(client, monkeypatch):
    client.post("/api/v1/security/sos-freeze", json={"user_id": "senior", "trigger_type": "LONG_PRESS"})
    seed = seed_data.seed

    def fail_after_seed(session):
        seed(session)
        session.flush()
        raise RuntimeError("seed failed")

    monkeypatch.setattr(seed_data, "seed", fail_after_seed)
    with pytest.raises(RuntimeError, match="seed failed"):
        client.post("/api/v1/demo/reset")
    assert member(state(client), "senior")["is_frozen"] is True


def test_unknown_member_is_404(client):
    r = client.post("/api/v1/security/sos-freeze", json={"user_id": "nobody", "trigger_type": "LONG_PRESS"})
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "member"


def test_invalid_body_uses_error_envelope(client):
    r = client.post("/api/v1/security/sos-freeze", json={"user_id": "senior", "trigger_type": "DANCE"})
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "invalid"
