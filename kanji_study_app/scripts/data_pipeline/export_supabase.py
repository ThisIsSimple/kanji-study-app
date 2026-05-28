#!/usr/bin/env python3
"""Export current Supabase kanji and words tables for deterministic merging."""

from __future__ import annotations

import argparse
import os
import ssl
import urllib.parse
import urllib.request
from pathlib import Path
import json

from common import DEFAULT_OUTPUT_DIR, write_json


def fetch_table(table: str, batch_size: int) -> list[dict]:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_ANON_KEY") or os.getenv("SUPABASE_SECRET_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_ANON_KEY, SUPABASE_SECRET_KEY, or SUPABASE_SERVICE_ROLE_KEY are required"
        )

    rows: list[dict] = []
    offset = 0
    context = ssl_context()
    while True:
        query = urllib.parse.urlencode({"select": "*", "order": "id.asc", "limit": str(batch_size), "offset": str(offset)})
        request = urllib.request.Request(
            f"{url.rstrip('/')}/rest/v1/{table}?{query}",
            headers={"apikey": key, "Authorization": f"Bearer {key}"},
        )
        with urllib.request.urlopen(request, timeout=60, context=context) as response:
            batch = json.loads(response.read().decode("utf-8"))
        if not batch:
            break
        rows.extend(batch)
        if len(batch) < batch_size:
            break
        offset += batch_size
    return rows


def ssl_context():
    if os.getenv("SUPABASE_INSECURE_SKIP_TLS_VERIFY") == "1":
        return ssl._create_unverified_context()
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ModuleNotFoundError:
        return ssl.create_default_context()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR / "exports")
    parser.add_argument("--batch-size", type=int, default=1000)
    args = parser.parse_args()

    words = fetch_table("words", args.batch_size)
    kanji = fetch_table("kanji", args.batch_size)
    write_json(args.output_dir / "words.json", {"words": words})
    write_json(args.output_dir / "kanji.json", {"kanji": kanji})
    print(f"exported words={len(words)} kanji={len(kanji)} -> {args.output_dir}")


if __name__ == "__main__":
    main()
