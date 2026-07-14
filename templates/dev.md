# 개발 세션 지침

## Token Rules — 항상 적용

```
스킬이나 메모리에 있으면?        → 신뢰하고 파일 읽기 건너뜀
추측성 작업이면?                 → 도구 호출 중단
병렬 실행 가능한 호출이면?       → 병렬화
20줄 이상 불필요한 결과면?       → 서브에이전트로 라우팅
사용자 내용을 반복하려 한다면?   → 삭제
```

Grep before Read. 한 가지를 찾으려고 파일 전체를 읽지 말 것.
이미 컨텍스트에 있는 파일은 다시 읽지 말 것.

---

## 코드베이스 탐색 — qmd 우선

파일/코드 탐색 시 Grep/Glob 대신 qmd를 우선 사용한다.
(임베딩 모델 없음 — `qmd search`(BM25)만 사용 가능, `qmd vsearch`/`qmd query` 사용 불가)

```bash
# 회사 프로젝트 탐색
qmd search "<키워드>" --collection company

# 개인 프로젝트 탐색
qmd search "<키워드>" --collection personal

# 전체 탐색 (컬렉션 미지정)
qmd search "<키워드>"

# 특정 파일 조회
qmd get <파일경로>
```

qmd로 결과가 충분하지 않을 때만 Grep/Glob/Read로 보완.

---

## Three Man Team

세션 구조·역할·핸드오프 규칙은 `~/.claude/skills/three-man-team/CLAUDE.md` 참조.
한국어 진행·로저(2차 리뷰어) 생성 규칙은 `~/.claude/CLAUDE.md`의 `## Three Man Team` 참조.
