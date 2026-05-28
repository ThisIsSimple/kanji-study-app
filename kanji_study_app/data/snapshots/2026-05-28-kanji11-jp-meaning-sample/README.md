# KANJI-11 Japanese Meaning Sample Snapshot

이 snapshot은 KANJI-11의 전체 운영 반영 전 검토용 샘플 산출물입니다.

## 포함 파일
- `words_jp_meanings_sample.json.gz`: `words.meanings_jp`가 채워진 단어 100개 샘플
- `words_jp_meanings_report.json.gz`: 단어 샘플 생성 리포트
- `kanji_multilang_sample.json.gz`: `kanji` 다국어 호환 필드가 채워진 한자 50개 샘플
- `kanji_multilang_report.json.gz`: 한자 샘플 생성 리포트
- `kanji11_sample_preflight_report.json.gz`: 샘플 preflight 통합 리포트
- `kanji11_sample_import_dry_run.json.gz`: Supabase upsert dry-run 리포트
- `manifest.json`: 체크섬, 복원 경로, count

## 복원
```bash
python3 kanji_study_app/scripts/data_pipeline/restore_snapshot.py \
  --snapshot kanji_study_app/data/snapshots/2026-05-28-kanji11-jp-meaning-sample \
  --output-dir .context/data-pipeline/kanji11
```

## 운영 기준
- 이 snapshot은 샘플 검토용이며 운영 DB에 upsert하지 않았다.
- AI 생성은 Codex CLI 체크포인트 방식으로 진행했고 API key 기반 생성 경로는 사용하지 않았다.
- 단어는 `meanings_jp`만 추가하고 기존 한국어/영어 뜻을 덮어쓰지 않는다.
- 한자는 `jp_*`, `kr_*`, `en_*` 호환 컬럼을 추가로 채우며 기존 컬럼을 삭제하거나 rename하지 않는다.
- 전체 운영 반영은 샘플 품질 확인 후 별도 이슈에서 진행한다.
