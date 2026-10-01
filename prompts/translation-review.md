# 번역 교차검증 프롬프트

역할 파일 등 AI 에이전트가 읽는 문서를 번역한 뒤, 번역한 모델과 다른 벤더의 모델에 붙여 넣는다.
첫 사용: `OPERATOR.md` 한국어 → 영어 (포크 `templates/optional/OPERATOR.md`, 원본은 이 repo git 이력의 `templates/OPERATOR.md`).
아래 `Files:`의 경로와 `Context:`의 독자 설명을 대상에 맞게 바꾼다.

예: `opencode run -m openai/gpt-6.1-sol "$(sed -n '/^```$/,/^```$/p' prompts/translation-review.md | sed '1d;$d')"`

```
You are reviewing a Korean→English translation of an AI agent role file. Read-only: do not edit any file.

Files:
- Original (Korean): ~/.claude/templates/OPERATOR.md
- Translation (English): ~/.claude/skills/three-man-team/templates/optional/OPERATOR.md

Context: The reader of this file is an LLM agent acting as an operator (SRE) with access to production systems. A translation error that changes what the agent is allowed to do is far worse than awkward prose.

Check in this priority order:
1. Authority and permission — Permission Tiers (T0/T1/T2), deadline rule, pre-stated instruction rule, blocked-operation rule, "Never" list. Any change in who approves, when approval is needed, what counts as reversible, or which tier applies is a meaning change.
2. Modality — must / must not / only / by default / may. Flag any place where a Korean obligation became a suggestion, or the reverse, or where scope ("only", "all", "even if") widened or narrowed.
3. Omissions and additions — sentences, conditions, or examples present in one version and missing in the other.
4. Ambiguity — English that a model could plausibly read two ways, even if one reading matches the original.
5. Naturalness — only flag phrasing that is unidiomatic enough to distract or mislead. Do not polish style.

Do not report: formatting, heading wording, punctuation, or choices that are faithful but differently phrased.

Output (in Korean), one table, most severe first:
| # | Severity (의미 변경 / 누락·추가 / 모호 / 부자연) | Section | KO original (quote) | EN translation (quote) | Problem | Suggested EN |

After the table: one line verdict — "의미 변경 없음" or the count per severity.
If there are no findings at a severity level, do not invent any.
```
