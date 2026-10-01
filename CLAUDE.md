# claude-settings-example — 프로젝트 지침

이 repo는 개인 Claude Code 세팅의 source-of-truth (설정 export용). 작업 대상이 아니라 설정 보관소다.

## Foreman 제외

이 repo는 주간 원장 보고 대상이 **아니다**. 여기서 `foreman guide`/`register`/`update`/`publish`를 실행하지 말 것. 보고 가능한 작업이 완료돼도 foreman을 건너뛴다.

## three-man-team 포크

- 포크 = `github.com/dreamwayjgs/three-man-team` (**public**, 개인 계정). upstream = `russelleNVy/three-man-team`.
- checkout = `~/.claude/skills/three-man-team` (`origin` = 포크, `upstream` = 원본). 포크 작업·push는 항상 이 세션(claude-settings-example)에서 한다.
- public이므로 push 전 `git diff upstream/main` 결과에서 회사 식별자(회사명·사내 프로젝트명·경로·호스트·이메일)를 grep하고, 실험 근거·사례는 넣지 않는다. 근거는 이 repo `three-man-team-model-allocation.md`에 둔다.
- 커스텀 커밋은 소유자 확인 후 push.
