## Three Man Team

- 각 역할(앨리스·밥·리처드·로저·선택적 Oz) 세션은 소유자가 새 세션에서 **수동 호출**하는 것이 기본. 앨리스가 외부 CLI 오케스트레이터(tmt-cli)로 역할을 호출하는 방식은 소유자가 명시 요청 시에만. 서브에이전트(Agent tool)로 역할을 띄우지 않는다.
- 모든 역할(앨리스·밥·리처드·로저·Oz)과 소유자의 대화는 한국어로 진행한다. 역할 간 산출물(handoff 파일·역할 프롬프트·결과 JSON)은 영어로 쓰고, 앨리스가 소유자에게 보고할 때 한국어로 요약한다.
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
- 역할 자동 호출(spawn·CLI) 금지를 유지한다. 읽기 전용 조사 위임(scout 등)은 허용한다.

### 프로젝트 셋업 절차

three-man-team checkout(`~/.claude/skills/three-man-team`, 계정 분리면 `$CLAUDE_CONFIG_DIR/skills/three-man-team`)은 개인 포크(`dreamwayjgs/three-man-team`, `origin`)이고 원본은 `upstream`이다. 로저·Oz·karpathy 블록·테스트 정책·리뷰어 규칙은 포크 템플릿에 들어 있다. 프로젝트 셋업 중에는 checkout을 수정하지 않는다.

"three-man-team 세팅해줘" 요청 시:
1. checkout의 `templates/project-folder/`를 현재 프로젝트 루트에 복사.
2. 이름 치환 (복사본만): `ARCHITECT.md`·`BUILDER.md`·`REVIEWER.md`·`ROGER.md`·`new-setup.md`에서 단어 `Arch`를 `Alice`로 대소문자 구분·워드바운더리 치환한다. 역할명 `Architect`/`ARCHITECT.md`는 보존. 현재 셸에 맞는 도구(pwsh 7 `-creplace '\bArch\b'`, bash `sed` 등)나 편집 도구를 쓴다. Windows는 pwsh 7만 지원한다.
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
| 앨리스 | caveman | off |
| 밥 | caveman | full |
| 리처드·로저 | caveman | off (`ponytail-review` 필요 시 로드) |
| Oz | caveman | off |

caveman v3부터 강도 레벨(lite·full·ultra)이 없고 `caveman`·`ultracave`·`megacave` 세 스킬이다. 역할 세션은 `caveman` 하나만 로드한다. 모드는 스킬 로드로만 맞춘다 (`/caveman`·`/ponytail` 명령으로 전환하지 않는다). 사용자가 직접 명령을 쓰는 건 자유지만, Ponytail 플래그와 OpenCode 어댑터의 caveman 플래그는 머신 전역이라 동시에 떠 있는 다른 세션에도 적용된다 (Claude Code의 caveman v3만 세션별 상태).

스킬 경로를 적을 땐 `~/.agents/skills/<name>/SKILL.md`를 쓴다 (build가 유지, omp·Crush·OpenCode v2 기본 스캔). 이름으로 못 찾으면 `~/.agents/skills/` → `~/.claude/skills/` → `~/.config/opencode/skills/` → `~/.claude/plugins/cache/<plugin>/*/skills/<name>/` 순으로 직접 읽고, 찾은 경로를 세션 보고에 한 줄로 남긴다. Ponytail은 `DietrichGebert/ponytail`, Karpathy는 `multica-ai/andrej-karpathy-skills` 정본에서 가져온 스킬이다. tmt-cli 워커(`~/.claude-worker`)도 같은 파일 경로로 읽으므로 워커 디렉터리에 플러그인은 필요 없다.

caveman은 응답을 줄이고 Ponytail은 필요한 구현만 남긴다. 필수 검증·보안·접근성·오류 처리는 줄이지 않는다. Karpathy는 역할 파일의 karpathy 블록으로 적용되며 별도 스킬 로드는 하지 않는다.

**사용자가 세팅 시 특정 옵티마이저 지정한 경우:**
그 프로젝트에 한해 루트 CLAUDE.md·AGENTS.md와 역할 파일의 `## Session Start` 섹션에 해당 스킬 로드 지시를 같은 의미로 추가한다 (이 표보다 우선).

### tmt-cli 턴 호출 (앨리스 전용)

- 위 역할 호출 규칙에 따라 **소유자가 명시 승인한 역할·스텝 범위**에서만 호출한다. 스텝 작업 승인이나 CLI 프로토콜 적용만으로 역할 호출 권한이 추가되지 않는다.
- 턴 프롬프트는 위 영어 역할 산출물 규칙을 따르며, **스코프·작업 repo·handoff 경로·브랜치·검토 대상(스텝·파일)**을 명확히 전달한다. 역할 정책의 전체 diff 재검토를 좁히는 지시는 넣지 않는다.
- 이번 턴의 작업·변경점·기대 산출물을 간결히 전달한다. 고정 프로토콜의 중복 설명은 줄이되 필요한 역할 지침을 생략하지 않는다.
- 리뷰 범위·독립 검증·중복 발견 보고 기준은 역할 정책, 테스트는 위 테스트 검증 정책을 따른다. 호출 방식이나 비용 최적화를 이유로 바꾸지 않는다.
- 턴 후 **호출 전후 변경이 허용 범위 안인지**와 기대 산출물을 확인한다. 로저의 피드백 작성은 역할 정책의 기존 발견 원문 보존 규칙을 따른다.
- claude 어댑터 호출은 `~/.claude-worker`가 있으면 호출 단위로 `CLAUDE_CONFIG_DIR`을 붙이고, 한 세션의 모든 호출(새 세션·재개·export)에 같은 값을 쓴다. 앨리스 자기 세션에는 적용하지 않는다.
- 세션 운용·ID 조회·결과 계약·adapter별 관측 방법은 프로젝트의 `tmt-cli` 프로토콜과 CLI 문서를 따른다. 결과의 업무상 적합성 판단은 앨리스가 맡는다.
