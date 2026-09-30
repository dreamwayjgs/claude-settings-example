# ponytail OpenCode V2 임시 패치

> **임시조치.** upstream `DietrichGebert/ponytail`에서 OpenCode V2를 공식 지원할 때까지만 유지한다.
> upstream이 V2를 지원하면 이 디렉터리를 삭제하고 `opencode.json`에서 npm 플러그인으로 복귀할 것.

## 왜 필요하나

upstream의 OpenCode 플러그인(`ponytail.mjs`)은 V1 API 기준이다. V1 `config` 훅에서
`ctx.config.command` / `ctx.config.skills.paths`를 직접 변이하는데, V2에는 mutable
global config(`ctx.config`)가 없다. 그대로 두면 서버 기동 시 플러그인 활성화 단계에서

```text
TypeError: undefined is not an object (evaluating 'ctx.config.command')
```

로 실패한다. V2 마이그레이션 가이드가 정한 교체처는 도메인 transform이다
(`ctx.command.transform`, `ctx.skill.transform`).
참조: https://opencode.ai/v2/docs/migrate-v1/ ,
https://opencode.ai/v2/docs/build/plugins/migrate-v1/

## 이 패치가 하는 일 (`index.js`)

- `ctx.config` 변이 삭제 → `ctx.command.transform(editor.add(...))`로 6개 커맨드 등록
  (`ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`).
  `ponytail` 실행 시 모드 저장 + 템플릿 `$ARGUMENTS` 치환 후 `ctx.session.prompt`로 제출.
- `skills.paths.push` 삭제 → `ctx.skill.transform`으로 6개 스킬 등록.
- `createRequire(import.meta.url)` → `createRequire(target)` + 직접 eval 로딩.
  Bun 컴파일 바이너리는 on-disk `require()`를 거부하므로 caveman과 같은 패턴 사용.
- `prompt` + `context/compaction/generate/title` 훅은 그대로 유지.
- 원본 소스: `~/.config/opencode/plugins/ponytail/index.js`와 byte-identical 유지.
  고칠 때는 설치본을 고치고 검증한 뒤 여기로 복사한다.

## 설치 (다른 머신 / 다른 agent)

```sh
cp opencode-plugins/ponytail-v2/index.js ~/.config/opencode/plugins/ponytail/index.js
```

`~/.config/opencode/opencode.json`의 `plugins`에 `"./plugins/ponytail"`이 있어야 한다.
확인:

```sh
opencode plugin list   # ponytail failed 없이 표시되면 OK
```

## 철수 조건

- upstream ponytail 릴리스가 OpenCode V2 플러그인 API(`setup(ctx)` + domain transform)를
  지원하면: 이 디렉터리 삭제, `opencode.json`을 npm 패키지 지정으로 복귀,
  `opencode.json.example`도 함께 되돌린다.
