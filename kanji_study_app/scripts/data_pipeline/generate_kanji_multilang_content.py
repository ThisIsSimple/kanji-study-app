#!/usr/bin/env python3
"""Generate multilingual kanji meanings and commentary with checkpoint reuse."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, dedupe, read_json, write_json


JAPANESE_RE = re.compile(r"[ぁ-んァ-ン一-龯]")
ENGLISH_RE = re.compile(r"[A-Za-z]")
DEFAULT_BATCH_SIZE = 25

KANJI_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["items"],
    "properties": {
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["key", "jp_meanings", "jp_commentary", "en_commentary"],
                "properties": {
                    "key": {"type": "string"},
                    "jp_meanings": {"type": "array", "minItems": 1, "maxItems": 6, "items": {"type": "string"}},
                    "jp_commentary": {"type": "string"},
                    "en_commentary": {"type": "string"},
                },
            },
        },
    },
}


def rows_from_json(path: Path) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("kanji"), list):
        return data["kanji"]
    raise ValueError("input JSON must be a list or contain a 'kanji' list")


def has_japanese(value: Any) -> bool:
    return bool(JAPANESE_RE.search(str(value or "")))


def has_english(value: Any) -> bool:
    return bool(ENGLISH_RE.search(str(value or "")))


def kanji_key(row: dict[str, Any]) -> str:
    return str(row.get("external_id") or row.get("character") or row.get("id")).strip()


def readings(row: dict[str, Any], source: str) -> list[str]:
    if source in row and isinstance(row[source], list):
        return [str(item) for item in row[source] if str(item).strip()]
    reading_obj = row.get("readings") or {}
    if source == "on_readings":
        return [str(item) for item in reading_obj.get("on") or []]
    if source == "kun_readings":
        return [str(item) for item in reading_obj.get("kun") or []]
    return []


def backfill_row(row: dict[str, Any]) -> dict[str, Any]:
    on = readings(row, "on_readings")
    kun = readings(row, "kun_readings")
    meanings_ko = row.get("meanings_ko") or row.get("meanings") or []
    meanings_en = row.get("meanings_en") or []
    return {
        **row,
        "jp_on_readings": row.get("jp_on_readings") or on,
        "jp_kun_readings": row.get("jp_kun_readings") or kun,
        "kr_on_readings": row.get("kr_on_readings") or row.get("korean_on_readings") or [],
        "kr_kun_readings": row.get("kr_kun_readings") or row.get("korean_kun_readings") or [],
        "kr_meanings": row.get("kr_meanings") or meanings_ko,
        "en_meanings": row.get("en_meanings") or meanings_en,
        "kr_commentary": row.get("kr_commentary") or row.get("commentary"),
    }


def has_missing_multilang_target(row: dict[str, Any]) -> bool:
    return not row.get("jp_meanings") or not has_japanese(row.get("jp_commentary")) or not has_english(row.get("en_commentary"))


def missing_fields(row: dict[str, Any]) -> list[str]:
    fields: list[str] = []
    if not row.get("jp_meanings"):
        fields.append("jp_meanings")
    if not has_japanese(row.get("jp_commentary")):
        fields.append("jp_commentary")
    if not has_english(row.get("en_commentary")):
        fields.append("en_commentary")
    return fields


def candidate_rows(rows: list[dict[str, Any]], sample_size: int | None = None) -> list[dict[str, Any]]:
    candidates = [
        backfill_row(row)
        for row in rows
        if row.get("id") is not None and row.get("character") and has_missing_multilang_target(row)
    ]
    candidates.sort(
        key=lambda row: (
            not bool(row.get("is_common")),
            row.get("priority_rank") if row.get("priority_rank") is not None else 10**9,
            row.get("id") or 0,
        )
    )
    if sample_size and sample_size > 0:
        return candidates[:sample_size]
    return candidates


def build_prompt(rows: list[dict[str, Any]]) -> str:
    entries = [
        {
            "key": kanji_key(row),
            "character": row.get("character"),
            "jp_on_readings": row.get("jp_on_readings") or [],
            "jp_kun_readings": row.get("jp_kun_readings") or [],
            "kr_meanings": row.get("kr_meanings") or [],
            "en_meanings": row.get("en_meanings") or [],
            "kr_commentary": row.get("kr_commentary"),
            "existing_jp_meanings": row.get("jp_meanings") or [],
            "existing_jp_commentary": row.get("jp_commentary"),
            "existing_en_commentary": row.get("en_commentary"),
            "missing_fields": missing_fields(row),
        }
        for row in rows
    ]
    return (
        "일본어 한자 학습 앱에 넣을 한자 다국어 콘텐츠 초안을 생성하세요.\n"
        "규칙:\n"
        "- 출력은 JSON 객체 하나만 반환하세요. 마크다운, 설명, 주석을 쓰지 마세요.\n"
        "- 스키마는 {\"items\":[{\"key\":\"...\",\"jp_meanings\":[\"...\"],\"jp_commentary\":\"...\",\"en_commentary\":\"...\"}]} 입니다.\n"
        "- 입력의 key를 그대로 보존하세요.\n"
        "- jp_meanings는 일본어 한자 사전식 뜻 1~6개입니다.\n"
        "- jp_commentary는 일본어로 한자의 기원/의미를 1~2문장으로 설명합니다.\n"
        "- en_commentary는 영어로 한자의 origin/meaning를 1~2문장으로 설명합니다.\n"
        "- existing_* 값이 있으면 의미를 바꾸지 말고 같은 값을 반환하세요.\n"
        "- missing_fields에 있는 값은 반드시 새로 채우세요.\n"
        "- 모르는 기원은 단정하지 말고 일반적인 의미/구성 중심으로 설명하세요.\n\n"
        f"- 입력 entries {len(entries)}개 각각에 대해 items 항목을 정확히 1개씩 반환하세요.\n\n"
        f"입력 JSON:\n{json.dumps({'entries': entries}, ensure_ascii=False, indent=2)}"
    )


def parse_payload(text: str) -> dict[str, dict[str, Any]]:
    raw = text.strip()
    if not raw:
        return {}
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        parsed = json.loads(re.sub(r"^```(?:json)?\s*|\s*```$", "", raw, flags=re.S).strip())
    if isinstance(parsed, dict):
        for wrapper in ("structured_output", "result", "content", "last_message"):
            nested = parsed.get(wrapper)
            if isinstance(nested, dict):
                parsed = nested
            elif isinstance(nested, str):
                return parse_payload(nested)
        items = parsed.get("items")
    else:
        items = parsed
    if not isinstance(items, list):
        return {}
    result: dict[str, dict[str, Any]] = {}
    for item in items:
        if not isinstance(item, dict):
            continue
        key = str(item.get("key") or "").strip()
        jp_meanings = item.get("jp_meanings")
        jp_commentary = str(item.get("jp_commentary") or "").strip()
        en_commentary = str(item.get("en_commentary") or "").strip()
        if key and isinstance(jp_meanings, list):
            result[key] = {
                "jp_meanings": dedupe(jp_meanings),
                "jp_commentary": jp_commentary,
                "en_commentary": en_commentary,
            }
    return result


def batched(rows: list[dict[str, Any]], size: int) -> list[list[dict[str, Any]]]:
    return [rows[index : index + size] for index in range(0, len(rows), size)]


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


def generate_mapping(
    rows: list[dict[str, Any]],
    output_dir: Path,
    provider: str,
    model: str,
    batch_size: int,
    timeout: int,
    prompts_only: bool,
    max_batches: int | None = None,
) -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model or "default")
    checkpoint_dir = output_dir / "kanji-multilang-cli" / provider / safe_model
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    schema_path = checkpoint_dir / "kanji_multilang_schema.json"
    write_json(schema_path, KANJI_SCHEMA)

    mapping: dict[str, dict[str, Any]] = {}
    failed_batches: list[dict[str, Any]] = []
    prompt_files: list[str] = []
    batches = batched(rows, batch_size)
    if max_batches and max_batches > 0:
        batches = batches[:max_batches]
    completed_batches = 0
    for batch_index, batch_rows in enumerate(batches, start=1):
        prompt = build_prompt(batch_rows)
        prompt_hash = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:12]
        base_name = f"batch_{batch_index:06d}_{prompt_hash}"
        prompt_path = checkpoint_dir / f"{base_name}_prompt.txt"
        raw_output_path = checkpoint_dir / f"{base_name}_raw.txt"
        parsed_output_path = checkpoint_dir / f"{base_name}_items.json"
        codex_last_message_path = checkpoint_dir / f"{base_name}_codex_last_message.json"
        prompt_path.write_text(prompt, encoding="utf-8")
        prompt_files.append(str(prompt_path))
        if prompts_only:
            continue
        expected_keys = {kanji_key(row) for row in batch_rows}
        try:
            if parsed_output_path.exists():
                batch_mapping = parse_payload(parsed_output_path.read_text(encoding="utf-8"))
            else:
                if provider != "codex-cli":
                    raise ValueError(f"unsupported provider for KANJI-11 sample: {provider}")
                raw_output = run_codex_cli(prompt, model, timeout, schema_path, codex_last_message_path)
                raw_output_path.write_text(raw_output, encoding="utf-8")
                batch_mapping = parse_payload(raw_output)
                write_json(parsed_output_path, {"items": [{"key": key, **value} for key, value in sorted(batch_mapping.items())]})
            missing_keys = sorted(expected_keys.difference(batch_mapping.keys()))
            if missing_keys:
                failed_batches.append({"batch": batch_index, "missing_keys": missing_keys[:20]})
            mapping.update(batch_mapping)
            completed_batches += 1
            print(f"kanji multilang batch {batch_index}/{len(batches)} items={len(batch_mapping)}", flush=True)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError, ValueError) as error:
            failed_batches.append({"batch": batch_index, "error": str(error)})
    return mapping, {
        "provider": provider,
        "model": model,
        "batch_size": batch_size,
        "planned_batches": len(batches),
        "completed_batches": completed_batches,
        "failed_batches": failed_batches,
        "prompts_only": prompts_only,
        "max_batches": max_batches,
        "prompt_files": prompt_files[:20],
        "checkpoint_dir": str(checkpoint_dir),
        "items": len(mapping),
    }


def apply_mapping(rows: list[dict[str, Any]], mapping: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    result = []
    for row in rows:
        item = mapping.get(kanji_key(row), {})
        generated_jp_meanings = [value for value in item.get("jp_meanings", []) if has_japanese(value)]
        current_jp_meanings = row.get("jp_meanings") or []
        current_jp_commentary = row.get("jp_commentary")
        current_en_commentary = row.get("en_commentary")
        result.append(
            {
                **row,
                "jp_meanings": current_jp_meanings or generated_jp_meanings,
                "jp_commentary": current_jp_commentary
                if has_japanese(current_jp_commentary)
                else item.get("jp_commentary") or current_jp_commentary,
                "en_commentary": current_en_commentary
                if has_english(current_en_commentary)
                else item.get("en_commentary") or current_en_commentary,
            }
        )
    return result


def preflight(rows: list[dict[str, Any]], expected_count: int | None = None) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    if expected_count is not None and len(rows) != expected_count:
        errors.append({"type": "unexpected_kanji_sample_count", "expected": expected_count, "actual": len(rows)})
    missing_jp_meanings = [row.get("id") for row in rows if not row.get("jp_meanings")]
    missing_jp_commentary = [row.get("id") for row in rows if not has_japanese(row.get("jp_commentary"))]
    missing_en_commentary = [row.get("id") for row in rows if not has_english(row.get("en_commentary"))]
    overwritten_kr = [
        row.get("id")
        for row in rows
        if (row.get("commentary") or None) is not None and row.get("kr_commentary") != row.get("commentary")
    ]
    if missing_jp_meanings:
        errors.append({"type": "missing_jp_meanings", "ids": missing_jp_meanings[:50]})
    if missing_jp_commentary:
        errors.append({"type": "missing_or_non_japanese_jp_commentary", "ids": missing_jp_commentary[:50]})
    if missing_en_commentary:
        errors.append({"type": "missing_or_non_english_en_commentary", "ids": missing_en_commentary[:50]})
    if overwritten_kr:
        errors.append({"type": "kr_commentary_does_not_match_legacy_commentary", "ids": overwritten_kr[:50]})
    return {"failed": bool(errors), "errors": errors, "totals": {"words": 0, "kanji": len(rows)}}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11")
    parser.add_argument("--output-prefix", default="kanji_multilang_sample")
    parser.add_argument("--provider", choices=["codex-cli"], default="codex-cli")
    parser.add_argument("--model", default="")
    parser.add_argument("--sample-size", type=int, default=None, help="생략하거나 0이면 전체 후보를 처리합니다.")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--max-batches", type=int, default=None)
    parser.add_argument("--prompts-only", action="store_true")
    args = parser.parse_args()

    all_rows = rows_from_json(args.input)
    sample_rows = candidate_rows(all_rows, args.sample_size)
    generation_rows = sample_rows
    if args.max_batches and args.max_batches > 0:
        generation_rows = sample_rows[: args.max_batches * args.batch_size]
    mapping, cli_report = generate_mapping(
        generation_rows,
        args.output_dir,
        args.provider,
        args.model,
        args.batch_size,
        args.timeout,
        args.prompts_only,
        args.max_batches,
    )
    output_rows = generation_rows if args.prompts_only else apply_mapping(generation_rows, mapping)
    report = {
        "input_count": len(all_rows),
        "candidate_count": len(sample_rows),
        "processed_count": len(generation_rows),
        "sample_count": len(generation_rows),
        "cli": cli_report,
        "preflight": preflight(output_rows, len(generation_rows)) if not args.prompts_only else None,
    }
    report_name = "kanji_multilang_report" if args.output_prefix == "kanji_multilang_sample" else f"{args.output_prefix}_report"
    write_json(args.output_dir / f"{args.output_prefix}.json", {"kanji": output_rows})
    write_json(args.output_dir / f"{report_name}.json", report)
    print(f"kanji multilang kanji={len(output_rows)} failed={report['preflight']['failed'] if report['preflight'] else None}")
    if report["preflight"] and report["preflight"]["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
