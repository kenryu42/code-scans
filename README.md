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

## Experiments

Each skill was run on real repositories in disposable git clones, once with the skill loaded and once without it as a baseline, and graded by an independent agent against fixed assertions. All runs used Claude Fable 5.1. Assertions were checked mechanically where possible (naming, symlink, path audit, absolute paths, frontmatter, edit scope) and by a grader reading the transcript, report, and generated files otherwise. Graders also re-ran spot-check searches in the clones to confirm candidate evidence and citations.

### Iteration 1 summary

| Configuration | Pass rate | Mean wall time | Mean tokens |
|---|---|---|---|
| With skill | 100% (5 of 5 cases, every assertion) | 475s | 117,653 |
| Without skill | 55% | 243s | 58,600 |

### Per-case results

| Case | Target repo | With skill | Without skill | Time (with / without) | Tokens (with / without) |
|---|---|---|---|---|---|
| create-canon-lint | canon-lint (TypeScript, bun, knip + jscpd gate) | 11/11 | 6/11 | 510s / 180s | 131,063 / 55,445 |
| create-mmx-cli | mmx-cli (CLI plus published SDK, no dead-code gate) | 11/11 | 5/11 | 358s / 172s | 95,781 / 60,712 |
| create-scrapline | scrapline (Godot/GDScript, goldens and decisions log) | 11/11 | 5/11 | 517s / 252s | 134,578 / 60,688 |
| maintain-ccsn | cc-safety-net, existing `ccsn-find-simplifications` | 7/7 | 4/7 | 465s / 308s | 107,757 / 78,037 |
| maintain-dsh | deepseek-harness, existing `dsh-find-simplifications` | 7/7 | 5/7 | 527s / 301s | 122,639 / 82,141 |

### Assertions

Create cases (11): skill registered at `code-scans-<project>` with a description naming the repo; symlink resolves; zero `MISSING` paths; no machine-specific absolute paths; no `disable-model-invocation`; protected surfaces each cite a repo source; the repo's own gates named with a caveat about what they cannot see; production, non-production, and ambiguous corpora with concrete roots; a deliverable channel with a repo-derived rationale; a trial survey with at least two candidates proven or rejected with evidence; no edits outside `.agents/` and `.claude/`.

Maintain cases (7): correct target located; path audit run and reported; exactly one outcome word; edits confined to the skill directory; a live survey of one named domain with at least two candidates; candidates reported but not committed; final path check clean and the commit message names what rotted. The deepseek-harness case additionally required detecting the retired `examples/` tree and the nested package layout.

### What the baselines missed

- No baseline ran a trial or live survey. Every with-skill run did, and in all three create cases the trial exposed a bug in the freshly written skill that was then fixed: an unscoped search returning `node_modules` hits, a search recipe that read a file's own declarations as consumers, and a fold candidate that a design doc records as a deliberate rule split.
- Every baseline mis-named the generated skill and every create baseline shipped backticked paths that do not exist. One baseline edited `AGENTS.md`, and one set `disable-model-invocation`, so its survey could never trigger on its own.
- In the maintain cases both configurations found the seeded drift. The skill's extra finds came from its live pass and enumeration audit: in cc-safety-net, a shared-machinery pointer that omitted the real host registry and two uncited `SECURITY.md` contracts; in deepseek-harness, an Agent Note heading the format gate rejects, a translation-pairing requirement that would fail `doc-sync`, and a protected experimental package tree. One baseline replaced a removed tool name with a semantically weaker one.

### Cost

With-skill runs took roughly twice the wall time and 1.6x to 2.4x the tokens of their baselines. Graders judged the extra cost earned in every case, because the difference was the trial or live pass and that is where the discriminating findings came from.

### Caveats

- Sample size is one run per configuration per case, so the time and token figures are indicative, not statistical.
- Some assertions do not discriminate: no-absolute-paths and edit-scope confinement passed for nearly every run, and the path-audit assertion passes for any grep loop.
- Nothing checks mechanically whether a fact a run writes into a skill is true. Graders spot-checked citations in every case and found no false claim in any shipped skill file, but that remains a manual check.
- Target clones had no installed dependencies, so runs could not execute the repos' check commands. Each run said so rather than claiming a green gate.

### Changes made from iteration 1

- The `<project>` naming rule was unstated; the canon-lint run chose `code-scans-canonlint` from the existing `verify-canonlint` skill. The generator now says to reuse the repo's established short name and otherwise the directory name.
- The outline's rot-resistance rules are author guidance, and one generated skill copied them in as a trailing section. The outline now says so explicitly.

## Credits

The shape of these skills, and of the skills they generate, draws on two sources:

- [cursor/plugins: pstack skills](https://github.com/cursor/plugins/tree/main/pstack/skills), whose `create-verification-skill` and `maintain-verification-skill` pair established the create-then-maintain pattern for project-local skills.
- [deepseek-ai/deepseek-harness: dsh-find-simplifications](https://github.com/deepseek-ai/deepseek-harness/tree/master/.agents/skills/dsh-find-simplifications), the finished simplification-survey skill that the generated skills take their section structure and evidence bar from.

## License

[MIT](LICENSE)
