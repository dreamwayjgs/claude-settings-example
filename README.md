# claude-settings-example

> **Public repo.** 사내 정책상 Internal 가시성 사용 불가해 Public으로 둠. 시크릿·고객사 정보 없음(확인 완료) — 그래도 fragment 추가할 때마다 커밋 전에 한 번 더 훑어볼 것.

개인 Claude Code·OpenCode 세팅(WSL2, gsjung)의 source of truth. 다른 머신에 옮기거나 급하게 복붙할 때 여기서 가져온다.

**전제:** caveman·three-man-team 설치(각 repo의 기본 설치법)는 새 머신에서 직접 수행. 이 repo는 설치 이후의 설정만 다룬다.

**Foreman 제외:** 이 repo는 설정 export용 — 주간 원장 보고 대상 아님. `foreman register`/`update`/`guide` 돌리지 말 것.

## 구조

| 경로 | 용도 |
|---|---|
| `fragments/00-core.md` | 공통 global router 앞부분 — arguing 규칙, 개발 세션. 자주 바뀜 |
| `fragments/05-foreman.md` | 선택적 Foreman 전역 규칙. 최초 빌드에서 포함 여부 결정 |
| `fragments/10-three-man-team.md` | `CLAUDE.md`의 Three Man Team 전체 블록. 안정적, 거의 안 바뀜 |
| `build-claude-md.sh` | fragments를 순서대로 이어붙여 동일 내용의 Claude Code·OpenCode global rules에 씀 |
| `build-rules.ps1` | `pwsh`용 동일 생성기. UTF-8 without BOM 출력 |
| `opencode.json.example` | OpenCode global config 참고본. caveman instructions + Ponytail npm plugin. 실제 파일명은 `opencode.json`/`opencode.jsonc` |
| `opencode-caveman.md` | OpenCode용 caveman 지침 본문 — `~/.config/opencode/caveman.md`로 복사 |
| `claude-settings.md` | 다른 머신에 옮길 때 참고 가이드 |
| `settings.json.example` | `~/.claude/settings.json` 참고본 (플레이스홀더 포함) |
| `statusline.sh` / `statusline.ps1` | 상태줄 스크립트 |
| `templates/` | harness와 무관한 프로젝트 bootstrap 템플릿 |
| `templates/project-rules.md` | 프로젝트 `CLAUDE.md`·`AGENTS.md` 공통 router 템플릿 |
| `templates/OPERATOR.md` | 선택적 Oz 운영 역할 템플릿 |
| `templates/.claudeignore` | 프로젝트용 ignore 템플릿 (deps/build/secrets 등). build가 두 harness의 `templates/`에 배치 → "저장된 .claudeignore 적용해줘" 시 거기서 프로젝트 루트로 복사 (`fragments/00-core.md` 참조) |
| `three-man-team-model-allocation.md` | 4역할 모델 배치 조사·결정 기록 (2026-07). 역할별 지배변수, 확정 라인업, 실측, 다음 검증 |

## 사용법

**global rules 고칠 때:** 생성된 `CLAUDE.md`·`AGENTS.md`를 직접 고치지 않는다. `fragments/*.md`를 고치고 `./build-claude-md.sh` 실행 — `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md`, `~/.config/opencode/AGENTS.md`에 동일하게 반영된다. `project-rules.md`·`OPERATOR.md`·`.claudeignore`도 두 harness의 template 경로에 복사된다. 최초 실행은 Foreman 포함 여부를 묻고 선택을 `.claude-settings.local`에 저장한다. 선택을 바꾸려면 이 파일의 값을 수정하거나 파일을 삭제하고 다시 실행한다.

**다른 머신에 세팅할 때:** `claude-settings.md` 참고. 설치 여부(caveman/three-man-team)는 파일 존재로 확인하고, 없으면 임의 설치하지 말고 사용자에게 확인.
