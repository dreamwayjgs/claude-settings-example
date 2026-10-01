# 머신 전환 프롬프트 — three-man-team 포크로 전환

각 머신에서 한 번, 역할 없는 세션에 붙여 넣는다. harness는 무엇이든 된다.

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 머신의 three-man-team checkout을 개인 포크로 전환하고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐.
Windows면 PowerShell 기준으로 바꿔 실행한다. 아래 `~`는 `$HOME`(`C:\Users\<user>`)이고, 하위 경로는 Linux와 같다.

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
     pwsh 7이 없으면 `powershell -ExecutionPolicy Bypass -File .\build-rules.ps1`. 실행 정책 오류가 나면 pwsh에도 `-ExecutionPolicy Bypass`를 붙인다.
   - Foreman 질문이 나오면 나에게 물어봐.
   - 빌드는 계정 폴더 중 `~/.claude`·`~/.claude-personal`에만 CLAUDE.md를 쓴다. 다른 계정 폴더(예: `~/.claude-admin`)가 있으면 `~/.claude/CLAUDE.md`를 그 폴더에 복사한다.
6. 옛 사본 정리: 아래 경로에 `OPERATOR.md`가 있으면 삭제한다. 빌드가 더는 이 파일을 쓰지 않고, 이제 포크의 `templates/optional/OPERATOR.md`가 원본이다.
   `~/.claude/templates/`, `~/.config/opencode/templates/`, `~/.omp/agent/templates/`, `~/.config/crush/templates/`
7. 검증:
   - checkout마다 `git -C <checkout> remote -v`: origin = 포크, upstream = 원본
   - checkout마다 `git -C <checkout> status -sb`: `main...origin/main`, ahead/behind 없음
   - `templates/project-folder/ROGER.md`, `templates/optional/OPERATOR.md` 존재
   - 생성된 전역 규칙 파일(이 harness 것)에 `templates/optional/OPERATOR.md` 문자열이 있음
   결과를 표로 보고.
```
