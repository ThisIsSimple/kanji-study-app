# KANJI-11 Full Multilingual Fill Snapshot

이 snapshot은 운영 DB의 빈 다국어 필드를 채운 KANJI-11 전체 적용 산출물입니다.

## 포함 내용

- `words_jp_meanings_full.json.gz`: `words.meanings_jp` 생성 결과 56,309개
- `kanji_multilang_full.json.gz`: `kanji.jp_meanings`, `jp_commentary`, `en_commentary` 생성 결과 4,102개
- `multilingual_content_patch_dry_run.json.gz`: 운영 반영 전 patch dry-run
- `multilingual_content_apply_report.json.gz`: 운영 patch apply 결과
- `post_multilingual_fill_check_report.json.gz`: 운영 반영 후 검증 결과
- `multilingual_fill_candidate_report.json.gz`, `multilingual_fill_merge_report.json.gz`: 후보 및 병합 검증 리포트

## 운영 가이드

`.context`는 임시 작업 폴더이므로 영구 보관 대상으로 보지 않습니다. 후속 agent가 이 작업을 재확인해야 하면 이 snapshot을 복원해서 `.context/data-pipeline/kanji11-full/` 아래에 압축 해제한 뒤 리포트를 확인하세요.

압축 해제된 JSON은 Git에 올리지 않습니다. 필요한 경우 `scripts/data_pipeline/restore_snapshot.py` 또는 `manifest.json`의 `restore_to` 경로를 기준으로 복원합니다.

이번 적용은 전체 row upsert가 아니라 `id` 기준 patch입니다. `words`는 `meanings_jp`, `kanji`는 `jp_meanings`, `jp_commentary`, `en_commentary`, 그리고 공통 `updated_at`만 변경했습니다.
