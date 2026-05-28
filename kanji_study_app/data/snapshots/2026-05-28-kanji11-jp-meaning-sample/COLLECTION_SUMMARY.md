# KANJI-11 Collection Summary

## 범위
- 단어 샘플: 100개
- 한자 샘플: 50개
- 운영 upsert: 실행하지 않음

## 생성 필드
- `words.meanings_jp`: 일본어 국어사전식 뜻 초안
- `kanji.jp_meanings`: 일본어 한자 뜻 초안
- `kanji.jp_commentary`: 일본어 한자 해설 초안
- `kanji.en_commentary`: 영어 한자 해설 초안
- `kanji.kr_*`, `kanji.jp_on_readings`, `kanji.jp_kun_readings`, `kanji.en_meanings`: 기존 데이터 기반 호환 백필

## 검증 결과
- 단어 `meanings_jp` 누락: 0
- 한자 `jp_meanings` 누락: 0
- 한자 `jp_commentary` 누락: 0
- 한자 `en_commentary` 누락: 0
- 샘플 preflight 실패: false
- dry-run 대상: words 100개, kanji 50개

## 다음 단계
샘플 품질을 사람이 확인한 뒤, 전체 운영 데이터에 대해 같은 파이프라인을 확장 적용한다.
