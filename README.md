# code-scans

[![skills.sh](https://skills.sh/b/kenryu42/code-scans)](https://skills.sh/kenryu42/code-scans)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/kenryu42/code-scans?label=Last%20update)](https://github.com/kenryu42/code-scans/commits/main)

Two skills that give a repository its own simplification-survey skill and keep that skill honest as the repository changes.

## Install

```bash
npx skills add kenryu42/code-scans
```

Or copy `skills/create-code-scans-skill` and `skills/maintain-code-scans-skill` into `~/.claude/skills/` (Claude Code) or `.agents/skills/` in a project.

A generic "find dead code" checklist cannot tell a surveying agent which unused-looking surfaces are settled decisions, what counts as a production consumer in this tree, where the trust boundary sits, which gate already catches the easy cases, or where a finding is supposed to go. That judgment is repo-specific, so it belongs in a repo-specific skill. The pair here produces and maintains one.

## Skills

### `create-code-scans-skill`

Generates `.agents/skills/code-scans-<project>/SKILL.md` (with a `.claude/skills/code-scans-<project>` symlink) for the repository it runs in. It interviews the checkout rather than the user: doctrine files, layout and corpora, protected surfaces with their citations, the trust boundary, the existing gates and their blind spots, the deliverable channel (a notes tree, or a report to the maintainer), validation commands, and recent history such as retired directories or removed dependencies. It then writes the skill, verifies every backticked path against `git ls-files`, and runs one bounded trial survey using only the generated skill's own rules. The trial exists to break the skill: a candidate its rules call strong that the repo protects somewhere it did not cite is a bug in the skill, fixed before handover.

Bundled: `references/generated-skill-outline.md` (the section skeleton and what each section needs), `references/examples/` (two finished skills, one for a notes-driven monorepo and one for a report-driven security tool), and `scripts/check-skill-paths.sh`.

### `maintain-code-scans-skill`

The upkeep loop. It locates the project's code-scans skill, audits every named path, diffs the repo's doctrine and tooling against the skill's protected-surface list and corpus rules, sweeps recent churn, replaces enumerations that rot with the rules that generate them, and runs one bounded live survey to catch drift the text alone cannot show. Outcomes are `clean`, `changed` (one PR of proven corrections), or `blocked`. It edits only the skill's own directory; simplification candidates it finds along the way are reported, never shipped in the maintenance PR.

### `scripts/check-skill-paths.sh`

Both skills bundle the same script. It extracts every backticked span from a Markdown file, keeps the ones that look like repo paths, and checks each against `git ls-files` (globs are matched as git pathspecs). Output is one line per path marked `ok`, `untracked`, or `MISSING`, with a non-zero exit when anything is missing. Running it on the deepseek-harness example during development found real drift: the top-level `examples/` tree had been retired three weeks earlier and the package glob no longer matched the nested workspace layout.

## Benchmark

Both skills were run against four open-source AI agent repositories, once with the skill loaded and once without it, and graded by an independent agent against fixed assertions (registration, path accuracy, cited protected surfaces, corpus rules, a trial or live survey with proven candidates, edit scope). Create runs used each repo at its 2026-08-20 commit. Maintain runs then took the skill the create run produced and advanced the repo to its 2026-09-17 head, so the drift is four weeks of real upstream churn. One run per configuration per case.

**Model:** Claude Fable 5.1 (`claude-fable-5-1`) at medium reasoning effort for every run: the skill runs, the baselines, their subagents, and the graders.

| Configuration | Pass rate | Mean wall time | Mean tokens |
|---|---|---|---|
| With skill | 100% | 865s | 186,458 |
| Without skill | 58% | 570s | 134,020 |

| Case | Target repo | Upstream commits in the drift window | With skill | Without skill | Time (with / without) | Tokens (with / without) |
|---|---|---|---|---|---|---|
| create | [anomalyco/opencode](https://github.com/anomalyco/opencode) | | 11/11 | 7/11 | 704s / 674s | 178,897 / 128,925 |
| create | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) | | 11/11 | 7/11 | 753s / 485s | 171,744 / 131,209 |
| create | [earendil-works/pi](https://github.com/earendil-works/pi) | | 11/11 | 7/11 | 806s / 512s | 180,885 / 110,717 |
| create | [openclaw/openclaw](https://github.com/openclaw/openclaw) | | 11/11 | 6/11 | 1,337s / 486s | 266,429 / 136,154 |
| maintain | anomalyco/opencode | 270 | 8/8 | 5/8 | 604s / 474s | 133,449 / 122,722 |
| maintain | deepseek-ai/deepseek-harness | 5,102 | 8/8 | 5/8 | 1,116s / 370s | 217,936 / 92,126 |
| maintain | earendil-works/pi | 409 | 8/8 | 4/8 | 637s / 750s | 135,606 / 180,775 |
| maintain | openclaw/openclaw | 15,028 | 8/8 | 3/8 | 964s / 807s | 206,720 / 169,528 |

The skill costs about 1.5x the wall time and 1.4x the tokens of an unaided run. Every with-skill run performed a trial or live survey and no baseline did; in every create case the trial caught a bug in the freshly written skill before handover, and in three of four maintain cases the baseline wrote at least one false claim into the skill while the with-skill run wrote none.

## Credits

The shape of these skills, and of the skills they generate, draws on two sources:

- [cursor/plugins: pstack skills](https://github.com/cursor/plugins/tree/main/pstack/skills), whose `create-verification-skill` and `maintain-verification-skill` pair established the create-then-maintain pattern for project-local skills.
- [deepseek-ai/deepseek-harness: dsh-find-simplifications](https://github.com/deepseek-ai/deepseek-harness/tree/master/.agents/skills/dsh-find-simplifications), the finished simplification-survey skill that the generated skills take their section structure and evidence bar from.

## License

[MIT](LICENSE)
