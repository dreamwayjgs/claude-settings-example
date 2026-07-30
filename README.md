# claude-settings-example

> **Public repo.** 사내 정책상 Internal 가시성 사용 불가해 Public으로 둠. 시크릿·고객사 정보 없음(확인 완료) — 그래도 fragment 추가할 때마다 커밋 전에 한 번 더 훑어볼 것.

개인 Claude Code 세팅(WSL2, gsjung)의 source of truth. 다른 머신에 옮기거나 급하게 복붙할 때 여기서 가져온다.

**전제:** caveman·three-man-team 설치(각 repo의 기본 설치법)는 새 머신에서 직접 수행. 이 repo는 설치 이후의 설정만 다룬다.

**Foreman 제외:** 이 repo는 설정 export용 — 주간 원장 보고 대상 아님. `foreman register`/`update`/`guide` 돌리지 말 것.

## 구조

| 경로 | 용도 |
|---|---|
| `fragments/00-core.md` | `CLAUDE.md` 앞부분 — arguing 규칙, 개발 세션, 템플릿. 자주 바뀜 |
| `fragments/05-foreman.md` | 선택적 Foreman 전역 규칙. 최초 빌드에서 포함 여부 결정 |
| `fragments/10-three-man-team.md` | `CLAUDE.md`의 Three Man Team 전체 블록. 안정적, 거의 안 바뀜 |
| `build-claude-md.sh` | fragments를 순서대로 이어붙여 `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md`에 씀 |
| `claude-settings.md` | 다른 머신에 옮길 때 참고 가이드 |
| `settings.json.example` | `~/.claude/settings.json` 참고본 (플레이스홀더 포함) |
| `statusline.sh` / `statusline.ps1` | 상태줄 스크립트 |
| `templates/` | `~/.claude/templates/`로 복사할 파일들 |
| `templates/.claudeignore` | 프로젝트용 ignore 템플릿 (deps/build/secrets 등). "저장된 .claudeignore 적용해줘" 시 프로젝트 루트로 복사 (`fragments/00-core.md` 참조) |
| `three-man-team-for-others.md` | three-man-team 전체 셋업 (외부 AI용 self-contained 버전) |
| `operator-role-for-others.md` | three-man-team에 **Operator(SRE/release) 5번째 역할** 추가 (외부용 self-contained). 라이브 서버 조사·배포·롤백 담당, Tier 권한 체계, 조사 방법론. **환경 좌표는 전부 플레이스홀더** — 프로젝트별로 채워야 동작 |
| `three-man-team-model-allocation.md` | 4역할 모델 배치 조사·결정 기록 (2026-07). 역할별 지배변수, 확정 라인업, 실측, 다음 검증 |

## 사용법

**CLAUDE.md 고칠 때:** `~/.claude/CLAUDE.md`를 직접 고치지 않는다. `fragments/*.md`를 고치고 `./build-claude-md.sh` 실행 — 두 위치(`~/.claude`, `~/.claude-personal`)에 동일하게 반영된다. 최초 실행은 Foreman 포함 여부를 묻고 선택을 `.claude-settings.local`에 저장한다. 선택을 바꾸려면 이 파일의 값을 수정하거나 파일을 삭제하고 다시 실행한다.

**다른 머신에 세팅할 때:** `claude-settings.md` 참고. 설치 여부(caveman/three-man-team)는 파일 존재로 확인하고, 없으면 임의 설치하지 말고 사용자에게 확인.
