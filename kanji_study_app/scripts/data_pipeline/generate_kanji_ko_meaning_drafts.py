#!/usr/bin/env python3
"""Generate Korean meaning drafts and split meanings for new KANJIDIC2 kanji."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any

from common import (
    DEFAULT_OUTPUT_DIR,
    QUALITY_AI_DRAFT,
    SOURCE_KANJIDIC2,
    add_common_output_args,
    dedupe,
    read_json,
    write_json,
)
from generate_ko_meaning_drafts import TRANSLATION_SCHEMA, parse_translation_payload


HANGUL_RE = re.compile(r"[가-힣]")
DEFAULT_BATCH_SIZE = 50
DEFAULT_REQUIRED_COUNT = 966


def has_korean(value: str) -> bool:
    return bool(HANGUL_RE.search(value or ""))


def kanji_key(row: dict[str, Any]) -> str:
    return str(row.get("external_id") or row.get("character") or "").strip()


def candidate_rows(rows: list[dict[str, Any]], required_count: int | None = DEFAULT_REQUIRED_COUNT) -> list[dict[str, Any]]:
    candidates = [
        row
        for row in rows
        if row.get("source") == SOURCE_KANJIDIC2 and row.get("quality_status") == QUALITY_AI_DRAFT
    ]
    if required_count is not None and len(candidates) != required_count:
        raise ValueError(f"expected {required_count} new kanji candidates, got {len(candidates)}")
    return candidates


def build_kanji_prompt(rows: list[dict[str, Any]]) -> str:
    entries: list[dict[str, Any]] = []
    for row in rows:
        readings = row.get("readings") or {}
        entries.append(
            {
                "key": kanji_key(row),
                "character": row.get("character"),
                "on_readings": readings.get("on") or [],
                "kun_readings": readings.get("kun") or [],
                "korean_on_readings": row.get("korean_on_readings") or [],
                "english_meanings": row.get("meanings") or [],
            }
        )
    return (
        "일본어 한자 학습 앱에 넣을 한국어 한자 뜻 초안을 생성하세요.\n"
        "규칙:\n"
        "- 출력은 JSON 객체 하나만 반환하세요. 마크다운, 설명, 주석을 쓰지 마세요.\n"
        "- 스키마는 {\"translations\":[{\"key\":\"...\",\"meanings\":[\"...\"]}]} 입니다.\n"
        "- 입력의 key를 그대로 보존하세요.\n"
        "- meanings는 한국어 한자 뜻 1~6개만 넣으세요.\n"
        "- 영어 gloss를 직역하지 말고 한국어 한자 사전에서 쓰는 짧은 뜻으로 정리하세요.\n"
        "- 뜻마다 12자 이내를 권장하고, 조사/문장/예문/설명 문장은 쓰지 마세요.\n"
        "- 인명/지명에 주로 쓰이는 한자는 가장 일반적인 뜻을 우선하세요.\n"
        "- 확실하지 않으면 가장 넓게 통용되는 뜻 1~2개만 반환하세요.\n\n"
        f"- 입력 entries {len(entries)}개 각각에 대해 translations 항목을 정확히 1개씩 반환하세요.\n\n"
        f"입력 JSON:\n{json.dumps({'entries': entries}, ensure_ascii=False, indent=2)}"
    )


def run_codex_cli(prompt: str, model: str, timeout: int, schema_path: Path, output_path: Path) -> str:
    command = [
        "codex",
        "exec",
        "--cd",
        str(Path.cwd()),
        "--sandbox",
        "read-only",
        "--output-schema",
        str(schema_path.resolve()),
        "--output-last-message",
        str(output_path.resolve()),
        "--ephemeral",
    ]
    if model:
        command.extend(["--model", model])
    command.append(prompt)
    completed = subprocess.run(command, text=True, capture_output=True, check=True, timeout=timeout)
    if output_path.exists():
        return output_path.read_text(encoding="utf-8")
    return completed.stdout


def run_claude_cli(prompt: str, model: str, timeout: int, schema_path: Path) -> str:
    command = [
        "claude",
        "-p",
        "--output-format",
        "json",
        "--json-schema",
        schema_path.read_text(encoding="utf-8"),
        "--permission-mode",
        "dontAsk",
    ]
    if model:
        command.extend(["--model", model])
    command.append(prompt)
    completed = subprocess.run(command, text=True, capture_output=True, check=True, timeout=timeout)
    return completed.stdout


def load_checkpoint_mapping(output_dir: Path, provider: str, model: str) -> dict[str, list[str]]:
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model or "default")
    checkpoint_dir = output_dir / "ko-draft-cli-kanji" / provider / safe_model
    if not checkpoint_dir.exists():
        return {}

    mapping: dict[str, list[str]] = {}
    for path in sorted(checkpoint_dir.glob("*_translations.json")):
        batch_mapping = parse_translation_payload(path.read_text(encoding="utf-8"))
        if not batch_mapping:
            raw_path = path.with_name(path.name.replace("_translations.json", "_raw.txt"))
            if raw_path.exists():
                batch_mapping = parse_translation_payload(raw_path.read_text(encoding="utf-8"))
        mapping.update(batch_mapping)
    return mapping


def cli_error_report(error: Exception) -> dict[str, str]:
    report = {"error": str(error)}
    if isinstance(error, subprocess.CalledProcessError):
        if error.stdout:
            report["stdout"] = str(error.stdout)[-4000:]
        if error.stderr:
            report["stderr"] = str(error.stderr)[-4000:]
    return report


def generate_cli_mapping(
    rows: list[dict[str, Any]],
    provider: str,
    model: str,
    output_dir: Path,
    batch_size: int,
    max_batches: int | None,
    timeout: int,
    prompts_only: bool,
) -> tuple[dict[str, list[str]], dict[str, Any]]:
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model or "default")
    checkpoint_dir = output_dir / "ko-draft-cli-kanji" / provider / safe_model
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    schema_path = checkpoint_dir / "translation_schema.json"
    write_json(schema_path, TRANSLATION_SCHEMA)

    batches = [rows[index : index + batch_size] for index in range(0, len(rows), batch_size)]
    if max_batches is not None:
        batches = batches[:max_batches]

    mapping: dict[str, list[str]] = {}
    failed_batches: list[dict[str, Any]] = []
    prompt_files: list[str] = []
    completed_batches = 0
    for batch_index, batch_rows in enumerate(batches, start=1):
        prompt = build_kanji_prompt(batch_rows)
        prompt_hash = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:12]
        base_name = f"batch_{batch_index:06d}_{prompt_hash}"
        prompt_path = checkpoint_dir / f"{base_name}_prompt.txt"
        raw_output_path = checkpoint_dir / f"{base_name}_raw.txt"
        parsed_output_path = checkpoint_dir / f"{base_name}_translations.json"
        codex_last_message_path = checkpoint_dir / f"{base_name}_codex_last_message.json"

        expected_keys = {kanji_key(row) for row in batch_rows}
        prompt_path.write_text(prompt, encoding="utf-8")
        prompt_files.append(str(prompt_path))
        if prompts_only:
            continue

        try:
            if parsed_output_path.exists():
                batch_mapping = parse_translation_payload(parsed_output_path.read_text(encoding="utf-8"))
                if not batch_mapping and raw_output_path.exists():
                    batch_mapping = parse_translation_payload(raw_output_path.read_text(encoding="utf-8"))
            else:
                if provider == "codex-cli":
                    raw_output = run_codex_cli(prompt, model, timeout, schema_path, codex_last_message_path)
                elif provider == "claude-cli":
                    raw_output = run_claude_cli(prompt, model, timeout, schema_path)
                else:
                    raise ValueError(f"unsupported CLI provider: {provider}")
                raw_output_path.write_text(raw_output, encoding="utf-8")
                batch_mapping = parse_translation_payload(raw_output)
                write_json(
                    parsed_output_path,
                    {"translations": [{"key": key, "meanings": meanings} for key, meanings in sorted(batch_mapping.items())]},
                )

            mapping.update(batch_mapping)
            missing_keys = sorted(expected_keys.difference(batch_mapping.keys()))
            if missing_keys:
                failed_batches.append(
                    {
                        "batch": batch_index,
                        "prompt": str(prompt_path),
                        "error": f"missing {len(missing_keys)} translations from CLI output",
                        "missing_keys": missing_keys[:20],
                    }
                )
            completed_batches += 1
            print(f"kanji ko draft batch {batch_index}/{len(batches)} translations={len(batch_mapping)}", flush=True)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError, ValueError) as error:
            failed_batches.append({"batch": batch_index, "prompt": str(prompt_path), **cli_error_report(error)})

    return mapping, {
        "provider": provider,
        "model": model,
        "batch_size": batch_size,
        "planned_batches": len(batches),
        "completed_batches": completed_batches,
        "failed_batches": failed_batches,
        "prompts_only": prompts_only,
        "prompt_files": prompt_files[:20],
        "checkpoint_dir": str(checkpoint_dir),
        "translations": len(mapping),
    }


def split_new_kanji(
    rows: list[dict[str, Any]],
    mapping: dict[str, list[str]],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    result: list[dict[str, Any]] = []
    excluded: list[dict[str, Any]] = []
    for row in rows:
        key = kanji_key(row)
        english_meanings = dedupe(meaning for meaning in row.get("meanings") or [] if not has_korean(str(meaning)))
        korean_meanings = dedupe(meaning for meaning in mapping.get(key, []) if has_korean(str(meaning)))
        if not korean_meanings:
            excluded.append({"id": row.get("id"), "character": row.get("character"), "external_id": key, "meanings_en": english_meanings})
            continue
        result.append(
            {
                **row,
                "meanings": korean_meanings,
                "meanings_ko": korean_meanings,
                "meanings_en": english_meanings,
                "quality_status": QUALITY_AI_DRAFT,
                "meaning_source": "ai_translation",
            }
        )
    return result, {"excluded_no_korean": excluded}


def duplicate_values(rows: list[dict[str, Any]], key: str) -> list[Any]:
    counts = Counter(row.get(key) for row in rows)
    return [value for value, count in counts.items() if value and count > 1]


def english_only_values(rows: list[dict[str, Any]], key: str) -> list[dict[str, Any]]:
    bad: list[dict[str, Any]] = []
    for row in rows:
        values = row.get(key) or []
        if values and not any(has_korean(str(value)) for value in values):
            bad.append({"id": row.get("id"), "character": row.get("character"), key: values[:5]})
    return bad


def invalid_readings(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    bad: list[dict[str, Any]] = []
    for row in rows:
        readings = row.get("readings")
        if not isinstance(readings, dict):
            bad.append({"id": row.get("id"), "character": row.get("character"), "error": "readings_not_object"})
            continue
        if not isinstance(readings.get("on") or [], list) or not isinstance(readings.get("kun") or [], list):
            bad.append({"id": row.get("id"), "character": row.get("character"), "error": "readings_on_kun_not_list"})
    return bad


def preflight_report(
    rows: list[dict[str, Any]],
    existing_rows: list[dict[str, Any]],
    required_count: int = DEFAULT_REQUIRED_COUNT,
) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    if len(rows) != required_count:
        errors.append({"type": "unexpected_kanji_count", "expected": required_count, "actual": len(rows)})

    duplicate_ids = duplicate_values(rows, "id")
    duplicate_characters = duplicate_values(rows, "character")
    duplicate_external_ids = duplicate_values(rows, "external_id")
    if duplicate_ids:
        errors.append({"type": "duplicate_kanji_ids", "ids": duplicate_ids[:50]})
    if duplicate_characters:
        errors.append({"type": "duplicate_kanji_characters", "characters": duplicate_characters[:50]})
    if duplicate_external_ids:
        errors.append({"type": "duplicate_kanji_external_ids", "external_ids": duplicate_external_ids[:50]})

    existing_characters = {row.get("character") for row in existing_rows if row.get("character")}
    character_conflicts = [row for row in rows if row.get("character") in existing_characters]
    if character_conflicts:
        errors.append(
            {
                "type": "existing_kanji_character_conflict",
                "items": [
                    {"id": row.get("id"), "character": row.get("character"), "external_id": row.get("external_id")}
                    for row in character_conflicts[:50]
                ],
            }
        )

    empty_characters = [row.get("id") for row in rows if not row.get("character")]
    empty_meanings = [row.get("id") for row in rows if not row.get("meanings_ko")]
    missing_english = [row.get("id") for row in rows if not row.get("meanings_en")]
    bad_meanings = english_only_values(rows, "meanings") + english_only_values(rows, "meanings_ko")
    bad_readings = invalid_readings(rows)
    if empty_characters:
        errors.append({"type": "empty_kanji_character", "ids": empty_characters[:50]})
    if empty_meanings:
        errors.append({"type": "empty_kanji_meanings_ko", "ids": empty_meanings[:50]})
    if missing_english:
        errors.append({"type": "kanjidic_rows_missing_english_gloss", "ids": missing_english[:50]})
    if bad_meanings:
        errors.append({"type": "kanji_korean_meanings_contain_english_only", "items": bad_meanings[:50]})
    if bad_readings:
        errors.append({"type": "invalid_kanji_readings", "items": bad_readings[:50]})

    existing_duplicate_characters = {
        character: [row.get("id") for row in existing_rows if row.get("character") == character]
        for character, count in Counter(row.get("character") for row in existing_rows).items()
        if character and count > 1
    }
    for character, ids in sorted(existing_duplicate_characters.items()):
        warnings.append({"type": "existing_kanji_character_duplicate", "character": character, "ids": ids})

    return {
        "failed": bool(errors),
        "errors": errors,
        "warnings": warnings,
        "totals": {"kanji": len(rows), "words": 0},
    }


def dry_run_report(rows: list[dict[str, Any]], preflight: dict[str, Any]) -> dict[str, Any]:
    return {
        "dry_run": True,
        "words": {"count": 0, "first_ids": []},
        "kanji": {"count": len(rows), "first_ids": [row["id"] for row in rows[:5]]},
        "preflight": preflight,
    }


def load_rows(path: Path, key: str) -> list[dict[str, Any]]:
    data = read_json(path)
    return data[key] if isinstance(data, dict) else data


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_OUTPUT_DIR / "recommended_v1_kanji.json")
    parser.add_argument("--existing-kanji", type=Path, help="기존 운영 한자 export. 없으면 input의 reviewed 한자를 사용합니다.")
    parser.add_argument("--provider", choices=["none", "codex-cli", "claude-cli"], default="codex-cli")
    parser.add_argument("--model", default="")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--max-batches", type=int)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--prompts-only", action="store_true")
    parser.add_argument("--required-count", type=int, default=DEFAULT_REQUIRED_COUNT)
    add_common_output_args(parser)
    args = parser.parse_args()

    all_kanji = load_rows(args.input, "kanji")
    candidates = candidate_rows(all_kanji, args.required_count)
    existing_kanji = load_rows(args.existing_kanji, "kanji") if args.existing_kanji else [
        row for row in all_kanji if row.get("source") != SOURCE_KANJIDIC2 or row.get("quality_status") != QUALITY_AI_DRAFT
    ]

    checkpoint_mapping = load_checkpoint_mapping(args.output_dir, args.provider, args.model) if args.provider != "none" else {}
    target_rows = [row for row in candidates if kanji_key(row) not in checkpoint_mapping]
    if args.max_batches is not None:
        target_rows = target_rows[: args.batch_size * args.max_batches]

    cli_mapping: dict[str, list[str]] = {}
    cli_report: dict[str, Any] | None = None
    if args.provider != "none":
        cli_mapping, cli_report = generate_cli_mapping(
            target_rows,
            args.provider,
            args.model,
            args.output_dir,
            args.batch_size,
            args.max_batches,
            args.timeout,
            args.prompts_only,
        )

    mapping = {**checkpoint_mapping, **cli_mapping}
    if args.prompts_only:
        report = {
            "candidate_count": len(candidates),
            "needs_translation": len(target_rows),
            "cli": cli_report,
        }
        write_json(args.output_dir / "new_kanji_split_meanings_report.json", report)
        print(f"kanji prompts candidate={len(candidates)} needs_translation={len(target_rows)}")
        return

    split_rows, split_report = split_new_kanji(candidates, mapping)
    preflight = preflight_report(split_rows, existing_kanji, args.required_count)
    report = {
        "candidate_count": len(candidates),
        "output_count": len(split_rows),
        "checkpoint_translations": len(checkpoint_mapping),
        "generated_translations": len(cli_mapping),
        "kanji": split_report,
        "cli": cli_report,
        "preflight": preflight,
    }
    write_json(args.output_dir / "recommended_v1_new_kanji_split_meanings.json", {"kanji": split_rows})
    write_json(args.output_dir / "new_kanji_split_meanings_report.json", report)
    write_json(args.output_dir / "recommended_v1_new_kanji_import_dry_run.json", dry_run_report(split_rows, preflight))
    print(
        f"new kanji split meanings kanji={len(split_rows)} excluded={len(split_report['excluded_no_korean'])} "
        f"preflight_failed={preflight['failed']}"
    )
    if preflight["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
