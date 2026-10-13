# Claude Code·OpenCode·omp·Crush 세팅 가이드 (aribaragi 적용용)

원본 머신(WSL2, gsjung)의 Claude Code·OpenCode·omp·Crush 세팅을 다른 머신에 옮기기 위한 참고 자료.
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
| `fragments/90-activation.md` | omp·Crush 전용 블록 (caveman·Ponytail 기본 off, 역할 표로 위임) |
| `build-claude-md.sh` | fragments를 이어붙여 `~/.claude/CLAUDE.md`, `~/.claude-personal/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.omp/agent/AGENTS.md`, `~/.config/crush/CRUSH.md` 생성 + 플러그인 스킬을 `~/.agents/skills/`로 복사 |
| `build-rules.ps1` | `pwsh` 7용 동일 생성기 (Windows PowerShell 5 미지원). UTF-8 without BOM 출력 |
| `templates/.claudeignore` | 프로젝트용 ignore 템플릿. build 스크립트가 네 harness의 `templates/`에 복사 |
| `templates/project-rules.md` | 프로젝트 `CLAUDE.md`·`AGENTS.md`에 동일하게 복사할 공통 router |
| `opencode.json.example` | OpenCode V1 global config 참고본 (Ponytail npm plugin). 실제 파일명은 `opencode.json` 또는 `opencode.jsonc` |
| `opencode.v2.json.example` | OpenCode V2 global config 참고본 (로컬 플러그인 `./plugins/caveman`·`./plugins/ponytail`) |
| `opencode-plugins/caveman-v2/` | caveman V2 임시 패치. 기존 upstream helper·스킬 위에 설치 (설치·제약·철수 조건은 내부 README) |
| `three-man-team-model-allocation.md` | 역할별 모델 기준·등급 시나리오·판정 원칙·리처드 벤더 실험 (모델명 미고정) |

## 설치 상태 확인 (진행 전 체크)

- caveman: `~/.claude/hooks/caveman-activate.js` 존재 + `settings.json`의 `enabledPlugins`에 `caveman@caveman`
- three-man-team: `~/.claude/skills/three-man-team/` 존재. 개인 포크 `dreamwayjgs/three-man-team`을 clone한다 (원본 `russelleNVy/three-man-team`은 `upstream` remote)
- karpathy-skills (옵셔널): `settings.json`의 `enabledPlugins`에 `andrej-karpathy-skills@karpathy-skills` + `extraKnownMarketplaces`에 `karpathy-skills`. 역할별 Karpathy 적용은 포크 템플릿 역할 파일의 karpathy 블록이 담당한다. 플러그인은 Claude Code 전용이고, 다른 하네스용 스킬은 build가 `agent-skills.txt`로 설치한다
- ponytail (옵셔널): Claude Code·OpenCode·Crush의 설치 경로가 다르다. Claude Code는 플러그인 마켓플레이스(github `DietrichGebert/ponytail`), OpenCode는 V1이면 npm 플러그인 `@dietrichgebert/ponytail`, V2면 `opencode-plugins/ponytail-v2` 로컬 패치, omp·Crush·OpenCode V2가 읽는 `~/.agents/skills`는 build가 `agent-skills.txt`에서 설치한다 (§5 참조). Claude 플러그인은 Claude Code에만 적용된다
- Foreman (옵셔널): 최초 `build-claude-md.sh` 실행에서 전역 연동 여부를 묻는다. 포함하려면 `foreman` 명령이 먼저 설치되어 있어야 한다

caveman·three-man-team 중 하나라도 없으면 → 사용자에게 설치 여부 확인 요청. 임의 설치 금지. (karpathy는 옵셔널 — 위 노트 참조.)

정본 출처 — three-man-team만 개인 포크(`dreamwayjgs/three-man-team`)이고 나머지는 원본을 쓴다: caveman `JuliusBrussee/caveman`, ponytail `DietrichGebert/ponytail`, karpathy `multica-ai/andrej-karpathy-skills` (구 `forrestchang/andrej-karpathy-skills`, GitHub 리다이렉트로 같은 레포). `opencode-plugins/caveman-v2`·`ponytail-v2`는 이 repo가 관리하는 OpenCode V2 로컬 호환 패치이지 upstream이 아니다 — 재설치·업데이트 때 upstream 설치기로 덮어쓰지 말고 각 README의 절차와 철수 조건을 따른다. 순서는 repo 패치 수정 → 설치 → 검증.

---

## 1. caveman — 설치 후 설정

원본 머신 기준 설치 후 상태 (`settings.json.example` 참조):

- 훅(`SessionStart`·`SubagentStart`·`UserPromptSubmit`)은 플러그인 manifest가 등록한다. `settings.json`에 caveman 훅을 따로 넣지 않는다 — 2026-10-13까지 같은 훅이 `~/.claude/hooks/` 사본으로 중복 등록돼 있었고, v3 업그레이드 때 제거했다. 플러그인 훅은 `node`를 PATH에서 찾으니 nvm 환경에서는 nvm이 로드된 셸에서 Claude를 띄운다 (없으면 조용히 건너뛴다).
- `~/.claude/hooks/caveman-*`는 statusline 배지(`statusline.sh` → `hooks/caveman-statusline.sh`)만 쓴다. 플러그인 업데이트 뒤 `~/.claude/plugins/cache/caveman/caveman/<version>/src/hooks/`의 `caveman-activate.js`·`caveman-config.js`·`caveman-mode-tracker.js`·`caveman-stats.js`·`caveman-statusline.sh`·`caveman-statusline.ps1`를 다시 복사한다.
- `<HOME>` → 홈 디렉토리 절대경로로 치환 (statusLine)
- 버전: 플러그인 3.2.0 (2026-10-13). `agent-skills.txt`의 caveman ref와 같이 올린다.

사용법:

- 세션 시작 시 기본 off (`~/.config/caveman/config.json`의 `defaultMode: off`, §5-1)
- 모드: `/caveman` = `caveman`(기본), `/caveman ultracave`, `/caveman megacave`(문언문). v3부터 lite·full·ultra 레벨은 없고 옛 이름은 별칭으로만 남아 있다. 상태는 세션별(`.caveman-sessions/<id>/`)
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

역할 파일 커스텀(로저 2차 리뷰어, Oz, karpathy 섹션, 테스트 정책, 리뷰어 규칙)은 포크 템플릿에 있고, 전역 규칙(앨리스 이름 치환, 한국어 진행, 셋업 절차)은 이 폴더의 fragment에 있다. 설치 확인 후 병합:

```bash
./build-claude-md.sh   # Bash: fragments/ -> Claude Code·OpenCode·omp·Crush global rules
pwsh -File ./build-rules.ps1  # Windows: same output, UTF-8 without BOM
```

build는 마지막에 `agent-skills.txt`(repo·ref·스킬 이름)의 스킬을 `npx skills add`로 `~/.agents/skills`에 설치한다. node와 네트워크가 필요하고, Claude Code 설치 여부와 무관하다. ref는 full commit sha 또는 태그만 된다(CLI가 `git clone --branch <ref>`를 쓴다). 설치 출처·ref·해시는 `~/.agents/.skill-lock.json`에 남는다. ref를 올릴 땐 매니페스트 수정 → 모든 머신에서 build, Claude 머신은 `claude plugin update`도 같이.

최초 실행에서 Foreman 포함 여부를 선택한다. 선택은 Git에서 제외되는 `.claude-settings.local`에 저장되며 이후 빌드에서도 재사용된다. 선택을 바꾸려면 이 파일의 값을 수정하거나 삭제 후 다시 실행한다. 비대화형 최초 실행은 `INCLUDE_FOREMAN=true|false ./build-claude-md.sh`처럼 명시한다.

사용법:

- 프로젝트 루트에서 "three-man-team 세팅해줘" → fragment의 셋업 절차 실행 (포크 템플릿 복사, Alice 치환, 공통 `CLAUDE.md`·`AGENTS.md`)
- "operator 세팅해줘" → 선택적으로 Oz `OPERATOR.md` 추가. 환경 좌표를 실측으로 채우기 전에는 운영 조작 금지
- 역할: 앨리스(설계)·밥(구현)·리처드(1차 리뷰)·로저(2차 리뷰)·선택적 Oz(운영) — 대화는 한국어
- handoff 파일은 BUILD-LOG.md 제외하고 매 스텝 덮어쓰기
- 테스트는 밥만 실행, 리뷰어들은 밥의 고지 참조 (fragment의 테스트 검증 정책 참조)

## 4. settings.json 나머지 항목 (선택)

`settings.json.example`의 `permissions.allow`는 원본 머신에서 쓰는 읽기성 명령 허용 목록 — 그대로 써도 무방, 취향껏 조정.

`enabledPlugins`·`extraKnownMarketplaces`에는 caveman 외에 karpathy-skills·ponytail이 들어 있다. 둘 다 옵셔널이라 안 쓰면 해당 항목만 지운다. `permissions.allow`의 MCP 항목(Atlassian·figma)은 해당 MCP 서버를 붙인 머신에서만 의미가 있다.

머신·계정별로 다른 값은 example에서 **제외**했으니 각자 채운다:

- `model` — 계정이 지원하는 모델·컨텍스트에 따라 다름 (원본은 `opus[1m]`)
- `tui` — 표시 취향 (원본은 `fullscreen`)
- `skipDangerousModePermissionPrompt` — 권한 우회 모드 진입 시 확인 프롬프트를 없애는 옵션. 기본값(미설정)을 권장하며, 켤 경우 그 머신에서 무엇이 자동 실행되는지 알고 켤 것

## 5. ponytail — harness별 설치 경로

Claude Code와 OpenCode가 서로 다른 배포 채널을 쓴다. Crush는 네이티브 플러그인 훅을 지원하지 않아 스킬과 전역 컨텍스트를 직접 등록한다. 양쪽 다 쓰려면 각각 설치해야 한다.

Claude Code (플러그인 마켓플레이스):

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
/reload-plugins
```

결과가 `settings.json`의 `enabledPlugins`·`extraKnownMarketplaces`에 기록된다 (`settings.json.example` 참조).

OpenCode는 머신의 메이저 버전에 맞춰 고른다:

- **V1 (npm 플러그인)** — config의 `plugin` 배열에 `@dietrichgebert/ponytail`을 넣으면 기동 시 자동 설치된다 (`opencode.json.example`).
- **V2 (로컬 임시 패치)** — upstream `ponytail.mjs`는 V1 API 전용이라 V2에서 기동 시 크래시한다. upstream이 V2를 지원할 때까지 `opencode-plugins/ponytail-v2/`의 패치를 로컬 플러그인으로 설치하고 `plugins`에 `./plugins/ponytail`을 지정한다 (`opencode.v2.json.example`, 설치·철수 조건은 해당 README).

omp·Crush·OpenCode V2용 스킬은 build가 `agent-skills.txt`의 고정 ref로 `~/.agents/skills`에 설치한다 (세 하네스가 기본으로 읽는 경로, §3). Claude 유무와 무관하다. 기본 off — build가 규칙 끝에 붙이는 `fragments/90-activation.md`가 역할 표로 위임. 다른 경로(`~/.config/crush/skills`, `~/.claude/skills`, `~/.config/opencode/skills`)에 같은 이름을 두지 말 것 — 하네스마다 우선순위가 달라 어느 사본이 이기는지 갈린다.

Crush 공통 제약 (A·B 동일): `ponytail`과 `ponytail-review`는 스킬 frontmatter에 `user-invocable: true`가 없어 `/ponytail`·`/ponytail-review` 명령으로 직접 실행할 수 없다. Crush는 `PreToolUse`만 지원하므로 Claude Code와 같은 세션 상태 추적 훅은 적용하지 않는다.

## 5-1. caveman·Ponytail 기본 off

역할 없는 세션은 둘 다 미적용, 역할 세션만 전역 규칙(`fragments/10-three-man-team.md`)의 역할별 표대로 스킬 로드. 표는 프로젝트에 복사하지 않는다. hook·plugin 기본값을 끈다 (Claude Code·OpenCode 공통, env `CAVEMAN_DEFAULT_MODE`·`PONYTAIL_DEFAULT_MODE`가 있으면 그게 우선):

```bash
mkdir -p ~/.config/caveman ~/.config/ponytail
echo '{"defaultMode":"off"}' > ~/.config/caveman/config.json
echo '{"defaultMode":"off"}' > ~/.config/ponytail/config.json
```

Windows는 경로가 `%APPDATA%\caveman\config.json`·`%APPDATA%\ponytail\config.json`이다 (두 플러그인 모두 win32에서 APPDATA 사용):

```powershell
foreach ($t in 'caveman','ponytail') { New-Item -ItemType Directory -Force "$env:APPDATA\$t" | Out-Null; '{"defaultMode":"off"}' | Set-Content -Encoding utf8NoBOM "$env:APPDATA\$t\config.json" }
```

역할 세션의 Session Start는 스킬 로드로만 모드를 맞춘다 (`/caveman`·`/ponytail` 명령으로 전환하지 않는다). 사용자가 직접 명령을 쓰는 건 자유지만, 모드 플래그(`~/.claude/.caveman-active` 등)가 머신 전역이라 동시에 떠 있는 다른 세션에도 적용된다. 스킬 미설치면 건너뛴다.

## 6. OpenCode 추가 파일

`build-claude-md.sh`가 만들어주지 않는 것:

```bash
cp opencode.json.example ~/.config/opencode/opencode.jsonc      # V1
cp opencode.v2.json.example ~/.config/opencode/opencode.json    # V2
```

caveman 지침은 `instructions`로 상시 주입하지 않는다 (기본 off, §5-1). `opencode.json`·`opencode.jsonc` 둘 다 유효 — 원본 머신은 2026-10-13 V2 전환 후 `.json`을 쓴다. 두 파일을 같이 두지 말 것.

## 7. omp·Crush

설정 파일(`~/.omp/agent/config.yml`, `~/.config/crush/crush.json`)은 건드리지 않는다. build가 쓰는 파일만으로 맞춘다:

| 항목 | omp | Crush |
|---|---|---|
| 전역 규칙 | `~/.omp/agent/AGENTS.md` (최우선, 사용자 단위 1개만 로드) | `~/.config/crush/CRUSH.md` (기본 `global_context_paths`) |
| 템플릿 | `~/.omp/agent/templates/` | `~/.config/crush/templates/` |
| 스킬 | `~/.agents/skills/` (기본 스캔) | `~/.agents/skills/` (기본 스캔) |
| caveman·Ponytail | 기본 off, 규칙 끝 블록이 역할 표로 위임 (hook 없음) | 동일 |

- 스킬 복사는 `jq` 필요(Bash). Claude 플러그인이 없는 머신이면 skip — 스킬만 빠지고 나머지는 적용된다.
- `caveman-stats`(Claude 세션 로그)·`cavecrew`(Claude 서브에이전트)는 omp·Crush에서 동작하지 않는다.
- Crush는 프로젝트 루트 `CLAUDE.md`·`AGENTS.md`를 둘 다 읽는다 — 공통 router가 두 번 주입된다(짧아서 감수). omp는 둘 다 찾지만 같은 디렉토리 depth에서는 하나만 주입한다(실측: `AGENTS.md`).
- Crush 설정에 `global_context_paths`를 직접 넣으면 기본값을 **대체**한다. 넣을 거면 `~/.config/crush/CRUSH.md`를 목록에 다시 포함할 것.

## 8. 옵션 (머신별 취향)

필수 아님. 쓰는 머신에만 적용한다.

- **Crush yolo 함수** — Crush는 설정 파일로 yolo 기본값을 둘 수 없고 `--yolo` 플래그만 있다. 승인 분류기가 번거로우면 함수를 따로 둔다 (원래 `crush`는 승인 모드로 유지). 인자 전달이 깔끔해서 alias 대신 함수를 쓴다:
  ```bash
  # ~/.bash_aliases
  crusy() { command crush --yolo "$@"; }
  ```
  Windows pwsh (`$PROFILE`):
  ```powershell
  function crusy { crush --yolo @args }
  ```
  모든 승인이 사라지므로 리뷰어 역할의 테스트·코드 수정 금지는 역할 지침만으로 지켜진다. 외부 콘텐츠(fetch·남의 repo)를 읽는 세션에서는 쓰지 않는다. 일부만 자동 승인하려면 대신 `~/.config/crush/crushrc`에 `permissions allow view ls grep glob edit multiedit write fetch`.

- **Claude 모델 선택 함수 (`claudef`·`claudeo`·`claudes`)** — `--model` 별칭(`fable`·`opus`·`sonnet`)은 항상 최신 버전으로 풀리므로 버전을 고정하지 않는다. 접미사는 모델 머리글자다. 계정 분리 함수와 독립이고, 조합하려면 `pclaude --model opus`처럼 인자로 붙인다:
  ```bash
  # ~/.bash_aliases
  claudef() { command claude --model fable "$@"; }
  claudeo() { command claude --model opus "$@"; }
  claudes() { command claude --model sonnet "$@"; }
  ```
  Windows pwsh (`$PROFILE`):
  ```powershell
  function claudef { claude --model fable @args }
  function claudeo { claude --model opus @args }
  function claudes { claude --model sonnet @args }
  ```

- **omp 모델 선택 함수 (`ompcf`·`ompco`·`ompcs`, `ompga`·`ompgs`·`ompgt`·`ompgl`)** — `c`=Claude(Fable·Opus·Sonnet), `g`=GPT(Astra·Sol·Terra·Luna), 끝 글자는 모델 머리글자다. omp `--model`은 최신 버전 별칭이 없어 ID를 고정하므로, 새 모델이 나오면 `omp models`로 확인해 아래 ID만 고친다 (2026-10 기준). GPT 모델은 인증이 있어야 목록에 나온다. 머신마다 한 방식을 고른다: (a) ChatGPT 구독이면 `omp login`에서 1번(`openai-codex`, 헤드리스는 12번), (b) 개발자 API 키면 `omp login` 목록에 OpenAI 항목이 없으므로 `~/.omp/agent/.env`(chmod 600)에 `OPENAI_API_KEY=...`를 직접 적는다. omp만 읽는 파일이라 셸 전역 export보다 자식 프로세스 노출이 적다. 키는 repo에 두지 않는다. 인자는 그대로 전달되므로 `ompgs -p "..."`처럼 쓴다:
  ```bash
  # ~/.bash_aliases
  ompcf() { command omp --model claude-fable-5-1 "$@"; }
  ompco() { command omp --model claude-opus-5-5 "$@"; }
  ompcs() { command omp --model claude-sonnet-5-5 "$@"; }
  ompga() { command omp --model gpt-6-astra "$@"; }
  ompgs() { command omp --model gpt-6.1-sol "$@"; }
  ompgt() { command omp --model gpt-5.6-terra "$@"; }
  ompgl() { command omp --model gpt-6-luna "$@"; }
  ```
  Windows pwsh (`$PROFILE`):
  ```powershell
  function ompcf { omp --model claude-fable-5-1 @args }
  function ompco { omp --model claude-opus-5-5 @args }
  function ompcs { omp --model claude-sonnet-5-5 @args }
  function ompga { omp --model gpt-6-astra @args }
  function ompgs { omp --model gpt-6.1-sol @args }
  function ompgt { omp --model gpt-5.6-terra @args }
  function ompgl { omp --model gpt-6-luna @args }
  ```
  `-pro` 변형(`gpt-5.6-sol-pro` 등)은 함수를 만들지 않았다. 필요하면 `omp --model gpt-5.6-sol-pro`로 직접 쓴다.

- **Claude 계정 분리 (`pclaude`·`aclaude` 등)** — 계정마다 설정 폴더를 따로 두고 `CLAUDE_CONFIG_DIR`로 바꿔 띄운다. alias보다 함수가 인자 전달이 깔끔하다. 별칭·함수는 `~/.bash_aliases`에 모은다 (Ubuntu 기본 `.bashrc`가 자동 로드):
  ```bash
  pclaude() { CLAUDE_CONFIG_DIR="$HOME/.claude-personal" command claude "$@"; }
  ```
  Windows pwsh (`$PROFILE`, 원래 값 복원):
  ```powershell
  function pclaude {
      $old = $env:CLAUDE_CONFIG_DIR
      $env:CLAUDE_CONFIG_DIR = "$HOME\.claude-personal"
      try { claude @args } finally {
          if ($null -eq $old) { Remove-Item Env:\CLAUDE_CONFIG_DIR } else { $env:CLAUDE_CONFIG_DIR = $old }
      }
  }
  ```
  - 폴더는 완전히 독립 — 인증(`.credentials.json`)·`settings.json`·플러그인·스킬·세션 이력을 따로 가진다. 첫 실행에서 로그인하고, 플러그인(caveman·ponytail 등)은 그 계정으로 다시 설치한다.
  - `build-claude-md.sh`·`build-rules.ps1`은 `~/.claude-personal/CLAUDE.md`만 대상으로 쓴다. 다른 폴더명(예: works 서버의 `aclaude` → `~/.claude-admin`)을 쓰면 build 대상에 추가하거나 `~/.claude/CLAUDE.md`를 복사한다.
  - statusline과 caveman·Ponytail 모드 플래그는 `CLAUDE_CONFIG_DIR`을 따른다 — 계정 폴더 사이에서는 모드가 새지 않는다.

- **Claude 워커 디렉터리 (`wclaude`, tmt-cli 전용)** — 앨리스가 CLI로 밥·리처드·로저를 호출할 때 쓰는 두 번째 설정 폴더. 계정 분리와 같은 `CLAUDE_CONFIG_DIR` 방식이지만 계정은 같다. 목적은 워커 첫 호출 컨텍스트 축소(tmt-cli Step K 실측 -27%, 비용은 중립)이며 statusLine·플러그인·소유자용 지침이 빠진다:
  ```bash
  wclaude() { CLAUDE_CONFIG_DIR="$HOME/.claude-worker" command claude "$@"; }
  ```
  - 생성: `mkdir ~/.claude-worker` 후 `settings.json.example`을 `~/.claude-worker/settings.json`으로 복사하고 `statusLine` 삭제, `enabledPlugins`를 `{}`, `extraKnownMarketplaces` 삭제(플러그인을 안 쓰는데 마켓플레이스 캐시만 받아온다). `model`·`tui`는 두지 않는다. permissions·hooks·autoMode·effortLevel 등 나머지는 본 `~/.claude/settings.json`과 같게 둔다 — hooks 경로는 `~/.claude/hooks/`를 그대로 가리킨다. 플러그인 캐시 복사는 불필요하다. 워커는 스킬을 `~/.agents/skills/<name>/SKILL.md` 파일로 읽는다.
  - `wclaude login`으로 한 번 로그인한다. `.credentials.json`을 복사하지 않는다 (refresh token 공유).
  - `~/.claude-worker/CLAUDE.md`를 두지 않는다. `$HOME` 아래 레포에서는 `~/.claude/CLAUDE.md`가 조상 Project 파일로 로드되므로(haiku `-p` 실측) 두면 중복만 된다. `$HOME` 밖 레포(`/mnt/c/...` 등)에서는 로드되지 않으니 거기서는 워커를 쓰지 않는다.
  - build 대상이 아니다. `build-claude-md.sh`·`build-rules.ps1`에 추가하지 않는다.

## 검증

1. 역할 없는 새 세션 → caveman 톤·Ponytail 주입 없음. 역할 세션(예: 밥) → 표대로 스킬 로드
2. 상태줄에 `모델 | 디렉토리 | Ctx:N%` 보이면 statusline OK
3. 아무 프로젝트에서 "three-man-team 세팅해줘" → ARCHITECT.md·BUILDER.md·REVIEWER.md·ROGER.md 생성, Alice 치환, karpathy 블록, 동일한 `CLAUDE.md`·`AGENTS.md` 확인
4. `omp`·`crush` 새 세션 → caveman 톤 + `ponytail` 스킬 로드 여부 확인. 스킬 목록에 caveman·ponytail·karpathy-guidelines 보이면 OK (`~/.agents/.skill-lock.json`의 ref가 `agent-skills.txt`와 같은지도 확인)
