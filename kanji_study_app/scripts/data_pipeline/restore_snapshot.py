#!/usr/bin/env python3
"""Restore a checked-in compressed data snapshot into a working directory."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
from pathlib import Path
from typing import Any

from common import DEFAULT_OUTPUT_DIR, ensure_dir, read_json


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def restore_file(snapshot_dir: Path, file_info: dict[str, Any], output_dir: Path) -> dict[str, Any]:
    source_path = snapshot_dir / file_info["path"]
    compressed = source_path.read_bytes()
    if sha256_bytes(compressed) != file_info["sha256_compressed"]:
        raise ValueError(f"compressed checksum mismatch: {source_path}")

    raw = gzip.decompress(compressed)
    if sha256_bytes(raw) != file_info["sha256_uncompressed"]:
        raise ValueError(f"uncompressed checksum mismatch: {source_path}")

    restore_name = Path(file_info["restore_to"]).name
    target_path = output_dir / restore_name
    ensure_dir(target_path.parent)
    target_path.write_bytes(raw)
    return {
        "source": str(source_path),
        "target": str(target_path),
        "bytes": len(raw),
        "sha256": file_info["sha256_uncompressed"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot", type=Path, required=True, help="snapshot directory containing manifest.json")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    manifest = read_json(args.snapshot / "manifest.json")
    restored = [restore_file(args.snapshot, file_info, args.output_dir) for file_info in manifest["files"]]
    print(
        f"restored snapshot={manifest['snapshot_id']} files={len(restored)} "
        f"output_dir={args.output_dir}"
    )
    for item in restored:
        print(f"- {item['target']} ({item['bytes']} bytes)")


if __name__ == "__main__":
    main()
