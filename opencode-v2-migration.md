# OpenCode V1 → V2 마이그레이션

이 세팅 기준으로 V2 전환에 필요한 것만 정리한다. 공식 가이드: https://opencode.ai/v2/docs/migrate-v1/

## 머신별 상태

| 머신 | 버전 | 비고 |
|---|---|---|
| aribaragi (서버, 8GB) | V2 2.0.20 | 2026-09-30 전환 완료 |
| 로컬 WSL (32GB) | V1 1.18.33 | 보류. 신규 셋업만 V2 |

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
| caveman | `plugins/caveman/plugin.js` (V1) | `opencode-plugins/caveman-v2/` 임시 패치 (기존 upstream helper·스킬 필요) |
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
3. V2 설치 (curl 설치기가 `~/.opencode/bin/opencode`를 덮어씀):
   ```bash
   curl -fsSL https://opencode.ai/v2/install | bash
   opencode --version   # 2.x
   ```
4. caveman — `opencode-plugins/caveman-v2/README.md` 설치 절차. 기존 helper·스킬을 보존하고
   repo의 `index.js`·`package.json`을 설치한다. 2026-10-08 upstream `main` (`2e08b91`)은
   V1 API이며 설치기도 V2 `index.js`를 생성하지 않는다. upstream 설치기 재실행만으로
   전환하지 말 것. 이 패치는 `/caveman` prompt 파싱을 생략하며 역할 모드는 스킬 로드로 적용한다.
5. ponytail — `opencode-plugins/ponytail-v2/README.md` 설치 절차.
6. config — `opencode.v2.json.example`을 `~/.config/opencode/opencode.json`으로. 기존 `opencode.jsonc`는 제거 (둘 다 두지 말 것).
7. caveman·Ponytail 기본 off 유지 확인: `~/.config/{caveman,ponytail}/config.json` = `{"defaultMode":"off"}` (`claude-settings.md` §5-1).

## 검증

- `opencode plugin list` → caveman·ponytail 둘 다 failed 없이 표시
- 역할 없는 `opencode run` → `~/.config/opencode/.caveman-active`·`.ponytail-active` 생성 안 됨, 응답 평문
- 역할 세션(예: 밥) → caveman·ponytail full 로드
- 1일 이상 사용 후 위 표와 같은 방식으로 RSS 측정: `ps -eo pid,rss,etime,args | grep '[o]pencode'`

## 미확인

- V1 세션 기록이 V2에서 보이는지
- 서버 V2의 실제 응답 톤 (크레딧 부족으로 모델 호출 실패, 플러그인·플래그 수준만 확인)

## 롤백

```bash
cp ~/.opencode/bin/opencode-v1 ~/.opencode/bin/opencode
rm ~/.config/opencode/opencode.json   # V2 config, V1 백업은 .jsonc
tar xzf ~/opencode-v1-backup-<date>.tgz -C ~
```
