# 프로젝트 동기화 프롬프트 — 역할 파일을 포크 템플릿에 맞추기

이미 three-man-team이 세팅된 프로젝트에서, 역할 없는 세션에 붙여 넣는다. 먼저 그 머신에서 `tmt-machine-migrate.md`를 끝내야 한다.
스텝 사이에 실행한다. 리뷰가 진행 중일 때는 하지 않는다.

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 프로젝트의 three-man-team 역할 파일에 개인 포크 템플릿의 변경을 반영해줘. 덮어쓰지 말고 필요한 부분만 넣는다. 커밋은 내가 diff를 본 뒤에 한다.

준비
1. 이 세션이 쓰는 three-man-team checkout(기본 `~/.claude/skills/three-man-team`, 계정 분리면 `$CLAUDE_CONFIG_DIR/skills/three-man-team`)의 origin이 `dreamwayjgs/three-man-team`이고 최신인지 확인한다. 아니면 멈추고 "머신 전환 먼저"라고 보고.
2. 진행 중인 리뷰가 있는지 확인한다: handoff 디렉터리(세션 스코프면 `handoff-*`도)의 REVIEW-REQUEST가 `Ready for Review: YES`인데 REVIEW-FEEDBACK이 아직 없으면 멈추고 보고.
3. 역할 파일 목록을 확정한다: 프로젝트 루트(또는 manifest.md)에서 ARCHITECT·BUILDER·REVIEWER·ROGER·OPERATOR에 해당하는 파일과 각 역할 이름(기본 Alice·Bob·Richard·Roger·Oz, 한국어 이름일 수 있다)을 찾는다. 파일이 여러 세트(v2/v3 등)면 세트별로 진행한다.

기준 diff
4. 반영할 변경 = `git -C <checkout> diff <base> origin/main -- templates/`.
   - `<base>`는 manifest.md의 `version`에 포크 커밋 해시가 있으면 그 값이다.
   - 없으면 `837bc2f`다. 로저·karpathy·Tests 절은 옛 셋업 절차로 이미 들어가 있는 것으로 보고, 그 뒤의 변경만 반영한다.
   - 단, 프로젝트 파일에 837bc2f 항목(로저 Role 절, karpathy 블록, 리뷰어 `## Tests` 절, deploy gate의 "고지된 green == 커밋 상태" 확인)이 빠져 있으면 그것도 대상에 넣는다.
5. 각 hunk를 프로젝트 파일에 의미 단위로 적용한다.
   - 템플릿의 이름(Arch·Bob·Richard)은 그 프로젝트의 이름으로 바꾼다.
   - 경로(`handoff/`)는 그 프로젝트의 handoff 경로로 바꾼다.
   - 템플릿 문장은 영어 그대로 넣는다. 다음 동기화 때 diff가 맞아야 한다.
   - 파일의 기존 인코딩(UTF-8)과 줄바꿈(CRLF/LF)을 유지한다. Windows에서는 pwsh 7을 쓰고, 가능하면 셸 치환 대신 편집 도구를 쓴다.
   - 이미 같은 의미의 문장이 있으면 넣지 않고 "이미 있음"으로 보고한다.
   - 프로젝트 고유 내용(환경 메모, 하위 repo 메모, 프로젝트 전용 규칙)은 지우거나 바꾸지 않는다.
   - 템플릿 문구와 충돌하는 프로젝트 고유 문구가 있으면 고치지 말고 목록으로 보고한다.
6. 파일별 주의:
   - ROGER.md: 17dec33은 Role 절 교체다. 옛 "Read handoff/REVIEW-FEEDBACK.md before you begin"과 "Flag only what Richard missed" 문장은 남기지 말고 새 문장으로 바꾼다. 로저의 탐색 범위를 좁히는 문장이 남으면 안 된다.
   - c78ae4e 반영 점검(2026-10-14): REVIEWER·ROGER의 Session Start에 `Read handoff/ARCHITECT-BRIEF.md`가 있는지 grep한다. 없으면 REVIEW-REQUEST 다음 단계로 넣고 뒤 번호를 민다. 같은 뜻의 단계가 이미 있으면 건너뛴다. `<!-- tmt-cli:start -->`~`<!-- tmt-cli:end -->` 블록은 `tmt init` 소유라 고치지 않는다.
   - OPERATOR.md: 환경 좌표가 채워진 프로젝트 파일이다. 템플릿으로 덮지 않는다. 템플릿 변경 중 규칙에 해당하는 것만 제안 목록으로 보고하고 적용하지 않는다.
   - ARCHITECT.md 버전 체크: 포크는 비활성화했다. 프로젝트에 upstream 버전 체크 단계가 있으면 같은 한 줄("disabled in this fork. Skip.")로 바꾼다.
   - 프로젝트에 `_temp/ARCHITECT.md`가 있으면 삭제를 제안만 한다.
   - qmd 잔재 점검: 프로젝트 `CLAUDE.md`·`AGENTS.md`·역할 파일에서 `qmd`를 grep한다. 옛 전역 규칙("qmd search 우선", `qmd status` 신선도 확인)이 복사돼 있으면 그 문장만 지운다(2026-10-13 전역 규칙에서 폐기). 프로젝트가 자체 용도로 qmd를 쓰는 문장이면 지우지 말고 보고한다.
   - caveman 레벨 표기 점검(2026-10-13, caveman v3): 역할 파일·프로젝트 지침에서 `caveman (lite|full|ultra)`·`/caveman lite|full|ultra` 같은 강도 표기를 grep한다. 역할별 로드 지시면 `caveman`(스킬 하나)으로 바꾸고, 전역 표를 복사해 둔 옛 Token Optimization 절이면 그 절을 지운다(전역 표가 우선).
   - 스킬 경로 점검: 프로젝트 지침·역할 파일에서 `SKILL.md`·`skills/` 경로를 grep한다. 실존하지 않거나 harness 전용 경로(`~/.claude/skills/<name>`, `~/.claude/plugins/cache/...` 등)면 `~/.agents/skills/<name>/SKILL.md`로 바꾼다. 그 경로에도 없는 스킬이면 바꾸지 말고 보고한다.
7. manifest.md: 이번 반영 기준인 포크 커밋 해시(`git -C <checkout> rev-parse --short origin/main`)를 `version`에 기록한다. 없으면 포크 `templates/project-folder/new-setup.md`의 manifest 형식으로 만든다. 이 값이 다음 동기화의 `<base>`다.

보고
8. 파일별로 정리한다: 적용한 hunk, 이미 있어서 건너뛴 것, 충돌로 보류한 것, OPERATOR 제안. 그다음 `git diff`를 보여준다. 커밋은 내 승인 후에 한다.
```
