# Claude Code 세팅 가이드 (aribaragi 적용용)

원본 머신(WSL2, gsjung)의 Claude Code 세팅을 다른 머신에 옮기기 위한 참고 자료.
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
| `fragments/00-core.md`, `fragments/10-three-man-team.md` | 글로벌 `~/.claude/CLAUDE.md`의 source of truth |
| `build-claude-md.sh` | fragments를 이어붙여 `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md` 생성 |
| `templates/dev.md` | `~/.claude/templates/dev.md`로 복사 (개발 세션 지침) |
| `templates/.claudeignore` | `~/.claude/templates/.claudeignore`로 복사 (프로젝트용 ignore 템플릿) |
| `three-man-team-for-others.md` | three-man-team 전체 셋업 자료 (커스텀 포함, 외부 AI용 self-contained 버전) — 참고용 |

## 설치 상태 확인 (진행 전 체크)

- caveman: `~/.claude/hooks/caveman-activate.js` 존재 + `settings.json`의 `enabledPlugins`에 `caveman@caveman`
- three-man-team: `~/.claude/skills/three-man-team/` 존재 (upstream: `russelleNVy/three-man-team`)
- qmd (옵셔널): `settings.json`의 `extensions`에 `qmd` (github `tobi/qmd`). 미설치여도 무방 — `templates/dev.md`의 "qmd 우선" 섹션만 삭제하면 됨
- karpathy-skills (각자 설치): `settings.json`의 `extensions`에 `karpathy-skills` (github `forrestchang/andrej-karpathy-skills`). 셋업 시 넣는 karpathy 블록은 `fragments/10-three-man-team.md`에 이미 박혀 있어 플러그인과 무관 — 플러그인은 등록만 하면 끝

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
mkdir -p ~/.claude/templates
cp templates/dev.md ~/.claude/templates/dev.md
cp templates/.claudeignore ~/.claude/templates/.claudeignore
./build-claude-md.sh   # fragments/ -> ~/.claude/CLAUDE.md, ~/.claude-personal/CLAUDE.md
```

주의: `templates/dev.md`의 "코드베이스 탐색 — qmd 우선" 섹션은 qmd 플러그인 전제 — qmd 미설치면 해당 섹션 삭제.

사용법:

- 프로젝트 루트에서 "three-man-team 세팅해줘" → fragment의 셋업 절차 실행 (템플릿 복사, Alice 치환, karpathy 블록 추가, AGENTS.md=로저 생성)
- 역할: 앨리스(설계)·밥(구현)·리처드(1차 리뷰)·로저(2차 리뷰) — 대화는 한국어
- handoff 파일은 BUILD-LOG.md 제외하고 매 스텝 덮어쓰기
- 테스트는 밥만 실행, 리뷰어들은 밥의 고지 참조 (fragment의 테스트 검증 정책 참조)

## 4. settings.json 나머지 항목 (선택)

`settings.json.example`의 `permissions.allow`는 원본 머신에서 쓰는 읽기성 명령 허용 목록 — 그대로 써도 무방, 취향껏 조정.

원본에는 이 외에 qmd·karpathy-skills 플러그인, figma·Atlassian MCP 권한도 있으나 머신·계정별로 달라 example에서 제외함. qmd·karpathy는 옵셔널 — 설치·등록법은 위 "설치 상태 확인" 노트 참조. MCP 권한은 각 머신에서 취향껏 추가.

## 검증

1. `claude` 새 세션 시작 → 첫 응답이 caveman 톤(단문·관사 생략)이면 hook 동작 OK
2. 상태줄에 `모델 | 디렉토리 | Ctx:N%` 보이면 statusline OK
3. 아무 프로젝트에서 "three-man-team 세팅해줘" → ARCHITECT.md 등 생성 + Alice 치환 + karpathy 블록 + AGENTS.md(로저) 확인
