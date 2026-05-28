# KANJI-8 Validation Snapshot

운영 Supabase export 기준 `quality_status=ai_draft` 한자 검증 결과를 고정한 snapshot입니다.

## 포함 파일
- `kanji_validation_report.json.gz`: hard error/warning 및 batch/source/domain별 count
- `kanji_validation_candidates.json.gz`: 검수 대상 전체와 validation flags
- `kanji_review_sample_100.json.gz`: 우선 검수용 샘플 100개
- `kanji_review_apply_dry_run.json.gz`: 승인 항목 적용 dry-run 결과
- `manifest.json`: 체크섬, 복원 경로, count

## 복원
```bash
python3 kanji_study_app/scripts/data_pipeline/restore_snapshot.py \
  --snapshot kanji_study_app/data/snapshots/2026-05-28-kanji8-validation \
  --output-dir .context/data-pipeline/kanji8
```

이번 snapshot은 검증과 dry-run 결과만 보존합니다. 운영 DB 수정은 포함하지 않습니다.
