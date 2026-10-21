# Python 제안 — uv 기반

AI의 Python 작업에 uv를 사용하도록 안내하는 `~/.config/machine-context/local.md` 예시다. OS가 관리하는 Python이 있어도 적용할 수 있으며, 기존 Python 설치를 제거할 필요는 없다.

## local.md 예시

```markdown
## Python

- Use uv for everything Python: `uv run`, `uv venv`, `uv pip`, `uv python install`, `uvx` for tools.
- Do not call bare `python`/`python3`/`py`/`pip`.
- Do not modify OS-managed Python installations or install packages into their environments. (Linux)
```

"uv로 설치된 걸 써라" 한 줄로는 부족하다. 에이전트는 습관대로 bare `python`·`pip`을 부르므로 행동 단위로 적는다.

## 선택 사항: Windows에서 사용자용 Python을 uv로 통일하기

아래는 기존 사용자용 Python을 정리하려는 경우에만 수행한다. 위 실행 규칙을 적용하는 데 필요한 절차가 아니다. Linux의 OS 관리 Python은 제거하거나 링크를 바꾸지 않는다. 버전과 경로는 해당 머신에서 확인하고, 제거 대상은 소유자 승인 후 처리한다.

1. **조사:** `Get-Command python,python3,py,pip -All`, `uv python list --only-installed`, `py --list-paths`, 설치된 프로그램 목록. uv 설치 방식은 `%LOCALAPPDATA%\uv\uv-receipt.json`으로 확인한다.
2. **쓰는 도구 확인:** 전역·사용자 site-packages(`%APPDATA%\Python`)에 poetry·cookiecutter 같은 CLI가 있으면 계속 쓸지 소유자에게 묻는다. 쓰면 `uv tool install`, 가끔 쓰면 `uvx`로 실행한다. pypdf·openpyxl 같은 라이브러리는 `uv run --with <pkg>`로 대체한다.
3. **제거 (Windows):**
   - 사용자 범위(일반 권한): `%APPDATA%\Python`, Store 스텁(suggestions-windows.md), 사용자 PATH의 Python 경로.
   - 시스템 범위(관리자): Python 설치본, Python Launcher, 시스템 PATH의 Python 경로.
4. **기본 인터프리터:** bare `python`이 필요하면 `uv python install <ver> --default`로 `~/.local/bin`에 shim을 만든다. 실험 기능이라 경고가 나온다.
5. **검증:** `Get-Command python,python3,py,pip -All`가 uv shim만 가리키는지, `uv python list`에 레지스트리 경고가 없는지 확인한다.

### 함정 (Windows)

- **chocolatey와 MSI의 버전 불일치:** chocolatey 패키지 버전(예: 3.12.0)과 실제 설치본(예: 3.12.10)이 다르면 `choco uninstall`이 파일만 지우고 MSI 등록을 남긴다. 그러면 `HKLM\Software\Python\PythonCore\<ver>`도 남아서, uv가 `Failed to inspect Python interpreter from registry` 경고를 계속 낸다. 설치된 프로그램 목록의 각 MSI 제품 코드에 대해 관리자 권한으로 `msiexec /x {GUID} /qn /l*v <log>`를 실행한 뒤 그 레지스트리 키를 지운다.
- **MSI가 `AppSearch`에서 죽는 경우:** 로그에 `Internal Exception during install operation: 0xc00000fd`(스택 오버플로)가 나오고 1603으로 끝나면 제거·복구·재설치 모두 같은 단계에서 막힌다. 파일이 이미 없다면 `HKLM\Software\Python\PythonCore`만 지워 uv 경고를 없애고, 설치된 프로그램 목록 항목은 남겨 둔다. 표시만 남을 뿐 동작에는 영향이 없다. MSDT 기반 "프로그램 설치 및 제거 문제 해결사"는 Windows 11 24H2 이후 실행되지 않을 수 있다.
- **Python Launcher는 여러 개일 수 있다:** 버전별로 따로 등록돼 있을 수 있어서 각각 `msiexec /x`로 지워야 한다. 다 지운 뒤 `HKCU\Software\Python\PyLauncher`가 남아 있으면 삭제한다.
