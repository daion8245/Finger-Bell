from __future__ import annotations

import os

from app import config
from app.config import DEFAULT_STT_MODEL, Settings


def test_env_file_supplies_key_but_real_env_wins(tmp_path, monkeypatch):
    env_file = tmp_path / ".env"
    env_file.write_text(
        '# 비밀값\nOPENROUTER_API_KEY="sk-or-from-file"\nFINGERBELL_LLM_MODEL=file/model\n\n', encoding="utf-8"
    )
    monkeypatch.setattr(config, "ENV_FILE", env_file)
    monkeypatch.setattr(os, "environ", {"FINGERBELL_LLM_MODEL": "env/model"})

    s = Settings.from_env()

    assert s.openrouter_api_key == "sk-or-from-file"
    assert s.llm_model == "env/model"
    assert s.stt_model == DEFAULT_STT_MODEL


def test_missing_env_file_keeps_mock_mode(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "ENV_FILE", tmp_path / "없음.env")
    monkeypatch.setattr(os, "environ", {})

    assert Settings.from_env().openrouter_api_key == ""
