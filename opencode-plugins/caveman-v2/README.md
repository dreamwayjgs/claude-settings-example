# caveman OpenCode V2 임시 패치

> **임시조치.** upstream `JuliusBrussee/caveman`이 OpenCode V2 플러그인 API를 지원할 때까지만 유지한다.

## 왜 필요하나

2026-10-08 확인한 upstream `main` (`2e08b9177c07bb7249a8a2d1a6758e5db281d002`)의
`src/plugins/opencode/plugin.js`는 V1 `chat.message`·`experimental.chat.system.transform`
훅을 사용한다. `installer/install.js`도 V1 `plugin.js`를 복사하며 V2 `index.js`를 생성하지 않는다.
따라서 upstream 설치기 재실행만으로 V2 전환이 완료되지 않는다.

- upstream: https://github.com/JuliusBrussee/caveman
- V2 API: https://opencode.ai/v2/docs/build/plugins

## 이 패치가 하는 일

- V1 훅 객체 대신 `id`·`setup(ctx)` 진입점 사용.
- `ctx.event.subscribe`의 `session.created`에서 머신 기본 모드 플래그 재설정.
- `ctx.session.hook('context', ...)`에서 활성 모드의 ruleset 주입.
- 설치된 upstream `caveman-config.cjs`를 읽어 모드·플래그·ruleset 처리 재사용.
- 로컬 설치본 `~/.config/opencode/plugins/caveman/index.js`와 동일한 사본 보관.

**전체 upstream 기능의 이식은 아니다.** `/caveman` 입력을 파싱하는 `prompt` 훅과
`compaction`·`generate`·`title` 훅은 등록하지 않는다. 역할별 모드는 전역 규칙에 따라
스킬 로드로 적용한다. 머신 기본 모드는 `off` 유지.

## 설치 (기존 caveman 설치에 덮어쓰기)

이 폴더만 복사하면 로드되지 않는다. 먼저 대상 머신에 기존 caveman 설치의
`~/.config/opencode/plugins/caveman/caveman-config.cjs`와
`~/.config/opencode/skills/` 아래 caveman 스킬들이 있어야 한다.
의존 파일이 없으면 설치를 멈춘다. upstream 업데이트 시 helper 호환성도 다시 확인한다.

Windows (pwsh 7, 이 repo 루트에서):

```powershell
$base = if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'opencode' } else { Join-Path $HOME '.config/opencode' }
$dest = Join-Path $base 'plugins/caveman'
if (!(Test-Path (Join-Path $dest 'caveman-config.cjs'))) { throw '기존 caveman helper 설치 필요' }
# 기존 index.js·package.json은 먼저 repo 밖에 백업한다.
Copy-Item ./opencode-plugins/caveman-v2/index.js, ./opencode-plugins/caveman-v2/package.json -Destination $dest
```

Linux·macOS·WSL (이 repo 루트에서):

```sh
base="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
dest="$base/plugins/caveman"
test -f "$dest/caveman-config.cjs" || { echo '기존 caveman helper 설치 필요'; exit 1; }
# 기존 index.js·package.json은 먼저 repo 밖에 백업한다.
cp opencode-plugins/caveman-v2/index.js opencode-plugins/caveman-v2/package.json "$dest/"
```

사용 중인 `opencode.json(c)`의 `plugins`에 `"./plugins/caveman"`을 지정한다
(`opencode.v2.json.example`). 기존 V1 `./plugins/caveman/plugin.js` 지정은 중복 로드하지 않는다.
기존 helper·스킬·커맨드·설정의 무관한 항목은 보존한다.

## 검증·철수 조건

- `opencode plugin list`에서 caveman이 failed 없이 표시되는지 확인.
- `~/.config/caveman/config.json`의 `defaultMode`가 `off`인지 확인.
- 역할 없는 세션에서 `.caveman-active`가 생성되지 않는지 확인.
- 역할 세션에서는 지정된 스킬을 로드해 모드 적용 확인.
- upstream의 V2 진입점·훅·설치기를 확인하고 실제 설치 검증까지 끝나면 이 패치를 철수한다.
  그때 이 디렉터리·마이그레이션 문서·설정 예제를 함께 갱신한다.
