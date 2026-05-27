# Data Snapshots

이 디렉터리는 AI 에이전트와 데이터 파이프라인이 재사용할 수 있는 영구 데이터 스냅샷을 보관합니다.

## 원칙

- `.context/`는 임시 작업 공간입니다. 영구 보관 기준 데이터는 이 디렉터리의 snapshot을 사용합니다.
- 큰 JSON은 `*.json.gz`로만 커밋합니다.
- 압축 해제된 `*.json` 작업 파일은 Git에 올리지 않습니다. `.gitignore`가 `data/snapshots/**/*.json`을 차단합니다.
- 각 snapshot은 `manifest.json`에 파일별 체크섬, 복원 경로, row count를 기록합니다.

## 현재 기준 스냅샷

- `snapshots/2026-05-28-kanji6-v1/`
- 단어 import 후보: 46,308개
- 한자 import 후보: 2,136개
- `meanings`/`meanings_ko`의 영어-only 값: 0개
- `meanings_en` 보존: 단어 44,050개, 한자 2,134개
- preflight 실패: 없음

## 작업 시작 절차

```sh
python scripts/data_pipeline/restore_snapshot.py \
  --snapshot data/snapshots/2026-05-28-kanji6-v1
```

기본 복원 위치는 repo 루트 기준 `.context/data-pipeline/`입니다. 복원 후 다음 파일을 기준으로 dry-run 또는 import 작업을 진행합니다.

- `.context/data-pipeline/recommended_v1_words_split_meanings.json`
- `.context/data-pipeline/recommended_v1_kanji_split_meanings.json`
- `.context/data-pipeline/split_meanings_report.json`
- `.context/data-pipeline/recommended_v1_split_import_dry_run.json`

## Import 전 확인

```sh
python scripts/data_pipeline/import_to_supabase.py \
  --words ../.context/data-pipeline/recommended_v1_words_split_meanings.json \
  --kanji ../.context/data-pipeline/recommended_v1_kanji_split_meanings.json
```

`split_meanings_report.json`의 preflight가 실패 상태면 import 스크립트가 중단됩니다.
