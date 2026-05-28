# KANJI-11 Full Multilingual Fill Summary

## 운영 반영 결과

- 운영 export 기준: 단어 56,310개, 한자 4,102개
- `words.meanings_jp` patch: 56,309개
- `kanji.jp_meanings`, `kanji.jp_commentary`, `kanji.en_commentary` patch: 4,102개
- apply 실패: 0건
- post-check 실패: 0건

## 보호 필드 검증

- `words.meanings`, `words.meanings_ko`, `words.meanings_en` 변경 감지: 0건
- `kanji.meanings`, `kanji.meanings_ko`, `kanji.meanings_en`, `commentary`, `kr_commentary`, `tags` 변경 감지: 0건

## 생성 방식

- 생성 경로: Codex CLI checkpoint 기반
- API key 기반 생성 경로: 사용하지 않음
- 운영 반영 경로: Supabase REST `PATCH`, `id` 기준, 허용 필드만 전송
