#!/usr/bin/env python3
"""Generate Japanese dictionary-style word meanings with checkpoint reuse."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, dedupe_meanings, read_json, write_json
from generate_ko_meaning_drafts import TRANSLATION_SCHEMA, draft_key, parse_translation_payload


JAPANESE_RE = re.compile(r"[ぁ-んァ-ン一-龯]")
DEFAULT_BATCH_SIZE = 100


def rows_from_json(path: Path) -> list[dict[str, Any]]:
    data = read_json(path)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("words"), list):
        return data["words"]
    raise ValueError("input JSON must be a list or contain a 'words' list")


def has_japanese(value: Any) -> bool:
    return bool(JAPANESE_RE.search(str(value or "")))


def meaning_texts(row: dict[str, Any], key: str) -> list[str]:
    result: list[str] = []
    for meaning in row.get(key) or []:
        if isinstance(meaning, dict):
            text = meaning.get("meaning")
        else:
            text = meaning
        if str(text or "").strip():
            result.append(str(text).strip())
    return result


def candidate_rows(rows: list[dict[str, Any]], sample_size: int | None = None) -> list[dict[str, Any]]:
    candidates = [
        row
        for row in rows
        if row.get("id") is not None
        and row.get("word")
        and row.get("reading")
        and not row.get("meanings_jp")
        and (row.get("meanings_ko") or row.get("meanings") or row.get("meanings_en"))
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
    entries = []
    for row in rows:
        entries.append(
            {
                "key": draft_key(row),
                "word": row.get("word"),
                "reading": row.get("reading"),
                "korean_meanings": meaning_texts(row, "meanings_ko") or meaning_texts(row, "meanings"),
                "english_meanings": meaning_texts(row, "meanings_en"),
                "part_of_speech": [
                    meaning.get("part_of_speech", "")
                    for meaning in row.get("meanings_ko") or row.get("meanings") or []
                    if isinstance(meaning, dict) and meaning.get("part_of_speech")
                ][:4],
            }
        )
    return (
        "일본어 학습 앱의 words.meanings_jp에 넣을 일본어 국어사전식 뜻을 생성하세요.\n"
        "규칙:\n"
        "- 출력은 JSON 객체 하나만 반환하세요. 마크다운, 설명, 주석을 쓰지 마세요.\n"
        "- 스키마는 {\"translations\":[{\"key\":\"...\",\"meanings\":[\"...\"]}]} 입니다.\n"
        "- 입력의 key를 그대로 보존하세요.\n"
        "- meanings는 일본어 표현 1~4개만 넣으세요.\n"
        "- 한국어/영어로 번역하지 말고 일본어 국어사전의 짧은 풀이처럼 쓰세요.\n"
        "- 각 뜻은 60자 이내를 권장하고 예문은 쓰지 마세요.\n"
        "- 품사와 단어 표기를 고려해 가장 일반적인 의미를 우선하세요.\n\n"
        f"- 입력 entries {len(entries)}개 각각에 대해 translations 항목을 정확히 1개씩 반환하세요.\n\n"
        f"입력 JSON:\n{json.dumps({'entries': entries}, ensure_ascii=False, indent=2)}"
    )


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
) -> tuple[dict[str, list[str]], dict[str, Any]]:
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model or "default")
    checkpoint_dir = output_dir / "jp-word-meaning-cli" / provider / safe_model
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    schema_path = checkpoint_dir / "translation_schema.json"
    write_json(schema_path, TRANSLATION_SCHEMA)

    mapping: dict[str, list[str]] = {}
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
        parsed_output_path = checkpoint_dir / f"{base_name}_translations.json"
        codex_last_message_path = checkpoint_dir / f"{base_name}_codex_last_message.json"
        prompt_path.write_text(prompt, encoding="utf-8")
        prompt_files.append(str(prompt_path))
        if prompts_only:
            continue
        expected_keys = {draft_key(row) for row in batch_rows}
        try:
            generated_now = False
            if parsed_output_path.exists():
                batch_mapping = parse_translation_payload(parsed_output_path.read_text(encoding="utf-8"))
            else:
                if provider != "codex-cli":
                    raise ValueError(f"unsupported provider for KANJI-11 sample: {provider}")
                raw_output = run_codex_cli(prompt, model, timeout, schema_path, codex_last_message_path)
                raw_output_path.write_text(raw_output, encoding="utf-8")
                batch_mapping = parse_translation_payload(raw_output)
                write_json(
                    parsed_output_path,
                    {"translations": [{"key": key, "meanings": meanings} for key, meanings in sorted(batch_mapping.items())]},
                )
                generated_now = True
            missing_keys = sorted(expected_keys.difference(batch_mapping.keys()))
            if missing_keys and parsed_output_path.exists() and not generated_now:
                parsed_output_path.rename(parsed_output_path.with_suffix(".incomplete.json"))
                raw_output = run_codex_cli(prompt, model, timeout, schema_path, codex_last_message_path)
                raw_output_path.write_text(raw_output, encoding="utf-8")
                batch_mapping = parse_translation_payload(raw_output)
                write_json(
                    parsed_output_path,
                    {"translations": [{"key": key, "meanings": meanings} for key, meanings in sorted(batch_mapping.items())]},
                )
                missing_keys = sorted(expected_keys.difference(batch_mapping.keys()))
            if missing_keys:
                failed_batches.append({"batch": batch_index, "missing_keys": missing_keys[:20]})
            mapping.update(batch_mapping)
            completed_batches += 1
            print(f"jp word meaning batch {batch_index}/{len(batches)} translations={len(batch_mapping)}", flush=True)
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
        "translations": len(mapping),
    }


def apply_mapping(rows: list[dict[str, Any]], mapping: dict[str, list[str]]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for row in rows:
        jp_meanings = [
            {
                "part_of_speech": (row.get("meanings_ko") or row.get("meanings") or [{}])[0].get("part_of_speech", "")
                if isinstance((row.get("meanings_ko") or row.get("meanings") or [{}])[0], dict)
                else "",
                "meaning": meaning,
                "source": "ai_translation",
                "quality_status": "ai_draft",
            }
            for meaning in mapping.get(draft_key(row), [])
            if has_japanese(meaning)
        ]
        result.append({**row, "meanings_jp": dedupe_meanings(jp_meanings)})
    return result


def preflight(rows: list[dict[str, Any]], expected_count: int | None = None) -> dict[str, Any]:
    errors: list[dict[str, Any]] = []
    if expected_count is not None and len(rows) != expected_count:
        errors.append({"type": "unexpected_word_sample_count", "expected": expected_count, "actual": len(rows)})
    missing = [row.get("id") for row in rows if not row.get("meanings_jp")]
    non_japanese = [
        row.get("id")
        for row in rows
        if row.get("meanings_jp") and not any(has_japanese(meaning.get("meaning")) for meaning in row["meanings_jp"])
    ]
    if missing:
        errors.append({"type": "missing_meanings_jp", "ids": missing[:50]})
    if non_japanese:
        errors.append({"type": "meanings_jp_without_japanese_text", "ids": non_japanese[:50]})
    return {"failed": bool(errors), "errors": errors, "totals": {"words": len(rows), "kanji": 0}}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "kanji11")
    parser.add_argument("--output-prefix", default="words_jp_meanings_sample")
    parser.add_argument("--provider", choices=["codex-cli"], default="codex-cli")
    parser.add_argument("--model", default="")
    parser.add_argument("--sample-size", type=int, default=None, help="생략하거나 0이면 전체 후보를 처리합니다.")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--max-batches", type=int, default=None)
    parser.add_argument("--start-index", type=int, default=0, help="후보 목록에서 처리 시작 index")
    parser.add_argument("--limit", type=int, default=None, help="start-index 이후 최대 처리 row 수")
    parser.add_argument("--prompts-only", action="store_true")
    args = parser.parse_args()

    all_rows = rows_from_json(args.input)
    sample_rows = candidate_rows(all_rows, args.sample_size)
    if args.start_index or args.limit is not None:
        sample_rows = sample_rows[args.start_index : None if args.limit is None else args.start_index + args.limit]
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
    report_name = "words_jp_meanings_report" if args.output_prefix == "words_jp_meanings_sample" else f"{args.output_prefix}_report"
    write_json(args.output_dir / f"{args.output_prefix}.json", {"words": output_rows})
    write_json(args.output_dir / f"{report_name}.json", report)
    print(f"jp word meanings words={len(output_rows)} failed={report['preflight']['failed'] if report['preflight'] else None}")
    if report["preflight"] and report["preflight"]["failed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
