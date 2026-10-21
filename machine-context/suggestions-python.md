# Python 제안 — uv 기반

Python을 uv 하나로 통일한 머신의 `~/.config/machine-context/local.md` 예시와 전환 절차다. 버전과 경로는 그 머신에서 확인한 값으로 바꾼다.

## local.md 예시

```markdown
## Python

- Use uv for everything Python: `uv run`, `uv venv`, `uv pip`, `uv python install`, `uvx` for tools.
- Do not call bare `python`/`python3`/`py`/`pip`.
- uv is the only Python on this machine (installed via the official astral installer, `uv self update`). Bare `python`/`python3` are uv shims in `~/.local/bin` (`uv python install <ver> --default`); there is no `py` or global `pip`.
```

"uv로 설치된 걸 써라" 한 줄로는 부족하다. 에이전트는 습관대로 bare `python`·`pip`을 부르므로 행동 단위로 적는다.

## 전환 절차

1. **조사:** `Get-Command python,python3,py,pip -All`(Linux는 `which -a`), `uv python list --only-installed`, `py --list-paths`, 설치된 프로그램 목록. uv 설치 방식은 `%LOCALAPPDATA%\uv\uv-receipt.json`(Linux `~/.config/uv/uv-receipt.json`)으로 확인한다.
2. **쓰는 도구 확인:** 전역·사용자 site-packages(`%APPDATA%\Python`)에 poetry·cookiecutter 같은 CLI가 있으면 계속 쓸지 소유자에게 묻는다. 쓰면 `uv tool install`, 가끔 쓰면 `uvx`로 실행한다. pypdf·openpyxl 같은 라이브러리는 `uv run --with <pkg>`로 대체한다.
3. **제거 (Windows):**
   - 사용자 범위(일반 권한): `%APPDATA%\Python`, Store 스텁(suggestions-windows.md), 사용자 PATH의 Python 경로.
   - 시스템 범위: Python 설치본·Python Launcher는 MSI이므로 소유자가 먼저 설정 > 앱에서 제거하고, 에이전트는 남은 흔적(`C:\PythonXY`, PATH, `HKLM\Software\Python\PythonCore`)만 확인한다 (suggestions-windows.md).
4. **기본 인터프리터:** bare `python`이 필요하면 `uv python install <ver> --default`로 `~/.local/bin`에 shim을 만든다. 실험 기능이라 경고가 나온다.
5. **검증:** `Get-Command python,python3,py,pip -All`가 uv shim만 가리키는지, `uv python list`에 레지스트리 경고가 없는지 확인한다.

## 함정 (Windows)

- **chocolatey로 깐 Python:** chocolatey 패키지 버전(예: 3.12.0)과 실제 설치본(예: 3.12.10)이 다르면 `choco uninstall`은 파일만 지우고 MSI 등록을 남긴다. `choco uninstall`보다 설정 > 앱에서 제거하는 쪽을 먼저 쓴다.
- **흔적 확인:** 제거 후 `HKLM\Software\Python\PythonCore\<ver>`가 남으면 uv가 `Failed to inspect Python interpreter from registry` 경고를 계속 낸다. 남은 흔적은 소유자에게 보고하고, 지울지 정한다.
