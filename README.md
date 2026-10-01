# claude-settings-example

> **Public repo.** 사내 정책상 Internal 가시성 사용 불가해 Public으로 둠. 시크릿·고객사 정보 없음(확인 완료) — 그래도 fragment 추가할 때마다 커밋 전에 한 번 더 훑어볼 것.

개인 Claude Code·OpenCode·omp·Crush 세팅(WSL2, gsjung)의 source of truth. 네 harness가 같은 규칙·스킬·Three Man Team 맥락을 쓰도록 맞춘다. 다른 머신에 옮기거나 급하게 복붙할 때 여기서 가져온다.

**전제:** caveman·three-man-team 설치(각 repo의 기본 설치법)는 새 머신에서 직접 수행. 이 repo는 설치 이후의 설정만 다룬다.

**Foreman 제외:** 이 repo는 설정 export용 — 주간 원장 보고 대상 아님. `foreman register`/`update`/`guide` 돌리지 말 것.

## 구조

| 경로 | 용도 |
|---|---|
| `fragments/00-core.md` | 공통 global router 앞부분 — arguing 규칙, 개발 세션. 자주 바뀜 |
| `fragments/05-foreman.md` | 선택적 Foreman 전역 규칙. 최초 빌드에서 포함 여부 결정 |
| `fragments/10-three-man-team.md` | `CLAUDE.md`의 Three Man Team 전체 블록. 안정적, 거의 안 바뀜 |
| `fragments/90-activation.md` | omp·Crush 전용 블록 — caveman·Ponytail 기본 off, 역할 표로 위임. build가 두 harness 규칙 끝에 붙임 |
| `build-claude-md.sh` | fragments를 이어붙여 네 harness global rules에 씀 + Claude 플러그인 스킬을 `~/.agents/skills/`로 복사 |
| `build-rules.ps1` | `pwsh` 7용 동일 생성기 (Windows PowerShell 5 미지원). UTF-8 without BOM 출력 |
| `opencode.json.example` | OpenCode V1 global config 참고본. Ponytail npm plugin. 실제 파일명은 `opencode.json`/`opencode.jsonc` |
| `opencode.v2.json.example` | OpenCode V2 global config 참고본. 로컬 플러그인 폴더(`./plugins/caveman`, `./plugins/ponytail`) 지정 |
| `opencode-plugins/ponytail-v2/` | ponytail OpenCode V2 임시 패치 (upstream V2 지원까지만 유지, 철수 조건은 내부 README). `index.js` + 설치·확인 절차 |
| `opencode-v2-migration.md` | OpenCode V1→V2 전환 절차·머신별 상태·RAM 실측 |
| `claude-settings.md` | 다른 머신에 옮길 때 참고 가이드 |
| `settings.json.example` | `~/.claude/settings.json` 참고본 (플레이스홀더 포함) |
| `statusline.sh` / `statusline.ps1` | 상태줄 스크립트 |
| `omp/hooks/pre/openai-personal-warning.ts` | 머신 선택 참고본 (build 대상 아님). omp에서 OpenAI 계열 모델 첫 요청 시 "개인 작업이 맞나요?" Y/N 확인 — 아니오는 취소 후 재질문, 화면 없는 실행(`-p`)은 취소. 개인 OpenAI 로그인을 쓰는 머신만 `~/.omp/agent/hooks/pre/`로 복사 |
| `templates/` | harness와 무관한 프로젝트 bootstrap 템플릿 |
| `templates/project-rules.md` | 프로젝트 `CLAUDE.md`·`AGENTS.md` 공통 router 템플릿 |
| `templates/.claudeignore` | 프로젝트용 ignore 템플릿 (deps/build/secrets 등). build가 네 harness의 `templates/`에 배치 → "저장된 .claudeignore 적용해줘" 시 거기서 프로젝트 루트로 복사 (`fragments/00-core.md` 참조) |
| `prompts/` | 필요할 때 다른 모델에 붙여 넣는 일회성 프롬프트. 빌드 대상 아님 (`translation-review.md`: 번역 교차검증 · `tmt-machine-migrate.md`: 머신별 tmt 포크 전환 · `tmt-project-sync.md`: 기존 프로젝트 역할 파일 동기화) |
| `three-man-team-model-allocation.md` | 역할별 모델 기준·등급 시나리오·판정 원칙·리처드 벤더 실험 (모델명 미고정) |

## 사용법

**global rules 고칠 때:** 생성된 `CLAUDE.md`·`AGENTS.md`를 직접 고치지 않는다. `fragments/*.md`를 고치고 `./build-claude-md.sh` 실행 — `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md`, `~/.config/opencode/AGENTS.md`에 동일하게, `~/.omp/agent/AGENTS.md`, `~/.config/crush/CRUSH.md`에는 같은 내용 + 활성화 블록(세션 시작 hook이 없어서)으로 반영된다. `project-rules.md`·`.claudeignore`는 네 harness의 template 경로(`~/.claude/templates/`, `~/.config/opencode/templates/`, `~/.omp/agent/templates/`, `~/.config/crush/templates/`)에 복사된다. Claude 플러그인(caveman·ponytail·karpathy·qmd) 스킬은 `~/.agents/skills/`로 복사된다 — omp·Crush가 기본으로 읽는 경로. 플러그인 업데이트 후 build 재실행. 최초 실행은 Foreman 포함 여부를 묻고 선택을 `.claude-settings.local`에 저장한다. 선택을 바꾸려면 이 파일의 값을 수정하거나 파일을 삭제하고 다시 실행한다.

**다른 머신에 세팅할 때:** `claude-settings.md` 참고. 설치 여부(caveman/three-man-team)는 파일 존재로 확인하고, 없으면 임의 설치하지 말고 사용자에게 확인.
