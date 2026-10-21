# Windows 머신 제안

Windows 머신의 `~/.config/machine-context/local.md`에 넣을 만한 항목과 셋업 중 겪은 함정이다. 그대로 복사하지 말고 그 머신에서 확인한 것만 옮긴다.

## local.md 예시

```markdown
## Shell

- Default shell: pwsh (PowerShell 7). Windows PowerShell 5 is not used.
```

## 함정

- **PATH가 오래된 값으로 남음:** 세션을 시작한 뒤 설치한 도구(gh·glab 등)는 에이전트 셸에 보이지 않는다. 없다고 판단하기 전에 PATH를 다시 읽는다.
  `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`
- **mode만 바뀐 diff:** `git diff`가 내용 없이 `old mode 100755`/`new mode 100644`만 보이면 그 repo에 `git config core.fileMode false`를 설정한다. Git for Windows로 clone하면 기본값이 false다. WSL 등 다른 git으로 만든 checkout에서 생긴다. repo 파일의 실행 비트는 바꾸지 않는다.
- **관리자 권한:** 에이전트 셸은 보통 관리자 권한이 아니다. 시스템 전체 설치본(MSI·chocolatey) 제거나 HKLM·시스템 PATH 수정은 명령을 소유자에게 넘겨 관리자 pwsh에서 실행하게 한다.
- **Microsoft Store 별칭:** `%LOCALAPPDATA%\Microsoft\WindowsApps`의 `python.exe`·`python3.exe`는 0바이트 스토어 스텁이다. 파일을 지워도 업데이트 때 다시 생길 수 있으니 설정 > 앱 > 고급 앱 설정 > 앱 실행 별칭에서 끈다.
- **Claude Code PowerShell 도구 오탐:** 한 명령 안에 `Remove-Item`과 경로처럼 보이는 문자열(예: 정규식 `'foo-(a|b)\.js'`)이 함께 있으면 보호 경로 삭제로 오인해 명령 전체를 막는다. 삭제 명령은 따로 실행한다.
- **Claude 프로젝트 slug:** 절대경로의 영숫자가 아닌 문자가 모두 `-`로 바뀐다(`:`·`\`·`_` 포함). 직접 계산하지 말고 `~/.claude*/projects/` 목록에서 찾는다.
