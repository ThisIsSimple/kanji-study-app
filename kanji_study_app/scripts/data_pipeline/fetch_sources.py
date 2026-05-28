#!/usr/bin/env python3
"""Download open-license source files and record their metadata."""

from __future__ import annotations

import argparse
import datetime as dt
import urllib.request
from dataclasses import dataclass
from pathlib import Path

from common import DEFAULT_SOURCE_DIR, ensure_dir, sha256_file, write_json


@dataclass(frozen=True)
class SourceSpec:
    name: str
    url: str
    filename: str
    license: str
    attribution_url: str


SOURCES = {
    "jmdict": SourceSpec(
        name="jmdict",
        url="https://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz",
        filename="JMdict_e.gz",
        license="CC BY-SA 4.0",
        attribution_url="https://www.edrdg.org/wiki/JMdict-EDICT_Dictionary_Project.html",
    ),
    "kanjidic2": SourceSpec(
        name="kanjidic2",
        url="https://www.edrdg.org/kanjidic/kanjidic2.xml.gz",
        filename="kanjidic2.xml.gz",
        license="CC BY-SA 4.0",
        attribution_url="https://www.edrdg.org/kanjidic/kanjd2index_legacy.html",
    ),
    "unihan": SourceSpec(
        name="unihan",
        url="https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip",
        filename="Unihan.zip",
        license="Unicode-3.0",
        attribution_url="https://unicode.org/reports/tr38/",
    ),
    "tatoeba_sentences": SourceSpec(
        name="tatoeba_sentences",
        url="https://downloads.tatoeba.org/exports/sentences.tar.bz2",
        filename="sentences.tar.bz2",
        license="CC BY 2.0 FR / CC0 1.0 mixed",
        attribution_url="https://tatoeba.org/en/downloads",
    ),
    "tatoeba_links": SourceSpec(
        name="tatoeba_links",
        url="https://downloads.tatoeba.org/exports/links.tar.bz2",
        filename="links.tar.bz2",
        license="CC BY 2.0 FR / CC0 1.0 mixed",
        attribution_url="https://tatoeba.org/en/downloads",
    ),
}


def download(spec: SourceSpec, output_dir: Path, force: bool = False) -> dict:
    ensure_dir(output_dir)
    destination = output_dir / spec.filename
    headers: dict[str, str] = {}
    if destination.exists() and not force:
        return metadata_for(spec, destination, headers, skipped=True)

    request = urllib.request.Request(spec.url, headers={"User-Agent": "konnakanji-data-pipeline/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        headers = {key.lower(): value for key, value in response.headers.items()}
        with destination.open("wb") as file:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                file.write(chunk)

    return metadata_for(spec, destination, headers, skipped=False)


def metadata_for(
    spec: SourceSpec,
    path: Path,
    headers: dict[str, str],
    skipped: bool,
) -> dict:
    last_modified = headers.get("last-modified")
    source_version = last_modified or dt.date.today().isoformat()
    return {
        "source": spec.name,
        "source_url": spec.url,
        "filename": path.name,
        "path": str(path),
        "license": spec.license,
        "attribution_url": spec.attribution_url,
        "source_version": source_version,
        "sha256": sha256_file(path),
        "bytes": path.stat().st_size,
        "fetched_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "skipped_existing_file": skipped,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--force", action="store_true", help="이미 받은 파일도 다시 다운로드")
    parser.add_argument(
        "--sources",
        nargs="+",
        choices=sorted(SOURCES),
        default=sorted(SOURCES),
    )
    args = parser.parse_args()

    manifest = [download(SOURCES[name], args.output_dir, args.force) for name in args.sources]
    write_json(args.output_dir / "manifest.json", {"sources": manifest})
    for item in manifest:
        print(f"{item['source']}: {item['filename']} {item['sha256'][:12]}")


if __name__ == "__main__":
    main()
