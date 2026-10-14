# 머신 전환 프롬프트 — three-man-team 포크로 전환

각 머신에서 한 번, 역할 없는 세션에 붙여 넣는다. harness는 무엇이든 된다.

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 머신의 three-man-team checkout을 개인 포크로 전환하고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐.
Windows면 pwsh 7 기준으로 바꿔 실행한다(Windows PowerShell 5는 지원하지 않는다). 아래 `~`는 `$HOME`(`C:\Users\<user>`)이고, 하위 경로는 Linux와 같다.

1. claude-settings-example repo를 찾아 `git pull`. 워킹트리가 더러우면 멈추고 보고.
2. three-man-team checkout을 **전부** 찾는다. Claude 계정 분리(`CLAUDE_CONFIG_DIR`)를 쓰면 계정 폴더마다 따로 있다.
   - bash: `ls -d ~/.claude*/skills/three-man-team`
   - pwsh: `Get-ChildItem $HOME -Directory -Force -Filter '.claude*' | ForEach-Object { Join-Path $_.FullName 'skills/three-man-team' } | Where-Object { Test-Path $_ }`
   하나도 없으면 설치하지 말고 물어봐. 찾은 checkout마다 3~4단계를 실행한다.
3. checkout의 `git status`가 깨끗한지 확인. 로컬 변경이나 미push 커밋이 있으면 멈추고 보고.
   Windows에서 거의 모든 파일이 modified로 나오면 줄바꿈(`core.autocrlf`) 문제다. reset하지 말고 `git diff --stat`·`git config core.autocrlf` 결과를 보고.
4. remote 확인:
   - `origin`이 `russelleNVy/three-man-team`이면: `git remote rename origin upstream` → `git remote add origin https://github.com/dreamwayjgs/three-man-team.git` → `git fetch origin` → `git branch -u origin/main` → `git pull --ff-only`.
   - `origin`이 이미 `dreamwayjgs/three-man-team`이면: `git pull --ff-only`만.
   - fast-forward가 안 되면 멈추고 보고.
   (이 머신에서 포크에 push할 일은 없다. push는 claude-settings-example 세션에서만 한다.)
5. 전역 규칙 빌드 (claude-settings-example 루트에서):
   - Linux·macOS·WSL: `./build-claude-md.sh`
   - Windows: `pwsh -File .\build-rules.ps1`. bash 셸에서 실행 중이어도(예: Claude Code의 Git Bash) ps1을 쓴다.
     pwsh 7이 없으면 멈추고 보고. 실행 정책 오류가 나면 `-ExecutionPolicy Bypass`를 붙인다.
   - Foreman 질문이 나오면 나에게 물어봐.
   - 빌드 마지막 단계가 `agent-skills.txt`의 스킬을 `npx skills add`로 `~/.agents/skills`에 설치한다 (node·네트워크 필요, Claude 불필요). `npx`가 없으면 빌드가 아무것도 쓰지 않고 실패하고, 설치가 실패하면 규칙은 써진 뒤 멈춘다. 어느 쪽이든 멈추고 출력 전체를 보고. `build-rules.ps1 -TargetHome <다른 경로>`는 규칙·템플릿만 그 경로에 쓰고 스킬 설치는 건너뛴다(격리 검증용). 예전 방식(Claude 플러그인 캐시 복사)은 없어졌으니 `~/.config/opencode/skills`·`~/.config/crush/skills`에 남은 caveman·ponytail 사본이 있으면 목록만 보고하고 지우지 않는다.
   - caveman (v3 2026-10-13, v4.0.1 2026-10-14): Claude 머신이면 빌드 전에 `claude plugin update caveman@caveman`을 실행하고, 설치된 플러그인 버전이 `agent-skills.txt`의 caveman ref(`v<버전>`)와 같은지 확인한다. 플러그인이 더 새 버전이면 멈추고 보고 — 매니페스트 ref는 소유자 세션(claude-settings-example)에서만 올린다. `~/.claude/settings.json`(계정 분리·워커 폴더 포함)의 `hooks`에 `caveman-activate.js`·`caveman-mode-tracker.js`를 부르는 **activation·mode-tracker 훅 등록**이 있으면 지운다 — 플러그인 manifest가 같은 훅을 등록하므로 중복이다 (statusline 설정과 `~/.claude/hooks/` 파일은 건드리지 않는다). 그 뒤 `~/.claude/plugins/cache/caveman/caveman/<version>/src/hooks/`에서 `caveman-activate.js`·`caveman-config.js`·`caveman-mode-tracker.js`·`caveman-stats.js`·`caveman-statusline.sh`·`caveman-statusline.ps1`를 `~/.claude/hooks/`에 덮어쓴다 (statusline 배지용).
   - 빌드는 계정 폴더 중 `~/.claude`·`~/.claude-personal`에만 CLAUDE.md를 쓴다. 다른 계정 폴더(예: `~/.claude-admin`)가 있으면 `~/.claude/CLAUDE.md`를 그 폴더에 복사한다.
   - OpenCode가 설치된 머신(`opencode --version`이 2.x)이면 caveman은 `opencode-v2-migration.md` 절차 4(upstream 파일 복사, 설치기 금지·옛 임시 패치 `index.js` 삭제, `~/.config/opencode/AGENTS.md`에 `<!-- caveman-begin -->` 블록이 있으면 지우지 말고 보고), ponytail은 `opencode-plugins/ponytail-v2/README.md` 설치 절차로 어댑터와 의존 파일(`node_modules/@dietrichgebert/ponytail`)을 맞추고, `opencode-v2-migration.md`의 "검증" 절(서버 로그 `loading plugin`, 역할 없는 run에 플래그 없음)을 돌린다. OpenCode가 없으면 생략.
6. 옛 사본 정리: 아래 경로에 `OPERATOR.md`가 있으면 삭제한다. 빌드가 더는 이 파일을 쓰지 않고, 이제 포크의 `templates/optional/OPERATOR.md`가 원본이다.
   `~/.claude/templates/`, `~/.config/opencode/templates/`, `~/.omp/agent/templates/`, `~/.config/crush/templates/`
   omp 마켓플레이스 플러그인 정리(2026-10-13): `omp plugin list`에 `ponytail@ponytail`·`caveman@...` 같은 스킬 플러그인이 있으면 `omp plugin uninstall <id>`로 지운다. 스킬 소스는 `agent-skills.txt` 하나이고, omp 플러그인 사본이 있으면 `~/.agents/skills`와 name collision을 내며 bare 이름을 가져간다. `omp plugin doctor`의 `package_manifest: Not created yet`는 정보성 경고라 그대로 둔다.
   qmd 폐기(2026-10-13, 세션 규칙에서 제외): Claude Code에 `qmd@qmd` 플러그인이 있으면 `claude plugin disable qmd@qmd`로 끄고, `~/.claude/settings.json`의 `permissions.allow`에서 `mcp__plugin_qmd_qmd__*` 항목을 지운다. 계정 분리 폴더(`~/.claude-personal` 등)와 워커 폴더(`~/.claude-worker`)의 `settings.json`도 같은 항목을 확인한다. `enabledPlugins`의 `"qmd@qmd": false`와 `extraKnownMarketplaces`의 `qmd`는 비활성 기록이라 남겨도 된다. `~/.agents/skills/qmd`가 있으면 삭제한다(build가 더는 만들지 않는 잔여물). qmd CLI 자체와 인덱스는 지우지 않는다 — 레포 밖 문서 검색용으로 `~/ops/CLAUDE.md`에서만 안내한다.
7. 검증:
   - checkout마다 `git -C <checkout> remote -v`: origin = 포크, upstream = 원본
   - checkout마다 `git -C <checkout> status -sb`: `main...origin/main`, ahead/behind 없음
   - `templates/project-folder/ROGER.md`, `templates/optional/OPERATOR.md` 존재
   - 생성된 전역 규칙 파일(이 harness 것)에 `templates/optional/OPERATOR.md` 문자열이 있음
   - repo `agent-skills.txt`의 각 줄(repo, ref, 스킬 이름들)에 대해 `~/.agents/skills/<이름>/SKILL.md`가 있고 `~/.agents/.skill-lock.json`의 그 스킬 `ref`가 줄의 ref와 같음. 개수·버전을 따로 외우지 말고 매니페스트에서 읽는다. `~/.agents/skills/qmd` 없음
   - 생성된 전역 규칙 파일 네 개와 `~/.claude/settings.json`에 `qmd` 문자열이 없음(`enabledPlugins`의 `"qmd@qmd": false`는 허용)
   - `omp plugin list`에 매니페스트 스킬과 겹치는 플러그인(ponytail·caveman·karpathy 계열)이 없고, `omp skill list` 출력에 `name collision`이 없음. 다른 omp 플러그인은 있어도 된다
   - Claude 머신: 설치된 caveman 플러그인 버전이 매니페스트 caveman ref와 같음, `~/.agents/skills/caveman/SKILL.md`에 lite/full 강도 표가 없음, `settings.json`들에 caveman activation·mode-tracker 훅 등록이 없음(statusLine은 그대로), 토큰 최적화 표의 caveman 열이 `caveman`
   결과를 표로 보고.
```
