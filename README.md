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

## Benchmarks

Two benchmarks answer two different questions. **Yield** asks whether a generated skill makes a surveying agent find better simplification candidates than it would unaided. **Artifact conformance** asks whether the create and maintain skills produce a well-formed, honest skill. The conformance numbers are larger and say nothing about what a survey finds; the yield result is the one that matters.

### Yield

Two of the four repositories below, each at its 2026-08-20 commit: [anomalyco/opencode](https://github.com/anomalyco/opencode) and [earendil-works/pi](https://github.com/earendil-works/pi). For each, one agent surveyed a pristine clone with the generated `code-scans-<project>` skill installed and was told to follow it, and another surveyed an identical pristine clone with no skill and no method prescribed. Both wrote at most 8 candidates in the same JSON schema, told not to pad and not to mention any skill or process. The two lists were pooled, shuffled with a fixed seed, stripped to ids, and handed to one adjudicator per repo working in a third clean clone, so both arms faced the same judge and the same standard. The judge re-verified every candidate against the checkout and scored it **valid** (the factual claim holds), **safe** (acting on it would not touch a documented-intentional surface, a published export, a byte contract, or a trust-boundary control), and **material** (worth a maintainer's attention rather than a one-line nit). Actionable means all three. `claude-fable-5-1` at medium reasoning effort for surveys and judges, via `claude -p`; one run per arm per repo.

| Arm | Candidates | Valid | Safe | Actionable |
|---|---|---|---|---|
| With skill | 16 | 100% | 100% | 94% |
| Without skill | 16 | 100% | 88% | 62% |

| Target repo | Candidates (with / without) | Valid | Safe | Actionable | Time (with / without) | Cost (with / without) |
|---|---|---|---|---|---|---|
| anomalyco/opencode | 8 / 8 | 100% / 100% | 100% / 88% | 100% / 38% | 986s / 404s | $36.62 / $6.06 |
| earendil-works/pi | 8 / 8 | 100% / 100% | 100% / 88% | 88% / 88% | 876s / 446s | $24.49 / $7.38 |

Every candidate in both arms survived independent re-verification, so on this model validity does not separate the arms. The skill's gain is on the other two axes. Both unsafe unaided proposals were doctrine misses: pi's session-search service interfaces are a documented design surface with a changelog obligation, and opencode's `sdk-next` package is a deliberate placeholder for a planned rename. Four unaided candidates were real, safe, and too small to be worth a maintainer's time (orphan helpers of ten to twelve lines each), against one with the skill. On opencode, where an unaided survey drifts toward small utility files, the skill's bounding rules and largest-files-first ordering are what produce the 100% versus 38% gap.

The skill arm costs four to six times as much per survey because the generated skill fans the survey out to subagents. Two caveats: one run per arm per repo, so per-repo rates carry wide error bars and only the pooled deltas should be read; and the remaining two repositories (deepseek-harness, openclaw) have not been run on this model.

### Artifact conformance

Both skills were run against four open-source AI agent repositories, once with the skill loaded and once without it, and graded by an independent agent against fixed assertions (registration, path accuracy, cited protected surfaces, corpus rules, a trial or live survey with proven candidates, edit scope). Create runs used each repo at its 2026-08-20 commit. Maintain runs then took the skill the create run produced and advanced the repo to its 2026-09-17 head, so the drift is four weeks of real upstream churn. One run per configuration per case.

#### Claude Opus 5, medium reasoning effort

`claude-opus-5` for the skill runs, the baselines, their subagents, and the graders.

| Configuration | Pass rate | Mean wall time | Mean tokens |
|---|---|---|---|
| With skill | 100% | 898s | 192,180 |
| Without skill | 48% | 574s | 129,838 |

| Case | Target repo | Upstream commits in the drift window | With skill | Without skill | Time (with / without) | Tokens (with / without) |
|---|---|---|---|---|---|---|
| create | [anomalyco/opencode](https://github.com/anomalyco/opencode) | | 11/11 | 5/11 | 885s / 649s | 216,750 / 172,485 |
| create | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) | | 11/11 | 5/11 | 823s / 541s | 197,754 / 140,118 |
| create | [earendil-works/pi](https://github.com/earendil-works/pi) | | 11/11 | 7/11 | 805s / 657s | 182,139 / 128,656 |
| create | [openclaw/openclaw](https://github.com/openclaw/openclaw) | | 11/11 | 6/11 | 1,239s / 453s | 243,282 / 120,424 |
| maintain | anomalyco/opencode | 270 | 8/8 | 4/8 | 492s / 521s | 103,465 / 100,424 |
| maintain | deepseek-ai/deepseek-harness | 5,102 | 8/8 | 3/8 | 996s / 577s | 193,489 / 116,603 |
| maintain | earendil-works/pi | 409 | 8/8 | 4/8 | 861s / 573s | 197,495 / 123,757 |
| maintain | openclaw/openclaw | 15,028 | 8/8 | 3/8 | 1,085s / 622s | 203,065 / 136,240 |

#### Claude Fable 5.1, medium reasoning effort

`claude-fable-5-1` for the skill runs, the baselines, their subagents, and the graders. This round ran against an earlier revision of the skills, before four fixes drawn from its own results, so the two rounds are not a controlled model comparison.

| Configuration | Pass rate | Mean wall time | Mean tokens |
|---|---|---|---|
| With skill | 100% | 865s | 186,458 |
| Without skill | 58% | 570s | 134,020 |

| Case | Target repo | With skill | Without skill | Time (with / without) | Tokens (with / without) |
|---|---|---|---|---|---|
| create | anomalyco/opencode | 11/11 | 7/11 | 704s / 674s | 178,897 / 128,925 |
| create | deepseek-ai/deepseek-harness | 11/11 | 7/11 | 753s / 485s | 171,744 / 131,209 |
| create | earendil-works/pi | 11/11 | 7/11 | 806s / 512s | 180,885 / 110,717 |
| create | openclaw/openclaw | 11/11 | 6/11 | 1,337s / 486s | 266,429 / 136,154 |
| maintain | anomalyco/opencode | 8/8 | 5/8 | 604s / 474s | 133,449 / 122,722 |
| maintain | deepseek-ai/deepseek-harness | 8/8 | 5/8 | 1,116s / 370s | 217,936 / 92,126 |
| maintain | earendil-works/pi | 8/8 | 4/8 | 637s / 750s | 135,606 / 180,775 |
| maintain | openclaw/openclaw | 8/8 | 3/8 | 964s / 807s | 206,720 / 169,528 |

#### What the skill buys

On both models the skill costs roughly 1.5x the wall time and 1.4x the tokens of an unaided run, and passes every assertion on every repo. The difference is procedural. Every with-skill run performed a trial or live survey and no baseline did, and in every create case that trial falsified a rule in the freshly written skill before handover: a duplication criterion that would have flagged a deliberate migration twin, a dead-code rule that missed published plugin API, a search recipe blinded by `.js` specifiers against `.ts` sources. In the maintain cases the path audit and live pass caught instruction-level bugs that no amount of re-reading finds, including a git pathspec that hid the six largest files in a survey domain. Baselines wrote false claims into the skill in three of eight Opus cases and three of eight Fable cases; with-skill runs wrote none that graders could falsify.

## Credits

The shape of these skills, and of the skills they generate, draws on two sources:

- [cursor/plugins: pstack skills](https://github.com/cursor/plugins/tree/main/pstack/skills), whose `create-verification-skill` and `maintain-verification-skill` pair established the create-then-maintain pattern for project-local skills.
- [deepseek-ai/deepseek-harness: dsh-find-simplifications](https://github.com/deepseek-ai/deepseek-harness/tree/master/.agents/skills/dsh-find-simplifications), the finished simplification-survey skill that the generated skills take their section structure and evidence bar from.

## License

[MIT](LICENSE)
