# 하네스 비교 — Three Man Team 관점

작성일: 2026-09-29, 갱신: 2026-10-13. 대상 프로젝트: oasis-mmm (v2 엔진 / v3 라이브) — 역할 배치 중 프로젝트 정책(예: 로저=Codex)은 이 프로젝트 한정이며 전역 템플릿 규칙이 아니다. omp 는 실제 세션에서 실측.

**범위 확장 (2026-09-29):** 기존 본문은 **Claude를 호출하는 하네스** 조사로 보존한다. 뒤에 **GPT × Codex·OpenCode·omp·Crush** 비교를 추가했다. 바로 아래 결론은 Claude 조사에만 해당한다. GPT 비교는 [GPT 하네스 비교](#gpt-하네스-비교) 참조.

## 결론

**권장안 (2026-09-30):** omp = 앨리스·밥, Claude Code = 나머지 (리처드·로저·Oz). 리처드는 무차별이지만 Claude Code로 두면 omp 테스트 압력 봉합((a) 줄)이 필요 없다. 로저가 프로젝트 정책으로 고정된 경우(oasis-mmm v3 = Codex)는 그 정책이 우선.

세부 근거:

- **앨리스·밥 → omp 유리**
- **오즈 → Claude Code 유리** (권한 하드 게이트 하나 때문. omp도 `--approval-mode`·`--tools`는 있으나 fail-closed 미검증 — [GPT 절 보충](#네-하네스의-차이) 참조)
- **리처드 → 무차별**, 단 omp 하네스 프롬프트가 역할 규칙과 충돌
- **로저(v3) = Codex 고정** (oasis-mmm 프로젝트 정책) → 무관
- omp 로 옮기려면 역할 파일에 **3줄 추가 선행** (아래 "구조적 마찰")

## 실측 차이 — omp vs Claude Code

| 영역 | omp (관측) | Claude Code | 영향 |
|---|---|---|---|
| 편집 | `edit` = 해시라인 앵커(스냅샷 태그 필수, stale 편집 거부) + `xd://ast_edit` | 문자열 치환 Edit | 밥 ↑ omp — 리뷰 픽스 반복 시 stale-edit 사고 차단 |
| 코드 인텔리전스 | `xd://lsp`(정의·참조·hover), `xd://debug`(DAP) | LSP 플러그인, DAP 없음 | 밥·리처드 ↑ omp — `allocation.py`·`analysis.py` 변경 시 parity 참조 추적 |
| 읽기 | `read` 라인범위·SQLite·아카이브·PDF·URL·이미지·video 프레임 | Read 파일/이미지, WebFetch | 앨리스·오즈 ↑ omp |
| 실행 | `eval` 영속 Python/Bun 커널(컴팩션 넘어 상태 유지), `browser` 내장 Chromium, `proc://` 서비스 ready-gate | Bash만, 브라우저는 Playwright MCP/Chrome 확장 별도 | 프론트 검증 ↑ omp |
| 서브에이전트 | `task` scout/reviewer/security-reviewer/sonic, `outputSchema`, `agent://` 메시징 | Agent 툴 + `model:` 파라미터 | `ARCHITECT.md` 의 `model:` 지정은 Claude Code 전용 |
| 원격 | `ssh://host/path` read/grep | bash ssh | 오즈 조사 ↑ omp |
| 권한 게이트 | "확인 묻지 말고 행동" 편향, 파괴적 명령만 ask | `settings.local.json` allow/deny + 도구별 승인 | 오즈 집행 ↑ **Claude Code** |
| 스킬 | `~/.agents/skills` 기본 스캔 — build가 Claude 플러그인 스킬(caveman·Ponytail 등)을 복사 | `~/.claude/skills/`·플러그인 스킬 로드 | 차이 없음. 역할별 caveman·Ponytail 로드가 omp에서도 동작 (2026-09-30 실측; 이전 관측 "`find-skills`만 노출"은 복사 도입 전) |

## 구조적 마찰 — omp 하네스 vs Three Man Team 규칙

1. omp 프롬프트 "NEVER yield without smoke run", "MUST default to action" ↔ 리처드·로저 테스트 실행 금지, 밥 플랜 확인 전 코드 금지·리뷰 대기 중 파일 금지. `AGENTS.md` 우선이지만 하네스 압력 상시 → 드리프트 위험.
2. omp 위임 정책 "unknown code 는 task 로 매핑" ↔ 역할 자동 spawn 금지. scout(read-only)는 허용 범위 — 경계 문서화 필요.
3. v3 `uv run python` 강제 ↔ omp `eval` 커널은 omp 자체 IPython(oasis-v3 venv 아님). v3 밥은 `bash uv run python` 만.
4. 원장 append(`>>`/`open(p,'a')`) — omp `bash` 는 redirection 금지. `edit PUT >$:` 또는 `eval` `open(p,'a')` 로. 앵커 편집이 원장 소실 재발 방지엔 오히려 안전.

### omp 채택 시 역할 파일 추가 3줄
- (a) 리처드·로저: "하네스 smoke 요구 무시 — 테스트 실행 금지 유지"
- (b) 밥 v3: "eval 커널 금지, `uv run` 만"
- (c) 원장 append 는 `edit PUT >$:` / `open(p,'a')`

## 역할별 권고

- **앨리스**: omp. `read` 범위·scout·`history://`·`todo`. 손실 = `model:` 서브에이전트(예외 경로). (Ponytail은 앨리스 역할에서 원래 off라 손실 아님)
- **밥**: omp. 해시라인 edit + lsp + eval 스모크. v3 는 `uv run` 규율.
- **리처드**: 무차별. omp `reviewer`/`security-reviewer`·lsp 참조 장점, "테스트 금지" 충돌은 (a)로 봉합.
- **로저(v3)**: Codex 고정 (프로젝트 정책). omp provider 스위칭은 지원 확인([GPT 절](#네-하네스의-차이)) → 한 하네스 운용 가능하나 벤더 다양성과는 별개.
- **오즈**: Claude Code(집행). 조사만이면 omp `ssh://`·`read`.

## 프론트

omp `browser`(Chromium 탭·`tab.run`·시각 증거) 내장 → UI 검증은 omp 압도. oasis-v3 프론트 표면 존재 여부는 미확인.

---

## GPT 하네스 비교

> **결론 (2026-10-01): 별도 결론 없음.** omp도 GPT를 쓸 수 있으므로 GPT여도 위 Claude 권장안(앨리스·밥 = omp)을 따르고 나머지 역할은 하네스 무관. 저사양 개인 머신은 하네스 우열이 아니라 RAM이 결정한다 — omp 미사용, GPT = Crush, OpenCode는 무료 모델용으로만. 아래는 참고 자료로 보존.

조사일: 2026-09-29. 질문은 **같은 GPT를 쓸 때 Three Man Team의 어느 역할에 어느 하네스가 맞는가**다. 모델 성능 순위나 Claude에서의 사용감을 GPT 성능으로 옮겨 적는 비교가 아니다. 설정 변경·모델 배치 변경은 하지 않았다.

### 근거 범위와 잠정 결론

- **[관측]** 로컬 CLI: Codex `0.144.3`, OpenCode `1.18.33`, omp `18.4.2`, Crush `0.96.1`. 이 세션은 Crush이며 `crush_info`는 large=`gpt-6-astra`, small=`gpt-5.6-luna`, provider=`openai`로 보고했다. 이는 런타임 설정 표시이며 실제 모든 요청의 모델·과금 경로를 검증한 것은 아니다.
- **[문서]** 각 공식 문서와 설치 패키지 README, 로컬 `--help`. 온라인 문서는 이동하므로 설치 버전의 모든 기능·기본값과 같다고 가정하지 않는다.
- **[추론]** 아래 역할 추천은 도구·권한·역할 규칙의 적합성에 대한 잠정 판정이다. **네 하네스에서 동일 GPT로 구현/리뷰를 완주한 대조 실험은 아직 없다.**
- **잠정 요약:** GPT 구현의 기준선은 **Codex**, 역할별 권한·모델 운용을 한 도구로 정리하려면 **OpenCode**, 도구가 많은 구현 환경 후보는 **omp**, 가벼운 수동 리뷰 세션 후보는 **Crush**. 단 Crush 기본 행동 지침은 리뷰 역할과 충돌하므로 그대로 채택하지 않는다.

[모델 배치](three-man-team-model-allocation.md)는 등급·벤더 기준만 다루고 하네스는 정하지 않는다. 여기서는 **GPT를 그 역할에 배치한다면**을 비교하며 기존 배치를 덮어쓰지 않는다. v3의 로저=Codex 고정도 프로젝트 정책이지 GPT 전체에 대한 하네스 우승 판정은 아니다.

### Three Man Team에서 중요한 비교축

| 역할 | 하네스가 도와야 할 일 | 도구가 많아도 감점하는 것 |
|---|---|---|
| 앨리스 | 요구 명확화, 설계·handoff, 승인 대기, 문맥 유지 | 질문 회피, 설계 중 구현 착수, 역할 자동 spawn |
| 밥 | 승인된 스텝만 구현, 탐색→편집→테스트→리뷰 수정 완주 | 플랜 승인 전 편집, 리뷰 대기 중 작업, 재작업 증가 |
| 리처드 | 누락 탐지, 참조 추적, 근거 있는 첫 리뷰 | 테스트 자동 실행, 제품 코드 수정, 불필요한 탐색 지연 |
| 로저 | 리처드 발견 보존, 추가 발견만 기록, 짧은 직렬 지연 | 기존 발견 재신고·삭제, 동일 벤더를 독립성으로 오인 |
| Oz | 조사와 집행 분리, 승인·범위 제한·감사 | 프롬프트상의 금지를 실제 권한 통제로 오인 |

공통 전제: 역할은 소유자가 **각각 새 세션에서 수동 호출**한다. read-only scout 위임과 앨리스가 밥·리뷰어를 자동 기동하는 것은 다르다. 리뷰어의 제품 코드 쓰기·테스트는 금지하지만, 지정된 리뷰 handoff 작성은 필요하다. 따라서 단순히 모든 쓰기를 막는 것으로 역할 설정이 끝나지는 않는다.

### 네 하네스의 차이

| 축 | Codex CLI | OpenCode | omp | Crush |
|---|---|---|---|---|
| GPT 연결 | ChatGPT 로그인 또는 API key [문서] | OpenAI 구독 로그인/API key, 별도 Zen 경로 [문서] | OpenAI·OpenAI Codex OAuth, provider/model 선택 [문서·CLI] | API key [문서], `crush login openai`로 ChatGPT 계정 인증 [CLI] |
| 수동 역할 운용 | 별도 세션·profile, resume/fork [CLI] | custom primary agent와 `--agent`, 역할별 권한 [문서·CLI] | profile·system prompt·도구 선택·resume [CLI] | 별도 세션·resume, 역할 파일 명시 로드; 전용 역할 preset은 이번 조사에서 미확인 |
| 구현 도구 | 로컬 구현·실행의 기준선; LSP·해시라인 우열은 이번 조사에서 미검증 | Build는 편집·bash 사용 가능; Plan과 역할별 권한 분리 [문서] | 해시라인 stale 거부, LSP, 영속 실행·브라우저 [문서·기존 관측] | 문자열 편집 + LSP 정의/참조/호출관계/rename/심볼 교체가 이 세션에 노출 [관측] |
| 조사 위임 | 이 비교에서는 별도 역할 세션을 기준으로 평가 | custom subagent·Task, 호출 권한 제한 가능 [문서] | scout/reviewer 등 task, 도구 선택 가능 [문서·CLI] | 현재 `agent`는 glob/grep/ls/view만 가진 읽기 전용 조사자 [관측] |
| 권한 경계 | sandbox와 approval이 별도 옵션 [CLI] | 도구·명령 패턴 allow/ask/deny [문서]; 이것만으로 OS 격리 판정 불가 | `--approval-mode` always-ask/write/yolo, `--tools` [CLI]; OS 격리 범위는 미검증 | 도구별 승인·숨김, yolo [문서·CLI]; OS 격리 보장은 미검증 |
| 지침 이식 | AGENTS.md·skills [문서]; Claude 훅 호환은 별도 검증 | AGENTS.md 우선, CLAUDE.md fallback [문서] | AGENTS.md·CLAUDE.md context, skills 탐색 [설치 문서·CLI] | 현재 CLAUDE.md와 skills 목록 주입 확인; Claude 훅의 동일 동작은 미검증 |

**구독 로그인 지원 ≠ 같은 모델·추론 설정·한도·과금.** Crush의 현재 인증 경로는 비밀 설정을 열어 확인하지 않았다. OpenCode Zen은 하네스가 아니라 선택 가능한 게이트웨이다. 어느 하네스가 싸다고 판정하려면 주 모델뿐 아니라 small/task 모델·검색 fallback의 실제 사용량도 함께 봐야 한다.

**앞 Claude 조사에 대한 보충:** 당시 “omp provider 스위칭 미확인”은 이번 README·CLI 조사에서 지원 확인으로 갱신한다. 또한 설치된 omp는 승인 모드와 도구 제한 옵션을 노출한다. 따라서 “권한 하드 게이트가 Claude Code에만 있다”는 표현을 네 하네스 전체로 확대할 수 없다. 옵션 존재와 실제 명령·원격 집행에 대한 fail-closed 검증은 별개다. 기존 세션 관측은 그대로 보존한다.

### Crush: 가벼움 외에 확인된 장단점

**장점**

1. **가벼운 UI라고 도구까지 빈약한 것은 아니다.** 이 세션에는 LSP 정의·참조·호출 계층·rename·심볼 교체, 웹 fetch, 백그라운드 작업 관리가 노출된다. 언어 서버가 붙은 프로젝트에서는 밥의 수정과 리뷰어의 참조 추적에 유리할 후보이다. 이 Markdown repo에서 LSP의 실제 정확도는 시험하지 않았다.
2. **읽기 전용 조사 위임은 역할 분리와 맞는다.** 현재 `agent`는 조사용 4개 도구로 제한되어 있어 scout에 적합하다. 이것을 밥·로저를 실행하는 범용 오케스트레이터로 간주하면 안 된다.
3. **역할 파일 중심의 수동 운용과 잘 맞는 후보이다.** 세션 이어가기와 스킬 발견을 지원한다. 현재 프로젝트 `CLAUDE.md`와 사용자 스킬 목록이 보이므로 “Claude 자산을 전혀 못 읽는다”는 가정은 틀리다. 다만 목록 노출은 스킬 실행·훅 호환 검증과 다르다.

**가장 큰 약점 후보는 기능 수가 아니라 기본 행동 지침이다.** 현재 모델에 전달된 하네스 지침에서 관측했다. Crush 모든 버전·설정의 불변 특성으로 일반화하지 않는다.

| 현재 세션 지침 | Three Man Team과의 마찰 |
|---|---|
| `Don't ask questions`, `BE AUTONOMOUS`, 완료할 때까지 계속 실행 | 앨리스의 요구 확인, 밥의 플랜 승인·리뷰 대기와 충돌 가능 |
| `Run tests immediately after each modification` | 리처드·로저가 피드백 문서만 고쳐도 테스트 실행 압력이 생김 |
| 하네스 지침이 우선 적용되는 구조 | 역할 파일에 “테스트 금지” 한 줄을 더해도 상위 지침과의 충돌 해소를 보장하지 못함 |
| 기본 응답 4줄 미만, 설명 최소화 | 간단한 인계에는 유리하나 설계 근거·리뷰 증거를 생략하지 않는지 확인 필요 |

따라서 **Crush는 가벼운 리뷰 전용 후보이지만, 기본 설정 그대로의 리뷰 전용 도구는 아니다.** 리뷰 프로필의 실행 도구 제한과 지정 handoff만 쓰는 경계를 검증해야 한다. 읽기 전용 탐색이 필요하므로 bash를 무조건 없애는 대신 git diff 등 필요한 조회 경로도 확보해야 한다. `edit`만 막고 LSP rename·심볼 교체·shell·MCP를 남겨두면 쓰기 금지가 아니다.

소유자의 “가볍다”는 평가는 **사용감 관측**으로 기록한다. 시작시간·RSS·입력 지연·프롬프트 토큰·리뷰 완료시간은 측정하지 않았다. 터미널 UI가 가벼운 것과 모델에게 전달되는 도구/지침이 적은 것, 실제 응답이 빠른 것은 서로 다른 주장이다.

### 역할별 잠정 선택

| 역할 | 우선 검토 | 이유와 채택 조건 |
|---|---|---|
| 앨리스(GPT 가정) | **OpenCode** | custom primary로 설계/승인/도구 경계를 분리하기 용이. Plan 기본값은 edit·bash `ask`이므로 무조건 실행 불가 모드는 아님. 기존 Claude 스킬·훅 이식 비용을 먼저 확인 |
| 밥 | **Codex 기준선**, omp 도전자 | 공식 GPT CLI를 대조군으로 두고, omp 해시라인·LSP가 실제 편집 실패·재작업을 줄이는지 평가. Codex가 더 똑똑하다는 판정이 아님. Crush도 구현에 필요한 도구는 있으나 완주 실측 전 우열 보류 |
| 리처드 | **Codex 또는 OpenCode의 제한된 리뷰 세션** | 기존 검증 모델 유지가 우선. Codex는 sandbox 경계, OpenCode는 역할별 도구 정책이 선택 근거. 하네스만 바꿔도 recall 유지 검증은 필요 |
| 로저 | **Crush 시험 후보**, 실패 시 기존 Codex 유지 | 리처드가 Claude 등 다른 벤더일 때 GPT 로저로 시험. 작은 수동 세션과 탐색 도구가 맞지만, 테스트 금지·원문 보존·추가 발견·지연 통과가 선행 |
| Oz(GPT 가정) | **Codex 우선 검증** | sandbox + approval을 분리해 집행 경계를 명시할 수 있음. 다른 하네스는 승인/deny만으로 동등한 격리를 가정하지 않음. 어떤 로컬 sandbox도 승인된 원격 명령의 대상 시스템 권한까지 자동 제한하지 않음 |

**리처드가 이미 GPT라면 GPT 로저를 하네스만 바꿔 붙이지 않는다.** Codex→Crush 또는 OpenCode→omp는 하네스 다양성이지 벤더 다양성이 아니다. 하네스 A/B는 가능하지만 로저의 독립 리뷰 요건을 충족했다는 뜻은 아니다. 위 추천은 이 저장소의 모델 배치 변경 지시가 아니다.

### 채택 전 확인할 경계와 최소 대조 실험

1. **역할별 실행 경계:** “테스트 금지”와 “파일 read-only”는 다르다. read-only sandbox에서도 읽기만 하는 명령은 실행될 수 있으므로 테스트 불실행 보장으로 쓰지 않는다. 반대로 리뷰 handoff 쓰기는 허용해야 한다. shell·Python·browser·LSP 쓰기·MCP·subagent를 포함한 실행/쓰기 경로를 점검한다. 승인 모드의 이름만으로 통과시키지 않는다.
2. **동일 조건:** 같은 repo 커밋·역할 파일·handoff·GPT 모델 ID·추론 수준을 고정하고 매번 새 세션을 쓴다. 인증/게이트웨이, 도구, 캐시, compaction, 보조 모델 차이를 기록한다. 같은 모델을 네 곳에서 제공하지 않으면 해당 대조군은 제외하고 모델 차이를 하네스 차이로 계산하지 않는다.
3. **Crush 첫 시험은 로저 복제 과제:** 과거 완료 스텝의 diff와 리처드 피드백을 별도 실험 작업공간에 제공한다. 기대값은 기존 발견 원문 보존, `Roger Additions`만 추가, 제품 코드 변경 0, 테스트 실행 0. 다른 세션의 실제 피드백을 덮어쓰지 않는다. 리처드가 GPT였던 스텝은 독립 리뷰 채택 근거가 아니라 하네스 A/B 자료로만 쓴다.
4. **밥 대조:** Codex 대 omp에서 같은 승인된 작은 구현 스텝을 수행한다. 편집 실패/재읽기, 테스트 통과, 리뷰 수정 라운드, 범위 밖 변경, 최종 handoff 일치 여부를 센다. 이후 Crush·OpenCode를 같은 기준으로 추가한다.
5. **측정:** 시작시간/RSS는 UI·프로세스 비용, 첫 응답/총 완료시간은 모델·도구 포함 비용으로 분리한다. 입력·출력·추론·보조 호출 사용량, 유효 추가 발견/오탐, 승인·테스트 금지 위반을 기록한다. 빠르더라도 역할 경계 위반이 있으면 탈락이다.

이번에 수행한 것은 버전·CLI 옵션·문서·현재 세션 도구/지침 조사다. 위 구현·리뷰 대조 실험, 실제 권한 차단 시험, 원격 운영 시험은 **미실시**이며 성능 순위나 운영 안전성을 확정하지 않는다.

### GPT 비교 출처와 재현

- **역할 원본:** [공통 역할 규칙](fragments/10-three-man-team.md), [역할별 모델 선택 기준](three-man-team-model-allocation.md#역할별-기준). 리처드·로저 테스트 금지, 수동 호출, Roger Additions 보존 규칙을 기준으로 삼았다.
- **Codex:** 설치 패키지 `@openai/codex/README.md:58-66`의 ChatGPT/API 인증, `codex --help`의 sandbox·approval·profile·resume/fork. [공식 문서](https://developers.openai.com/codex).
- **OpenCode:** [Agents](https://opencode.ai/docs/agents/), [Permissions](https://opencode.ai/docs/permissions/), [Rules](https://opencode.ai/docs/rules/), [Providers](https://opencode.ai/docs/providers/), [Zen](https://opencode.ai/docs/zen/). Plan의 ask와 deny, primary와 subagent, provider와 gateway를 구분했다.
- **omp:** [공식 README](https://github.com/can1357/oh-my-pi#readme), `omp --help`; 설치 패키지 `@oh-my-pi/pi-coding-agent@18.4.2`의 `src/edit/hashline-compact.md:1-21`, `src/prompts/tools/lsp.md:5-17`, `src/prompts/system/plan-mode-active.md:3-9`, `CHANGELOG.md:1428`. plan 프롬프트만으로 OS 격리를 입증하지 않았다.
- **Crush:** [공식 저장소](https://github.com/charmbracelet/crush); 설치 패키지 `@charmland/crush/README.md:400-411`(LSP), `494-555`(hooks·세션·context), `567-590`(permissions), `602-685`(skills), `701-716`(AGENTS 초기화). ChatGPT 로그인은 README에 없지만 `crush login --help`에서 직접 확인했다. 현재 도구 스키마·하네스 지침과 `crush_info`는 별도의 세션 관측이다.

버전과 지원 옵션 재확인 명령(로그인·모델 호출·설정 변경 없음):

```sh
codex --version; opencode --version; omp --version; crush --version
codex --help; opencode --help; omp --help; crush --help
crush login --help
```

## tmt-cli 2R 기록 재검토 — 2026-10-13

**범위:** 2026-10-12의 oasis-mmm 리뷰 기록(저장소 `.tmt/runs/`)을 읽기 전용으로 재집계했다. 수동 호출과 CLI 호출의 대조 실험이 아니며, 역할·모델 배치나 리뷰 정책을 변경하는 근거로 쓰지 않는다. 집계 방법과 수치는 아래 tmt-cli 이슈에 고정했다. 4개 기록은 두 세션의 probe/export 쌍이며 모델 호출 4회가 아니다.

| 역할 / adapter | probe run | export run |
|---|---|---|
| Richard / omp | `run_20261012063930691_2c4209` | `run_20261012063936198_6f860a` |
| Roger / claude | `run_20261012064135463_906ea1` | `run_20261012064140960_70c9ef` |

### 정정한 판단

- 리처드 도구 호출 수(write 4·bash 10)는 이름 출현 횟수를 호출로 센 수치였다. `tool_execution_start` 기준 실제 호출은 36회다 ([#4](https://github.com/dreamwayjgs/tmt-cli/issues/4)).
- 824K는 단일 프롬프트 크기나 금액이 아니라 24번의 모델 호출에 걸친 cacheRead + cacheWrite 누적량이다 ([#2](https://github.com/dreamwayjgs/tmt-cli/issues/2)).
- "Claude는 파일 수준 감사만 가능"은 철회한다. 기존 export에 도구 요청·결과가 있다 ([#3](https://github.com/dreamwayjgs/tmt-cli/issues/3)).
- "29줄 증분에 824K, 전부 프롬프트 과다 때문"이라는 인과 단정은 철회한다. 근거가 있는 개선 후보는 짧은 reviewer 턴의 todo 전용 왕복 감소뿐이며 ([#5](https://github.com/dreamwayjgs/tmt-cli/issues/5)), prelude 효과와 새 세션/재개 비용 차이는 미검증 가설이다 (#2).

### 결정

- 비용 절감을 이유로 증분 전용 리뷰, 로저 재검 금지, 전역 todo 금지를 도입하지 않는다.
- 책임 경계: 전역 지침은 호출 승인과 기존 정책 준수, 역할 템플릿은 리뷰 범위·독립 검증, tmt-cli는 실행 프로토콜·관측 방법을 맡는다. 업무상 적합성 판단은 앨리스에게 남고, 원장 감사는 필요한 프로젝트가 정한다.
- 후속 비교는 같은 모델·코드·역할 지침·필수 검토 범위에서 세션·캐시 조건을 기록하고, 사용량·모델/도구 호출 수·발견 품질을 함께 본다.

CLI 구현 변경이나 비교 실험은 이번 기록 정리에 포함하지 않았다.

## tmt-cli Step I~K 교훈 — 2026-10-13

Step I~K(README 보강·todo 억제 지침·`CLAUDE_CONFIG_DIR` 지원)에서 앨리스가 CLI로 역할을 호출하며 관찰한 것. 통제 비교가 아니라 운용 기록이며, 위 "결정"의 후속 비교 조건을 대신하지 않는다. 원기록은 tmt-cli `handoff/BUILD-LOG.md`와 `ARCHITECT.md`의 워커 프롬프트 규칙.

- **omp**: `-p --mode json` 출력은 이벤트 스트림이라 파싱이 필요하고, 도구 호출 수는 `tool_execution_start` 기준으로 센다. bash 출력이 240줄에서 잘리고 모델이 artifact 조각으로 다시 읽으므로 긴 diff는 호출 수를 늘린다.
- **claude -p**: 결과 객체 하나에 비용·세션 ID·permission_denials가 들어 있어 후처리가 없다.
- **재개 턴 비용**: claude 재개 턴은 cacheRead가 턴당 420~440k로 세션 누적 컨텍스트를 매번 읽는다. Step K 밥 3턴(새 세션 $0.74 → 재개 $1.04 → $1.27, 합계 $3.05)이 omp 같은 모델 턴($0.12~0.46)보다 높았다. 같은 과제의 대조가 아니므로 방향만 참고한다.
- **워커 디렉터리**: `~/.claude-worker`로 첫 호출 컨텍스트 -27%, 쓰기·재개·export 정상, 비용 중립 (`claude-settings.md` §8 워커 절).
- **todo 억제 지침**: 짧은 리뷰어 턴에서만 todo 전용 왕복 감소가 확인됐다. 긴 구현 턴에서는 미확인.
- **리뷰어 프롬프트**: base 커밋과 handoff 제외를 포함한 diff 명령(`git diff <base> -- . ':!handoff'`)을 명시한다. 없으면 handoff diff를 리뷰 대상으로 잡거나 잘린 출력을 다시 읽는다.
