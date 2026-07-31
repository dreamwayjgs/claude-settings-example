# Claude Code·OpenCode 세팅 가이드 (aribaragi 적용용)

원본 머신(WSL2, gsjung)의 Claude Code·OpenCode 세팅을 다른 머신에 옮기기 위한 참고 자료.
파일들은 "현재 값" 그대로이므로, 이 머신 상황(경로·설치 도구)에 맞게 치환해서 적용할 것.

**전제:** caveman·three-man-team 설치(각 repo의 기본 설치법)는 사용자가 직접 수행함.
이 가이드는 설치 이후의 설정과 사용법만 다룬다.
**설치가 안 되어 있는 것 같으면(파일/플러그인 부재 등) 임의로 설치를 진행하지 말고 사용자에게 되물을 것.**

## 폴더 내용

| 파일 | 용도 |
|---|---|
| `claude-settings.md` | 이 가이드 |
| `settings.json.example` | `~/.claude/settings.json` 참고본 (플레이스홀더 포함) |
| `statusline.sh` | 상태줄 스크립트 (Linux/macOS/WSL) — `~/.claude/statusline.sh`로 복사 |
| `statusline.ps1` | 상태줄 스크립트 (Windows PowerShell 버전, 동일 기능) |
| `fragments/00-core.md`, `fragments/10-three-man-team.md` | 동일 내용의 global `CLAUDE.md`·`AGENTS.md` source of truth |
| `fragments/05-foreman.md` | 선택적 Foreman 전역 규칙 |
| `build-claude-md.sh` | fragments를 이어붙여 `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md`, `~/.config/opencode/AGENTS.md` 생성 |
| `build-rules.ps1` | `pwsh`용 동일 생성기. UTF-8 without BOM 출력 |
| `templates/.claudeignore` | 프로젝트용 ignore 템플릿. build 스크립트가 두 harness의 `templates/`에 복사 |
| `templates/project-rules.md` | 프로젝트 `CLAUDE.md`·`AGENTS.md`에 동일하게 복사할 공통 router |
| `templates/OPERATOR.md` | 선택적 Oz 운영 역할 템플릿 |
| `opencode.json.example` | OpenCode global config 참고본 (caveman instructions + Ponytail npm plugin). 실제 파일명은 `opencode.json` 또는 `opencode.jsonc` |
| `opencode-caveman.md` | OpenCode용 caveman 지침 본문 — `~/.config/opencode/caveman.md`로 복사 |
| `three-man-team-model-allocation.md` | 4역할 모델 배치 조사·결정 기록 (2026-07) |

## 설치 상태 확인 (진행 전 체크)

- caveman: `~/.claude/hooks/caveman-activate.js` 존재 + `settings.json`의 `enabledPlugins`에 `caveman@caveman`
- three-man-team: `~/.claude/skills/three-man-team/` 존재 (upstream: `russelleNVy/three-man-team`)
- qmd (옵셔널): 설치되어 있으면 global router가 `qmd search`를 우선 사용하고, 없으면 Grep/Glob/Read로 자동 fallback. 임베딩 모델이 없으면 `qmd search`만 사용
- karpathy-skills (각자 설치): `settings.json`의 `enabledPlugins`에 `andrej-karpathy-skills@karpathy-skills` + `extraKnownMarketplaces`에 `karpathy-skills` (github `forrestchang/andrej-karpathy-skills`). 셋업 시 넣는 karpathy 블록은 `fragments/10-three-man-team.md`에 이미 박혀 있어 플러그인과 무관 — 플러그인은 등록만 하면 끝
- ponytail (옵셔널): Claude Code와 OpenCode의 설치 경로가 다르다. Claude Code는 플러그인 마켓플레이스(github `DietrichGebert/ponytail`), OpenCode는 npm 플러그인 `@dietrichgebert/ponytail`. 한쪽만 깔면 다른 쪽에는 적용되지 않는다 (§5 참조)
- Foreman (옵셔널): 최초 `build-claude-md.sh` 실행에서 전역 연동 여부를 묻는다. 포함하려면 `foreman` 명령이 먼저 설치되어 있어야 한다

caveman·three-man-team 중 하나라도 없으면 → 사용자에게 설치 여부 확인 요청. 임의 설치 금지. (qmd·karpathy는 옵셔널 — 위 노트 참조.)

---

## 1. caveman — 설치 후 설정

원본 머신 기준 설치 후 상태 (`settings.json.example` 참조):

- `SessionStart` / `UserPromptSubmit` hooks가 `~/.claude/hooks/caveman-*.js`를 node로 실행
- hooks의 node 경로는 절대경로 필수 — nvm 환경이면 hook 실행 시 로그인 셸이 아닐 수 있어 `node`만으로는 못 찾음. `<NODE_BIN>` → `which node` 결과로 치환
- `<HOME>` → 홈 디렉토리 절대경로로 치환

사용법:

- 세션 시작 시 자동 활성 (기본 `full` 레벨)
- 레벨 전환: `/caveman lite|full|ultra`
- 해제: "stop caveman" / "normal mode"
- 통계: `/caveman-stats`, 도움말: `/caveman-help`
- 커밋 메시지: `/caveman-commit`, 리뷰: `/caveman-review`
- 코드·커밋·PR·보안 경고는 압축 미적용 (정상 문장으로 작성됨)

## 2. statusline — 파일 복사로 적용

이건 repo 설치 아님 — 이 폴더의 스크립트를 복사한다:

```bash
cp statusline.sh ~/.claude/statusline.sh
```

`settings.json`에 등록 (절대경로 사용):

```json
"statusLine": {
  "type": "command",
  "command": "bash /절대경로/.claude/statusline.sh"
}
```

세그먼트: `[caveman 배지] | 모델 | 디렉토리 | Ctx:잔여% | 레이트리밋`

- caveman 배지는 `~/.claude/hooks/caveman-statusline.sh` 존재 시에만 표시 (caveman 설치가 만들어줌 — 없으면 자동 생략, 에러 아님)
- 의존: `jq`, `awk`. Synology 등에서 jq 없으면 사용자에게 알릴 것.

Windows에서 쓸 경우 `statusline.ps1` 사용 (기능 동일, jq 불필요 — PowerShell 내장 JSON 파싱):

```json
"statusLine": {
  "type": "command",
  "command": "powershell -NoProfile -File C:\\Users\\<사용자>\\.claude\\statusline.ps1"
}
```

caveman 배지도 동일 방식 — `hooks/caveman-statusline.ps1` 존재 시에만 표시.

## 3. three-man-team — 설치 후 설정

upstream repo에는 커스텀 규칙(앨리스 이름 치환, karpathy 섹션, 로저 2차 리뷰어, 한국어 진행)이 없음 — 이 폴더의 fragment가 전부. 설치 확인 후 병합:

```bash
./build-claude-md.sh   # Bash: fragments/ -> Claude Code·OpenCode global rules
pwsh -File ./build-rules.ps1  # Windows: same output, UTF-8 without BOM
```

최초 실행에서 Foreman 포함 여부를 선택한다. 선택은 Git에서 제외되는 `.claude-settings.local`에 저장되며 이후 빌드에서도 재사용된다. 선택을 바꾸려면 이 파일의 값을 수정하거나 삭제 후 다시 실행한다. 비대화형 최초 실행은 `INCLUDE_FOREMAN=true|false ./build-claude-md.sh`처럼 명시한다.

qmd는 선택 사항이다. 설치되면 global router가 우선 사용하고, 없으면 Grep/Glob/Read로 fallback한다.

사용법:

- 프로젝트 루트에서 "three-man-team 세팅해줘" → fragment의 셋업 절차 실행 (upstream 템플릿 복사, Alice 치환, karpathy 블록 추가, 공통 `CLAUDE.md`·`AGENTS.md`, `ROGER.md` 생성)
- "operator 세팅해줘" → 선택적으로 Oz `OPERATOR.md` 추가. 환경 좌표를 실측으로 채우기 전에는 운영 조작 금지
- 역할: 앨리스(설계)·밥(구현)·리처드(1차 리뷰)·로저(2차 리뷰)·선택적 Oz(운영) — 대화는 한국어
- handoff 파일은 BUILD-LOG.md 제외하고 매 스텝 덮어쓰기
- 테스트는 밥만 실행, 리뷰어들은 밥의 고지 참조 (fragment의 테스트 검증 정책 참조)

## 4. settings.json 나머지 항목 (선택)

`settings.json.example`의 `permissions.allow`는 원본 머신에서 쓰는 읽기성 명령 허용 목록 — 그대로 써도 무방, 취향껏 조정.

`enabledPlugins`·`extraKnownMarketplaces`에는 caveman 외에 qmd·karpathy-skills·ponytail이 들어 있다. 셋 다 옵셔널이라 안 쓰면 해당 항목만 지운다. `permissions.allow`의 MCP 항목(Atlassian·qmd·figma)은 해당 MCP 서버를 붙인 머신에서만 의미가 있다.

머신·계정별로 다른 값은 example에서 **제외**했으니 각자 채운다:

- `model` — 계정이 지원하는 모델·컨텍스트에 따라 다름 (원본은 `opus[1m]`)
- `tui` — 표시 취향 (원본은 `fullscreen`)
- `skipDangerousModePermissionPrompt` — 권한 우회 모드 진입 시 확인 프롬프트를 없애는 옵션. 기본값(미설정)을 권장하며, 켤 경우 그 머신에서 무엇이 자동 실행되는지 알고 켤 것

## 5. ponytail — harness별 설치 경로

Claude Code와 OpenCode가 서로 다른 배포 채널을 쓴다. 양쪽 다 쓰려면 각각 설치해야 한다.

Claude Code (플러그인 마켓플레이스):

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
/reload-plugins
```

결과가 `settings.json`의 `enabledPlugins`·`extraKnownMarketplaces`에 기록된다 (`settings.json.example` 참조).

OpenCode (npm 플러그인): config의 `plugin` 배열에 `@dietrichgebert/ponytail`을 넣으면 기동 시 자동 설치된다 (`opencode.json.example` 참조).

global router(`fragments/10-three-man-team.md`)는 "Ponytail이 설정된 환경에서는" 조건부로 쓰도록 되어 있어, 미설치 머신에서도 규칙 파일은 그대로 둬도 된다.

## 6. OpenCode 추가 파일

`build-claude-md.sh`가 만들어주지 않는 것:

```bash
cp opencode-caveman.md ~/.config/opencode/caveman.md
cp opencode.json.example ~/.config/opencode/opencode.jsonc   # <HOME> 치환 후
```

`instructions` 항목은 절대경로만 받으므로 `<HOME>`을 치환해야 한다. `opencode.json`·`opencode.jsonc` 둘 다 유효 — 원본 머신은 `.jsonc`를 쓴다. 두 파일을 같이 두지 말 것.

## 검증

1. `claude` 새 세션 시작 → 첫 응답이 caveman 톤(단문·관사 생략)이면 hook 동작 OK
2. 상태줄에 `모델 | 디렉토리 | Ctx:N%` 보이면 statusline OK
3. 아무 프로젝트에서 "three-man-team 세팅해줘" → ARCHITECT.md·BUILDER.md·REVIEWER.md·ROGER.md 생성, Alice 치환, karpathy 블록, 동일한 `CLAUDE.md`·`AGENTS.md` 확인
