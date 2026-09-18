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

Each skill was run on real repositories in disposable clones, once with the skill loaded and once without it, and graded by an independent agent against fixed assertions (registration, path accuracy, cited protected surfaces, corpus rules, a trial survey with proven candidates, edit scope). All runs used Claude Fable 5.1, one run per configuration per case.

| Configuration | Pass rate | Mean wall time | Mean tokens |
|---|---|---|---|
| With skill | 100% | 475s | 117,653 |
| Without skill | 55% | 243s | 58,600 |

| Case | Target repo | With skill | Without skill | Time (with / without) | Tokens (with / without) |
|---|---|---|---|---|---|
| create-canon-lint | canon-lint (TypeScript, bun, knip + jscpd gate) | 11/11 | 6/11 | 510s / 180s | 131,063 / 55,445 |
| create-mmx-cli | mmx-cli (CLI plus published SDK, no dead-code gate) | 11/11 | 5/11 | 358s / 172s | 95,781 / 60,712 |
| create-scrapline | scrapline (Godot/GDScript, goldens and decisions log) | 11/11 | 5/11 | 517s / 252s | 134,578 / 60,688 |
| maintain-ccsn | cc-safety-net, existing `ccsn-find-simplifications` | 7/7 | 4/7 | 465s / 308s | 107,757 / 78,037 |
| maintain-dsh | deepseek-harness, existing `dsh-find-simplifications` | 7/7 | 5/7 | 527s / 301s | 122,639 / 82,141 |

The skill costs roughly twice the wall time and 1.6x to 2.4x the tokens of an unaided run. The difference comes from the trial survey, which every with-skill run performed and no baseline did; in every create case it caught a bug in the freshly written skill before handover.

## Credits

The shape of these skills, and of the skills they generate, draws on two sources:

- [cursor/plugins: pstack skills](https://github.com/cursor/plugins/tree/main/pstack/skills), whose `create-verification-skill` and `maintain-verification-skill` pair established the create-then-maintain pattern for project-local skills.
- [deepseek-ai/deepseek-harness: dsh-find-simplifications](https://github.com/deepseek-ai/deepseek-harness/tree/master/.agents/skills/dsh-find-simplifications), the finished simplification-survey skill that the generated skills take their section structure and evidence bar from.

## License

[MIT](LICENSE)
