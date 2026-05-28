# KANJI-7 v2 Import Snapshot

이 snapshot은 KANJI-7 v2 운영 반영 후보를 고정하기 위한 압축 보관본입니다.

## 포함 파일
- `recommended_v2_words_split_meanings.json.gz`: 단어 10,000개 import 후보
- `recommended_v2_kanji_split_meanings.json.gz`: 한자 1,000개 import 후보
- `recommended_v2_split_meanings_report.json.gz`: split 생성 리포트
- `recommended_v2_quality_report.json.gz`: 표시 뜻/영어 gloss/preflight 검증 리포트
- `recommended_v2_import_dry_run.json.gz`: import dry-run 리포트
- `tag_backfill_dry_run.json.gz`: 기존 v1 운영 데이터 태그 backfill dry-run 리포트
- `recommended_v2_import_apply_report.json.gz`: 운영 반영 실행 리포트
- `post_v2_upsert_check_report.json.gz`: 운영 반영 후 검증 리포트
- `manifest.json`: 체크섬, 복원 경로, count

## 복원
```bash
python3 kanji_study_app/scripts/data_pipeline/restore_snapshot.py \
  --snapshot kanji_study_app/data/snapshots/2026-05-28-kanji7-v2-import \
  --output-dir .context/data-pipeline/kanji7-v2
```

`tag_backfill_dry_run.json`은 복원 후 필요하면 `.context/data-pipeline/`로 이동하거나 manifest의 `restore_to` 값을 참고해 사용합니다.

## 운영 기준
- 신규 upsert 대상: words 10,000개, kanji 1,000개
- 기존 row 수정 범위: `tags` 병합 backfill
- `meanings`/`meanings_ko`: 한국어 표시 뜻만 저장
- `meanings_en`: JMdict/KANJIDIC2 영어 gloss 보존
