#!/usr/bin/env python3
"""Generate or apply Korean meaning drafts for entries without Korean meanings."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import urllib.request
from pathlib import Path
from typing import Any

from common import QUALITY_AI_DRAFT, add_common_output_args, dedupe_meanings, read_json, write_json


HANGUL_RE = re.compile(r"[가-힣]")
JSON_FENCE_RE = re.compile(r"^```(?:json)?\s*|\s*```$", re.S)
DEFAULT_CLI_BATCH_SIZE = 50


TRANSLATION_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["translations"],
    "properties": {
        "translations": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["key", "meanings"],
                "properties": {
                    "key": {"type": "string"},
                    "meanings": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 6,
                        "items": {"type": "string"},
                    },
                },
            },
        },
    },
}


def has_korean_meaning(row: dict[str, Any]) -> bool:
    return any(HANGUL_RE.search(str(meaning.get("meaning", ""))) for meaning in row.get("meanings") or [])


def draft_key(row: dict[str, Any]) -> str:
    return row.get("external_id") or f"{row.get('word')}|{row.get('reading')}"


def load_mapping(path: Path | None) -> dict[str, list[str]]:
    if not path:
        return {}
    data = read_json(path)
    if not isinstance(data, dict):
        raise ValueError("translation map must be a JSON object")
    result: dict[str, list[str]] = {}
    for key, value in data.items():
        if isinstance(value, str):
            result[key] = [value]
        elif isinstance(value, list):
            result[key] = [str(item) for item in value if str(item).strip()]
    return result


def gemini_translate(row: dict[str, Any], model: str) -> list[str]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return []
    glosses = [meaning.get("meaning", "") for meaning in row.get("meanings") or []]
    prompt = (
        "일본어 학습 앱에 넣을 한국어 뜻 초안을 JSON 배열로만 반환하세요. "
        "간결한 사전식 표현만 쓰고 설명 문장은 쓰지 마세요.\n"
        f"단어: {row.get('word')}\n읽기: {row.get('reading')}\n영어 뜻: {glosses}"
    )
    body = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode("utf-8")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    request = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))
    text = payload["candidates"][0]["content"]["parts"][0]["text"].strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*|\s*```$", "", text, flags=re.S)
    parsed = json.loads(text)
    if not isinstance(parsed, list):
        return []
    return [str(item).strip() for item in parsed if str(item).strip()]


def rows_needing_translation(words: list[dict[str, Any]], limit: int | None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in words:
        if has_korean_meaning(row):
            continue
        if row.get("quality_status") != QUALITY_AI_DRAFT:
            continue
        rows.append(row)
        if limit is not None and len(rows) >= limit:
            break
    return rows


def build_cli_prompt(rows: list[dict[str, Any]]) -> str:
    entries = []
    for row in rows:
        entries.append(
            {
                "key": draft_key(row),
                "word": row.get("word"),
                "reading": row.get("reading"),
                "part_of_speech": [
                    meaning.get("part_of_speech", "")
                    for meaning in row.get("meanings") or []
                    if meaning.get("part_of_speech")
                ][:4],
                "english_meanings": [meaning.get("meaning", "") for meaning in row.get("meanings") or []],
            }
        )
    return (
        "일본어 학습 앱에 넣을 한국어 뜻 초안을 생성하세요.\n"
        "규칙:\n"
        "- 출력은 JSON 객체 하나만 반환하세요. 마크다운, 설명, 주석을 쓰지 마세요.\n"
        "- 스키마는 {\"translations\":[{\"key\":\"...\",\"meanings\":[\"...\"]}]} 입니다.\n"
        "- 입력의 key를 그대로 보존하세요.\n"
        "- meanings는 한국어 사전식 표현 1~6개만 넣으세요.\n"
        "- 영어 뜻을 직역하지 말고 일본어 단어/읽기에 맞는 자연스러운 한국어 뜻을 쓰세요.\n"
        "- 뜻마다 30자 이내를 권장하고, 예문/설명 문장은 쓰지 마세요.\n"
        "- 확실하지 않으면 가장 일반적인 뜻만 반환하세요.\n\n"
        f"- 입력 entries {len(entries)}개 각각에 대해 translations 항목을 정확히 1개씩 반환하세요.\n\n"
        f"입력 JSON:\n{json.dumps({'entries': entries}, ensure_ascii=False, indent=2)}"
    )


def parse_translation_payload(text: str) -> dict[str, list[str]]:
    raw = text.strip()
    if not raw:
        return {}
    parsed: Any
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        parsed = json.loads(JSON_FENCE_RE.sub("", raw).strip())

    if isinstance(parsed, dict):
        structured_output = parsed.get("structured_output")
        if isinstance(structured_output, dict):
            translations = structured_output.get("translations")
            if isinstance(translations, list):
                parsed = structured_output
        for wrapper_key in ("result", "message", "content", "last_message"):
            nested = parsed.get(wrapper_key)
            if isinstance(nested, str):
                return parse_translation_payload(nested)
        translations = parsed.get("translations")
    else:
        translations = parsed

    if not isinstance(translations, list):
        return {}

    result: dict[str, list[str]] = {}
    for item in translations:
        if not isinstance(item, dict):
            continue
        key = str(item.get("key") or "").strip()
        meanings = item.get("meanings")
        if not key or not isinstance(meanings, list):
            continue
        clean_meanings = [str(meaning).strip() for meaning in meanings if str(meaning).strip()]
        if clean_meanings:
            result[key] = clean_meanings
    return result


def batched(rows: list[dict[str, Any]], size: int) -> list[list[dict[str, Any]]]:
    return [rows[index : index + size] for index in range(0, len(rows), size)]


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
    checkpoint_dir = output_dir / "ko-draft-cli" / provider / safe_model
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    schema_path = checkpoint_dir / "translation_schema.json"
    write_json(schema_path, TRANSLATION_SCHEMA)

    mapping: dict[str, list[str]] = {}
    batches = batched(rows, batch_size)
    if max_batches is not None:
        batches = batches[:max_batches]

    completed_batches = 0
    failed_batches: list[dict[str, Any]] = []
    prompt_files: list[str] = []
    for batch_index, batch_rows in enumerate(batches, start=1):
        prompt = build_cli_prompt(batch_rows)
        prompt_hash = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:12]
        base_name = f"batch_{batch_index:06d}_{prompt_hash}"
        prompt_path = checkpoint_dir / f"{base_name}_prompt.txt"
        raw_output_path = checkpoint_dir / f"{base_name}_raw.txt"
        parsed_output_path = checkpoint_dir / f"{base_name}_translations.json"
        codex_last_message_path = checkpoint_dir / f"{base_name}_codex_last_message.json"

        expected_keys = {draft_key(row) for row in batch_rows}
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
                if provider == "claude-cli":
                    raw_output = run_claude_cli(prompt, model, timeout, schema_path)
                elif provider == "codex-cli":
                    raw_output = run_codex_cli(prompt, model, timeout, schema_path, codex_last_message_path)
                else:
                    raise ValueError(f"unsupported CLI provider: {provider}")
                raw_output_path.write_text(raw_output, encoding="utf-8")
                batch_mapping = parse_translation_payload(raw_output)
                write_json(
                    parsed_output_path,
                    {
                        "translations": [
                            {"key": key, "meanings": meanings} for key, meanings in sorted(batch_mapping.items())
                        ]
                    },
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
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError, ValueError) as error:
            failed_batches.append({"batch": batch_index, "prompt": str(prompt_path), **cli_error_report(error)})

    report = {
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
    return mapping, report


def checkpoint_dir_for(output_dir: Path, provider: str, model: str) -> Path:
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model or "default")
    return output_dir / "ko-draft-cli" / provider / safe_model


def load_checkpoint_mapping(output_dir: Path, provider: str, model: str) -> dict[str, list[str]]:
    checkpoint_dir = checkpoint_dir_for(output_dir, provider, model)
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


def apply_mapping_to_words(
    words: list[dict[str, Any]],
    mapping: dict[str, list[str]],
    limit: int | None,
    allowed_keys: set[str] | None = None,
) -> tuple[int, int, list[dict[str, Any]]]:
    updated = 0
    skipped = 0
    exported_prompts: list[dict[str, Any]] = []
    for row in words:
        if has_korean_meaning(row):
            skipped += 1
            continue
        if row.get("quality_status") != QUALITY_AI_DRAFT:
            skipped += 1
            continue
        if limit is not None and updated >= limit:
            break

        key = draft_key(row)
        if allowed_keys is not None and key not in allowed_keys:
            continue
        drafts = mapping.get(key) or mapping.get(f"{row.get('word')}|{row.get('reading')}") or []
        if not drafts:
            exported_prompts.append(
                {
                    "key": key,
                    "word": row.get("word"),
                    "reading": row.get("reading"),
                    "english_meanings": [m.get("meaning") for m in row.get("meanings") or []],
                }
            )
            continue

        pos = ""
        if row.get("meanings"):
            pos = row["meanings"][0].get("part_of_speech", "")
        row["meanings"] = dedupe_meanings(
            [
                {
                    "part_of_speech": pos,
                    "meaning": draft,
                    "source": "ai_translation",
                    "quality_status": QUALITY_AI_DRAFT,
                }
                for draft in drafts
            ]
        )
        row["meaning_source"] = "ai_translation"
        row["quality_status"] = QUALITY_AI_DRAFT
        updated += 1
    return updated, skipped, exported_prompts


def apply_drafts(
    words: list[dict[str, Any]],
    mapping: dict[str, list[str]],
    provider: str,
    model: str,
    limit: int | None,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    cli_report: dict[str, Any] | None = None
    candidate_rows = rows_needing_translation(words, limit)
    target_rows = candidate_rows
    allowed_keys: set[str] | None = None
    if provider in ("claude-cli", "codex-cli"):
        checkpoint_mapping = load_checkpoint_mapping(apply_drafts.output_dir, provider, model)
        mapping = {**checkpoint_mapping, **mapping}
        target_rows = [row for row in target_rows if draft_key(row) not in mapping]
        if apply_drafts.max_batches is not None:
            target_rows = target_rows[: apply_drafts.batch_size * apply_drafts.max_batches]
        cli_mapping, cli_report = generate_cli_mapping(
            target_rows,
            provider,
            model,
            apply_drafts.output_dir,
            apply_drafts.batch_size,
            apply_drafts.max_batches,
            apply_drafts.timeout,
            apply_drafts.prompts_only,
        )
        mapping = {**mapping, **cli_mapping}
        allowed_keys = {draft_key(row) for row in candidate_rows}
        cli_report["checkpoint_translations"] = len(checkpoint_mapping)
        cli_report["generated_target_rows"] = len(target_rows)
    else:
        allowed_keys = None
    if provider == "none":
        mapping = {}

    if apply_drafts.prompts_only:
        report = {
            "updated": 0,
            "skipped": 0,
            "needs_translation": [
                {
                    "key": draft_key(row),
                    "word": row.get("word"),
                    "reading": row.get("reading"),
                    "english_meanings": [m.get("meaning") for m in row.get("meanings") or []],
                }
                for row in target_rows
            ],
        }
        if cli_report is not None:
            report["cli"] = cli_report
        return words, report

    updated, skipped, exported_prompts = apply_mapping_to_words(words, mapping, limit, allowed_keys)
    if provider == "gemini":
        for row in words:
            if has_korean_meaning(row):
                continue
            if row.get("quality_status") != QUALITY_AI_DRAFT:
                continue
            if limit is not None and updated >= limit:
                break

            drafts = gemini_translate(row, model)
            if not drafts:
                continue
            single_mapping = {draft_key(row): drafts}
            changed, _, _ = apply_mapping_to_words([row], single_mapping, None)
            updated += changed

    report = {"updated": updated, "skipped": skipped, "needs_translation": exported_prompts}
    if cli_report is not None:
        report["cli"] = cli_report
    return words, report


apply_drafts.output_dir = Path(".")
apply_drafts.batch_size = DEFAULT_CLI_BATCH_SIZE
apply_drafts.max_batches = None
apply_drafts.timeout = 900
apply_drafts.prompts_only = False


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="merged_words.json")
    parser.add_argument("--translation-map", type=Path, help="external_id 또는 word|reading -> 한국어 뜻 배열")
    parser.add_argument("--provider", choices=["none", "mapping", "gemini", "claude-cli", "codex-cli"], default="mapping")
    parser.add_argument("--model", help="provider별 모델명. gemini 기본값은 gemini-1.5-flash, claude-cli 기본값은 sonnet")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--batch-size", type=int, default=DEFAULT_CLI_BATCH_SIZE)
    parser.add_argument("--max-batches", type=int, help="CLI 실행 시 처리할 최대 배치 수")
    parser.add_argument("--timeout", type=int, default=900, help="CLI 배치 1개당 timeout seconds")
    parser.add_argument("--prompts-only", action="store_true", help="CLI 실행 없이 배치 프롬프트와 스키마만 생성")
    add_common_output_args(parser)
    args = parser.parse_args()

    data = read_json(args.input)
    words = data["words"]
    mapping = load_mapping(args.translation_map)
    model = args.model
    if not model:
        if args.provider == "gemini":
            model = "gemini-1.5-flash"
        elif args.provider == "claude-cli":
            model = "sonnet"
        else:
            model = ""
    apply_drafts.output_dir = args.output_dir
    apply_drafts.batch_size = args.batch_size
    apply_drafts.max_batches = args.max_batches
    apply_drafts.timeout = args.timeout
    apply_drafts.prompts_only = args.prompts_only
    words, report = apply_drafts(words, mapping, args.provider, model, args.limit)
    write_json(args.output_dir / "merged_words_with_ko_drafts.json", {"words": words})
    write_json(args.output_dir / "ko_draft_report.json", report)
    print(f"ko_drafts updated={report['updated']} needs_translation={len(report['needs_translation'])}")


if __name__ == "__main__":
    main()
