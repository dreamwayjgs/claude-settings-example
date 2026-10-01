| # | Severity (의미 변경 / 누락·추가 / 모호 / 부자연) | Section | KO original (quote) | EN translation (quote) | Problem | Suggested EN |
|---|---|---|---|---|---|---|
| 1 | 모호 | Never | **버전 관리 밖의 파일은 삭제 대신 이동한다.** | **Move files outside version control instead of deleting them.** | `outside version control`이 `Move`의 목적지로도 읽힌다. 원문은 **이미 버전 관리 대상이 아닌 파일**에 대한 삭제 금지인데, 번역은 파일을 버전 관리 밖으로 옮기라는 지시로 해석될 수 있다. | **For files not under version control, move them instead of deleting them.** |
| 2 | 모호 | Deploy Execution | 배포할 커밋은 항상 Architect deploy gate를 통과한 것. | The commit to deploy has always passed the Architect deploy gate. | 원문은 gate 통과를 배포의 필수 전제조건으로 둔다. `has always passed`는 과거에 항상 통과했다는 사실 서술로도 읽혀, 미통과 커밋의 배포를 금지하는 규칙이 불명확하다. | Only deploy commits that have passed the Architect deploy gate. |

의미 변경 0건 / 누락·추가 0건 / 모호 2건 / 부자연 0건.
