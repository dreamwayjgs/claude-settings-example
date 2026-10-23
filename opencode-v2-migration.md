# OpenCode V1 → V2 마이그레이션

이 세팅 기준으로 V2 전환에 필요한 것만 정리한다. 공식 가이드: https://opencode.ai/v2/docs/migrate-v1/

## 머신별 상태

| 머신 | 버전 | 비고 |
|---|---|---|
| aribaragi (서버, 8GB) | V2 2.0.20 | 2026-09-30 전환 완료 |
| 로컬 WSL (32GB) | V2 2.0.27 | 2026-10-13 전환 완료 (V1 1.18.35에서, 백업 `~/opencode-v1-backup-2026-10-13.tgz`·`~/.opencode/bin/opencode-v1`) |

## 왜 V2

Bun → Node 런타임 전환으로 메모리 개선 (공식 명시 사유). 2026-09-30 실측 RSS:

| | 프로세스 | 합계 | 평균 |
|---|---|---|---|
| V1 로컬 | 2 | 2327 MB | 1164 MB |
| V2 서버 | 6 | 1462 MiB | 244 MiB |

동일 조건 아님 — 호스트 RAM(8GB는 회수 적극적), uptime 미기록, RSS는 공유 페이지 중복 계산. V2는 상주 서버 1개 + 클라이언트 구조라 평균보다 합계 비교가 낫다. 세션 3배에 합계가 더 작다는 방향만 신뢰.

## 이 세팅에서 바뀌는 것

공식 가이드의 나머지(permissions·providers·mcp·agents·tui.json 등)는 이 세팅에 해당 없음.

| 항목 | V1 | V2 |
|---|---|---|
| config | `opencode.json.example` (`plugin`) | `opencode.v2.json.example` (`plugins`, 로컬 플러그인 폴더) |
| caveman | `plugins/caveman/plugin.js` (V1) | upstream v4.0.1 `src/plugins/opencode/` (`server.js`가 V2 진입점). 임시 패치는 2026-10-14 철수 |
| ponytail | npm `@dietrichgebert/ponytail` (V1 API, V2에서 크래시) | `opencode-plugins/ponytail-v2/` 임시 패치 |
| `commands/*.md` | `description`만 사용 | 변경 없음 (`subtask` 미사용) |
| `AGENTS.md`·스킬 | | 변경 없음 |

## 절차

1. 실행 중인 V1 세션을 모두 끝낸다 (config 교체 후 V1이 V2 형식을 읽으면 깨짐).
2. 백업 — 가이드에 롤백 절차 없음:
   ```bash
   tar czf ~/opencode-v1-backup-$(date +%F).tgz -C ~ .config/opencode .local/share/opencode .opencode/bin
   cp ~/.opencode/bin/opencode ~/.opencode/bin/opencode-v1
   ```
3. V2 설치 (curl 설치기가 `~/.opencode/bin/opencode`를 덮어씀). 최신 버전 조회(`opencode.ai/update/api`)가 503을 내면 버전을 명시한다 (npm registry에서 받는다):
   ```bash
   curl -fsSL https://opencode.ai/v2/install | bash                      # 최신
   curl -fsSL https://opencode.ai/v2/install | bash -s -- --version 2.0.27  # 고정
   opencode --version   # 2.x
   ```
4. caveman — upstream 파일만 복사한다. **upstream 설치기(`installer/install.js`)는 쓰지 않는다**:
   `~/.config/opencode/AGENTS.md`에 상시 caveman ruleset 블록을 넣고 skills·agents까지 깔아
   기본 off 정책과 `~/.agents/skills` 단일 경로를 깬다. ref는 `agent-skills.txt`의 caveman ref와 같게.
   ```bash
   git clone -q --depth 1 --branch v4.0.1 https://github.com/JuliusBrussee/caveman /tmp/caveman-src
   S=/tmp/caveman-src; P=~/.config/opencode/plugins/caveman; mkdir -p $P ~/.config/opencode/commands
   cp $S/src/plugins/opencode/{plugin.js,server.js,package.json} $P/
   cp $S/src/hooks/caveman-config.js $P/caveman-config.cjs
   cp $S/src/hooks/caveman-parse.js $P/caveman-parse.cjs
   rm -f $P/index.js   # 옛 임시 패치 진입점
   cp $S/src/plugins/opencode/commands/*.md ~/.config/opencode/commands/
   ```
   ```powershell
   git clone -q --depth 1 --branch v4.0.1 https://github.com/JuliusBrussee/caveman $env:TEMP\caveman-src
   $S = "$env:TEMP\caveman-src"; $P = "$HOME\.config\opencode\plugins\caveman"
   New-Item -ItemType Directory -Force $P, "$HOME\.config\opencode\commands" | Out-Null
   Copy-Item "$S\src\plugins\opencode\plugin.js", "$S\src\plugins\opencode\server.js", "$S\src\plugins\opencode\package.json" $P
   Copy-Item "$S\src\hooks\caveman-config.js" "$P\caveman-config.cjs"
   Copy-Item "$S\src\hooks\caveman-parse.js" "$P\caveman-parse.cjs"
   Remove-Item "$P\index.js" -ErrorAction SilentlyContinue
   Copy-Item "$S\src\plugins\opencode\commands\*.md" "$HOME\.config\opencode\commands"
   ```
   ruleset 본문은 `~/.config/opencode/skills`가 없으므로 주입되지 않고 배너+thesis 한 줄만 들어간다.
   역할 세션은 `~/.agents/skills/caveman/SKILL.md`를 직접 읽으므로 영향 없음.
   설치 후 백그라운드 서비스(`opencode serve --service`)를 재시작해야 새 플러그인을 확실히 읽는다.
   재시작은 모든 설치·설정을 마친 뒤 마지막에 한 번 한다. OpenCode 세션 안에서 재시작하면 그 세션이 끊긴다(`Command cancelled`). 재개하면 앞 단계를 반복하지 말고 서비스 상태·`opencode debug config`·서버 로그의 plugin 로드 기록부터 확인한다.
5. ponytail — `opencode-plugins/ponytail-v2/README.md` 설치 절차.
6. config — `opencode.v2.json.example`을 `~/.config/opencode/opencode.json`으로. 기존 `opencode.jsonc`는 제거 (둘 다 두지 말 것).
7. caveman·Ponytail 기본 off 유지 확인: `~/.config/{caveman,ponytail}/config.json` = `{"defaultMode":"off"}` (`claude-settings.md` §5-1).

## Windows TUI 탭

Windows TUI에서 세션 탭 스트립이 뜨면 `~/.config/opencode/cli.json`에
`{"tabs": {"mode": "off"}}`. `auto`는 Herdr 안에서는 숨지만(그래서 Linux/Herdr에선 안 뜸)
Windows 터미널에선 뜨는 경우가 있다. build는 `cli.json`을 건드리지 않으므로 머신별 수동 설정.

## 검증

- (즉시) 플러그인 로드: `opencode debug config`에 `plugins` 두 개가 보이고(출력의 최상위 형태는 버전마다 다르다 — 2.1.3은 JSON 배열. 객체로 가정하지 말고 `grep -A5 '"plugins'`처럼 형태 무관하게 찾는다), 서버 로그 `~/.local/share/opencode/log/opencode.log`에 `loading plugin id=.../plugins/caveman`·`.../plugins/ponytail`이 찍힌다. **`opencode plugin list`는 2.0.27에서 `cli.json`(`plugin add`로 등록한 것)만 보여 주므로 config 경로 플러그인 확인에 쓸 수 없다.**
- (행동, 승인 필요) 역할 없는 `opencode run` → `~/.config/opencode/.caveman-active`·`.ponytail-active` 생성 안 됨, 응답 평문
- (행동, 역할 세션 별도 승인) 역할 세션(예: 밥) → caveman·ponytail full 로드
- (지연) 1일 이상 사용 후 위 표와 같은 방식으로 RSS 측정: `ps -eo pid,rss,etime,args | grep '[o]pencode'`

### 로컬 WSL 실측 — 2026-10-13, V2 2.0.27, `openai/gpt-5-nano`, 새 세션마다 `opencode run`

| 시나리오 | 결과 |
|---|---|
| 역할 없는 평문 요청 | 응답 `ok`, 플래그 파일 둘 다 없음 |
| 스킬 목록 질의 | `~/.agents/skills`의 caveman 계열·ponytail 계열·karpathy-guidelines·qmd·find-skills 전부 보임 → V2가 `~/.agents/skills`를 스캔한다. ponytail 어댑터의 `editor.get` 가드 덕에 중복 경고 없음 |
| `/ponytail` (기본 off, 플래그 없음) | `.ponytail-active=full`, 응답에 Ponytail 서명(Skipped/Risk 꼬리) |
| `/ponytail off` | `.ponytail-active=off` |
| 플래그 `full`·`off`·없음에서 "시스템 프롬프트에 `PONYTAIL MODE ACTIVE`가 있나" | full → 있음(서명 포함 응답), off·없음 → `no` |

확인 후 플래그 파일은 삭제해 기본 off로 되돌렸다. 질문에 'ponytail'만 쓰면 스킬 설명 때문에 항상 yes가 나오므로 주입 마커로 물어야 한다.

## 미확인

- V1 세션 기록이 V2에서 보이는지
- 서버 V2의 실제 응답 톤 (크레딧 부족으로 모델 호출 실패, 플러그인·플래그 수준만 확인)
- caveman upstream 4.0.1 어댑터의 서브에이전트 가드(`parentID` 세션은 모드 전환 무시)는 코드로만 확인, 실측 안 함.
- 서버에 4.0.1 어댑터 적용 여부 (절차 4).

## 롤백

```bash
cp ~/.opencode/bin/opencode-v1 ~/.opencode/bin/opencode
rm ~/.config/opencode/opencode.json   # V2 config, V1 백업은 .jsonc
tar xzf ~/opencode-v1-backup-<date>.tgz -C ~
```
