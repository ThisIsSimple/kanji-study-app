# KANJI-9 Full Backlog Snapshot

이 snapshot은 `.context/data-pipeline`에만 있던 전체 후보 풀을 Git에서 복원 가능하게 보존합니다. 운영 DB 반영, 앱 UI 변경, 신규 후보 선정은 포함하지 않습니다.

## 포함 파일
- `merged_words.json.gz`: 병합 완료 단어 후보 296,611개
- `merged_kanji.json.gz`: 병합 완료 한자 후보 13,110개
- `normalized_jmdict_words.json.gz`: JMdict 정규화 단어 299,143개
- `normalized_kanjidic_kanji.json.gz`: KANJIDIC2/Unihan 정규화 한자 13,108개
- `merge_report.json.gz`: 병합 리포트
- `manifest.json`: 체크섬, 크기, 복원 경로, count

## 복원
```bash
python3 kanji_study_app/scripts/data_pipeline/restore_snapshot.py \
  --snapshot kanji_study_app/data/snapshots/2026-05-28-kanji9-full-backlog \
  --output-dir .context/data-pipeline
```

## Agent 가이드
- `.context`는 임시 작업 폴더이므로 전체 backlog의 원본으로 신뢰하지 않습니다.
- 다음 batch 선정 작업은 이 snapshot을 복원한 뒤 `merged_words.json`과 `merged_kanji.json`에서 시작합니다.
- 압축 해제된 `.json` 파일은 Git에 올리지 않습니다. `.gitignore` 정책상 snapshot 안의 gzip만 커밋합니다.
- 운영 DB에 바로 전량 upsert하지 말고, batch selection → 한국어 뜻 생성 → 검수/검증 → import 후보 snapshot → dry-run/apply 순서로 진행합니다.
