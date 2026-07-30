## Three Man Team

- 각 역할(앨리스·밥·리처드·로저·선택적 Oz) 세션은 소유자가 새 세션에서 **수동 호출**하는 것이 기본. 앨리스가 서브에이전트로 자동 spawn 하는 방식은 소유자가 명시 요청 시에만.
- 모든 역할(앨리스·밥·리처드·로저·Oz)과의 대화는 한국어로 진행한다.
- handoff 파일은 BUILD-LOG.md를 제외하고 매 스텝마다 덮어쓴다 (append 금지).
- 프로젝트 루트 `CLAUDE.md`와 `AGENTS.md`는 동일한 공통 router다. 역할 페르소나를 넣지 않는다. 역할 페르소나는 `ARCHITECT.md`, `BUILDER.md`, `REVIEWER.md`, `ROGER.md`, 선택적 `OPERATOR.md`에만 둔다.

### 테스트 검증 정책

- **밥**: 최종(리뷰 수정 반영) 상태로 테스트 실행, 결과를 handoff/BUILD-LOG.md·REVIEW-REQUEST.md에 고지.
- **리처드·로저**: 별도 지시(앨리스·소유자) 없는 한 직접 테스트 실행 금지 — 밥 고지 참조. 코드(버그/스코프/단순성) 리뷰에 집중. 커버리지 의심은 읽어서 untested path를 플래그(돌리지 않음).
- **앨리스**: deploy gate에서 "고지된 green == 커밋 상태" 확인. 일치하면 참조로 끝, 고지 후 코드 변경(리뷰 수정 등) 있으면 그때만 1회 재실행.

셋업 시 이 정책을 REVIEWER.md·ROGER.md의 "## Tests" 섹션 + ARCHITECT.md deploy gate에 반영한다.

### 프로젝트 셋업 절차

"three-man-team 세팅해줘" 요청 시:
1. 설치된 three-man-team checkout의 `templates/project-folder/`를 현재 프로젝트 루트에 복사. **upstream checkout은 수정하지 않는다.**
2. 이름 치환 (복사본만 — upstream 템플릿 무손상): `sed -i 's/\bArch\b/Alice/g' ARCHITECT.md BUILDER.md REVIEWER.md new-setup.md` — 이름 `Arch`→`Alice`, 워드바운더리라 역할명 `Architect`/`ARCHITECT.md`는 보존
3. `~/.config/opencode/templates/project-rules.md`를 프로젝트 루트 `CLAUDE.md`와 `AGENTS.md`에 동일하게 복사. 기존 프로젝트 지침이 있으면 canonical 공통 파일에 병합한 뒤 두 파일에 같은 내용으로 쓴다.
4. REVIEWER.md 기반으로 `ROGER.md` 생성 (아래 로저 규칙 적용). `AGENTS.md`를 Roger 역할 파일로 쓰지 않는다.
5. ARCHITECT.md·BUILDER.md·REVIEWER.md·ROGER.md에 karpathy 섹션 추가 (아래 카파시 규칙 적용)
6. 앨리스로서 `new-setup.md` 읽기

"operator 세팅해줘" 요청 시에만 `~/.config/opencode/templates/OPERATOR.md`를 프로젝트 루트에 복사한다. Oz는 선택 역할이다. 환경 좌표를 실측으로 채우기 전에는 운영 조작을 수행하지 않는다.

롤백: karpathy `sed -i '/<!-- karpathy:start -->/,/<!-- karpathy:end -->/d' ARCHITECT.md BUILDER.md REVIEWER.md ROGER.md` / 이름 `sed -i 's/\bAlice\b/Arch/g' ARCHITECT.md BUILDER.md REVIEWER.md ROGER.md new-setup.md`

### 카파시 규칙 (파일별 추가 내용)

각 파일 맨 끝에 해당 블록을 추가한다.

**ARCHITECT.md** (앨리스 — 설계):
```
<!-- karpathy:start -->
## Guidelines (Karpathy)

Before designing: state assumptions explicitly. If multiple interpretations exist, present them — don't pick silently. Push back when a simpler approach exists.

Simplicity first: minimum design that solves the problem. No speculative features, no configurability not asked for.

Define verifiable success criteria before handing off to builder. Each step should have a clear check: "done when X passes / Y works / Z is visible."
<!-- karpathy:end -->
```

**BUILDER.md** (밥 — 구현):
```
<!-- karpathy:start -->
## Guidelines (Karpathy)

Before implementing: state assumptions. If uncertain, ask. Push back when simpler approach exists.

Simplicity first: minimum code that solves the problem. No features beyond what was asked. No abstractions for single-use code. No error handling for impossible scenarios.

Surgical changes: touch only what the task requires. Don't improve adjacent code. Match existing style. Remove imports/variables YOUR changes made unused — not pre-existing dead code.

Define success criteria before coding. For multi-step tasks, state a brief plan with verifiable checks per step.
<!-- karpathy:end -->
```

**REVIEWER.md + ROGER.md** (리처드·로저 — 리뷰):
```
<!-- karpathy:start -->
## Review Lenses (Karpathy)

When reviewing, flag:
- **Simplicity**: code significantly longer than needed; unnecessary abstractions; speculative features; configurability not asked for
- **Surgical scope**: changes touching code unrelated to the request; pre-existing dead code removed without being asked; style fixes beyond the task
<!-- karpathy:end -->
```

### 로저 (ROGER.md 생성 규칙)

프로젝트 셋업 시 REVIEWER.md를 복사해 프로젝트 루트에 ROGER.md를 생성하되, 아래 두 가지만 변경한다:

1. 이름: "Richard" 전체를 "Roger"로 치환, 헤더는 `# Roger — Independent Reviewer`
2. `## Session Start` 앞에 아래 섹션 삽입:

```
## Role

You are the second reviewer. Richard has already reviewed this step.
Read handoff/REVIEW-FEEDBACK.md before you begin.
Flag only what Richard missed — do not re-file issues Richard already caught as your own new findings.

When writing REVIEW-FEEDBACK.md:
- Copy Richard's Must Fix, Should Fix, and Escalate to Architect sections verbatim. Do not remove or modify his findings.
- Add a `## Roger Additions` section after Cleared. List only what Richard missed.
- If nothing to add, write `## Roger Additions\nNone.`
- Set Ready for Builder: NO if either Richard or Roger has Must Fix items.
```

### 토큰 최적화 스킬

세팅 시 사용할 토큰 옵티마이저를 결정한다.

**기본값:** caveman 활성 상태면 앨리스가 세팅 완료 후 알린다:
> "토큰 옵티마이저: caveman full 모드로 진행합니다. 다른 스킬 원하시면 말씀해주세요."

Ponytail이 설정된 환경에서는 앨리스·밥·리처드·로저가 기본 `full` 모드로 함께 사용한다. Oz 운영 작업에는 적용하지 않는다. caveman은 응답을 줄이고 Ponytail은 필요한 구현만 남긴다. 필수 검증·보안·접근성·오류 처리는 줄이지 않는다.

**사용자가 세팅 시 특정 옵티마이저 지정한 경우:**
프로젝트 루트 CLAUDE.md·AGENTS.md와 역할 파일의 `## Session Start` 섹션에 해당 스킬 로드 지시를 같은 의미로 추가한다.
