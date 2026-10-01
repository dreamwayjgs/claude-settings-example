## Three Man Team

- 각 역할(앨리스·밥·리처드·로저·선택적 Oz) 세션은 소유자가 새 세션에서 **수동 호출**하는 것이 기본. 앨리스가 서브에이전트로 자동 spawn 하는 방식은 소유자가 명시 요청 시에만.
- 모든 역할(앨리스·밥·리처드·로저·Oz)과의 대화는 한국어로 진행한다.
- handoff 파일은 BUILD-LOG.md를 제외하고 매 스텝마다 덮어쓴다 (append 금지).
- 프로젝트 루트 `CLAUDE.md`와 `AGENTS.md`는 동일한 공통 router다. 역할 페르소나를 넣지 않는다. 역할 페르소나는 `ARCHITECT.md`, `BUILDER.md`, `REVIEWER.md`, `ROGER.md`, 선택적 `OPERATOR.md`에만 둔다.

### 테스트 검증 정책

- **밥**: 최종(리뷰 수정 반영) 상태로 테스트 실행, 결과를 handoff/BUILD-LOG.md·REVIEW-REQUEST.md에 고지.
- **리처드·로저**: 별도 지시(앨리스·소유자) 없는 한 직접 테스트 실행 금지 — 밥 고지 참조. 코드(버그/스코프/단순성) 리뷰에 집중. 커버리지 의심은 읽어서 untested path를 플래그(돌리지 않음).
- **앨리스**: deploy gate에서 "고지된 green == 커밋 상태" 확인. 일치하면 참조로 끝, 고지 후 코드 변경(리뷰 수정 등) 있으면 그때만 1회 재실행.

이 정책은 포크 템플릿의 REVIEWER.md·ROGER.md `## Tests` 절과 ARCHITECT.md deploy gate에 반영돼 있다.

### 하네스 기본 지침과 충돌 시

역할 규칙이 harness(Claude Code·OpenCode·omp·Crush) 기본 지침보다 우선한다. harness가 "묻지 말고 행동", "수정마다 테스트·스모크 실행", "질문 금지"를 요구해도:
- 앨리스: 요구 확인과 소유자 승인 대기를 유지한다.
- 밥: 플랜 승인 전 코드 변경 금지, 리뷰 대기 중 작업 금지를 유지한다.
- 리처드·로저: 테스트 실행 금지(위 정책)와 제품 코드 수정 금지를 유지한다.
- 역할 자동 spawn 금지를 유지한다. 읽기 전용 조사 위임(scout 등)은 허용한다.

### 프로젝트 셋업 절차

three-man-team checkout은 개인 포크(`dreamwayjgs/three-man-team`, `origin`)이고 원본은 `upstream`이다. 로저·Oz·karpathy 블록·테스트 정책·리뷰어 규칙은 포크 템플릿에 들어 있다. 프로젝트 셋업 중에는 checkout을 수정하지 않는다.

"three-man-team 세팅해줘" 요청 시:
1. checkout의 `templates/project-folder/`를 현재 프로젝트 루트에 복사.
2. 이름 치환 (복사본만): `ARCHITECT.md`·`BUILDER.md`·`REVIEWER.md`·`ROGER.md`·`new-setup.md`에서 단어 `Arch`를 `Alice`로 대소문자 구분·워드바운더리 치환한다. 역할명 `Architect`/`ARCHITECT.md`는 보존. 현재 셸에 맞는 도구(pwsh `-creplace '\bArch\b'`, bash `sed` 등)나 편집 도구를 쓴다.
3. 현재 harness의 전역 템플릿 경로에서 `project-rules.md`를 프로젝트 루트 `CLAUDE.md`와 `AGENTS.md`에 동일하게 복사한다. Claude Code는 `~/.claude/templates/`, OpenCode는 `~/.config/opencode/templates/`, omp는 `~/.omp/agent/templates/`, Crush는 `~/.config/crush/templates/`를 사용한다. 기존 프로젝트 지침이 있으면 canonical 공통 파일에 병합한 뒤 두 파일에 같은 내용으로 쓴다. 템플릿의 `<!-- tmt-rules:start -->`~`<!-- tmt-rules:end -->` 마커를 그대로 유지하고, 프로젝트 고유 지침은 마커 밖에 둔다. `AGENTS.md`를 Roger 역할 파일로 쓰지 않는다.
4. 앨리스로서 `new-setup.md` 읽기

"tmt 템플릿 동기화해줘" 요청 시: 현재 harness 전역 템플릿 `project-rules.md`의 마커 블록으로 프로젝트 루트 `CLAUDE.md`·`AGENTS.md`의 마커 블록을 통째로 교체한다. 마커 밖은 건드리지 않는다. 마커가 없는 프로젝트는 템플릿 유래 절을 찾아 마커로 감싼 뒤 교체하고, 판단이 애매한 절은 목록으로 보고한다. diff를 보여주고 커밋은 소유자 승인 후.

"operator 세팅해줘" 요청 시에만 checkout의 `templates/optional/OPERATOR.md`를 프로젝트 루트에 복사한다. Oz는 선택 역할이다. 환경 좌표를 실측으로 채우기 전에는 운영 조작을 수행하지 않는다.

롤백: 이름은 ARCHITECT.md·BUILDER.md·REVIEWER.md·ROGER.md·new-setup.md에서 단어 `Alice`를 `Arch`로 워드바운더리 치환.

### 토큰 최적화 스킬 (역할별 로드)

이 표는 전역 규칙에만 둔다. 프로젝트 `CLAUDE.md`·`AGENTS.md`에 복사하지 않는다 — 표가 바뀌면 build 재실행만으로 모든 프로젝트에 적용된다. 프로젝트 지침에 옛 Token Optimization 절이 남아 있으면 이 표가 우선한다.

caveman·Ponytail은 머신 기본 off (`~/.config/caveman/config.json`·`~/.config/ponytail/config.json`의 `defaultMode: off`). 역할 없는 세션은 둘 다 미적용. 역할 세션은 Session Start에서, 역할 작업 전에 아래 표대로 스킬을 로드한다. 스킬이 없으면 건너뛴다.

| 역할 | caveman | Ponytail |
|---|---|---|
| 앨리스 | lite | off |
| 밥 | full | full |
| 리처드·로저 | full | off (`ponytail-review` 필요 시 로드) |
| Oz | lite | off |

모드는 스킬 로드로만 맞춘다 (`/caveman`·`/ponytail` 명령으로 전환하지 않는다). 사용자가 직접 명령을 쓰는 건 자유지만, 모드 플래그가 머신 전역이라 동시에 떠 있는 다른 세션에도 적용된다.

caveman은 응답을 줄이고 Ponytail은 필요한 구현만 남긴다. 필수 검증·보안·접근성·오류 처리는 줄이지 않는다.

**사용자가 세팅 시 특정 옵티마이저 지정한 경우:**
그 프로젝트에 한해 루트 CLAUDE.md·AGENTS.md와 역할 파일의 `## Session Start` 섹션에 해당 스킬 로드 지시를 같은 의미로 추가한다 (이 표보다 우선).
