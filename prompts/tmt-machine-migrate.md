# 머신 전환 프롬프트 — three-man-team 포크로 전환

각 머신에서 한 번, 역할 없는 세션에 붙여 넣는다. harness는 무엇이든 된다.

```
이 머신의 three-man-team checkout을 개인 포크로 전환하고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐.

1. claude-settings-example repo를 찾아 `git pull`. 워킹트리가 더러우면 멈추고 보고.
2. three-man-team checkout을 찾는다(기본 `~/.claude/skills/three-man-team`). 없으면 설치하지 말고 물어봐.
3. checkout의 `git status`가 깨끗한지 확인. 로컬 변경이나 미push 커밋이 있으면 멈추고 보고.
4. remote 확인:
   - `origin`이 `russelleNVy/three-man-team`이면: `git remote rename origin upstream` → `git remote add origin https://github.com/dreamwayjgs/three-man-team.git` → `git fetch origin` → `git branch -u origin/main` → `git pull --ff-only`.
   - `origin`이 이미 `dreamwayjgs/three-man-team`이면: `git pull --ff-only`만.
   - fast-forward가 안 되면 멈추고 보고.
   (이 머신에서 포크에 push할 일은 없다. push는 claude-settings-example 세션에서만 한다.)
5. 전역 규칙 빌드: bash는 `./build-claude-md.sh`, Windows는 `pwsh -File ./build-rules.ps1`. Foreman 질문이 나오면 나에게 물어봐.
6. 옛 사본 정리: 아래 경로에 `OPERATOR.md`가 있으면 삭제한다. 빌드가 더는 이 파일을 쓰지 않고, 이제 포크의 `templates/optional/OPERATOR.md`가 원본이다.
   `~/.claude/templates/`, `~/.config/opencode/templates/`, `~/.omp/agent/templates/`, `~/.config/crush/templates/`
7. 검증:
   - `git -C <checkout> remote -v`: origin = 포크, upstream = 원본
   - `git -C <checkout> status -sb`: `main...origin/main`, ahead/behind 없음
   - `templates/project-folder/ROGER.md`, `templates/optional/OPERATOR.md` 존재
   - 생성된 전역 규칙 파일(이 harness 것)에 `templates/optional/OPERATOR.md` 문자열이 있음
   결과를 표로 보고.
```
