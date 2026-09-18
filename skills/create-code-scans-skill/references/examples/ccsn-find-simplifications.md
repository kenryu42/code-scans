---
name: ccsn-find-simplifications
description: 'Use when working in the cc-safety-net repo to find non-obvious simplification candidates: dead, duplicated, speculative, over-built, or contract-exceeding surfaces in the shell parser, analyzer, guards, secret protection, policy, rules manager, audit log, hosts, CLI, or GUI. Produces evidence-backed proposals for the maintainer, not a pile of guesses.'
disable-model-invocation: true
---

# Finding CC Safety Net Simplifications

This skill turns a broad "find things to simplify" request into evidence-backed candidates that remove or collapse existing surface area. It is guidance, not a checklist: follow the code, keep judgment active, and prefer a few well-proven candidates over many thin ones.

Over-engineering is this repo's documented dominant failure mode (see Scope Discipline in `AGENTS.md`), so simplification proposals have a tailwind — but the same discipline applies to the proposals themselves: each one must name the concrete cost the current code carries, not just "this looks complex."

## Start With Repo Context

- Read `AGENTS.md` (Scope Discipline, Testing, Style Guide, Knip rules), `REVIEW.md` (threat model and review boundary), and `SECURITY.md` (the standard/strict/paranoid mode contract).
- Read `docs/residual-risk.md` before judging anything in `src/core/shell`, `src/gate/analyzer`, `src/gate/guards`, or `src/core/rules`. Adjudicated bypass families are settled decisions; fixtures pinning them are load-bearing even when nothing else references them. Read `docs/secret-protection-known-limitations.md` before judging `src/gate/secret`.
- The mode contract is the repo's central seam: standard mode blocks recognizable accidental destruction and is explicitly not bypass-proof; strict/paranoid fail closed. Complexity that exists only to chase crafted adversarial shapes in standard mode exceeds the documented contract — `REVIEW.md` forbids adding it, which makes any existing instance a prime simplification candidate. Conversely, fail-closed machinery in strict/paranoid is contract, not bloat.

## Treat As Intentional By Default

- Every per-host directory under `src/hosts` (`amp`, `claude-code`, `codex`, `cursor`, `pi`, and the rest). Each exists because a real host tool needs it; propose deleting one only if the user says the host is dropped. Removing an unused hook, command, or method *inside* one is still fair game, and so is folding duplication into the shared host machinery (`src/hosts/detect`, `src/hosts/install`, `src/hosts/hook`, `src/hosts/templates`) when no host's enforcement weakens.
- The residual-risk registry pair (`docs/residual-risk-registry.json` + `docs/residual-risk.md`) and the strict/paranoid fail-closed fixtures that back its families.
- The behavioral contract corpus: `tests/gate/behavioral-contract-cases.ts`, `tests/gate/pipeline-contract-cases.ts`, and the hand-edited verdict table `tests/fixtures/gate/harvested-verdicts.jsonl`. Per `AGENTS.md`, a row there is a stated expectation, not a recording; a proposal that needs a row flipped must name the row and argue the flip on contract grounds. The two snapshot surfaces (`explain` in `tests/cli/explain`, `doctor --json` in `tests/cli/doctor`) are byte contracts, not incidental output.
- The zero-runtime-dependency posture. Hand-rolled shell parsing, JSONC/TOML reading, and atomic writes are the product, not a hand-rolling smell — this is a security hook with a deliberately minimal supply chain. Do not propose swapping the parser, a guard, or a reader in `src/core/io` for an npm package; a new dependency is a maintainer decision to propose separately, never a "low effort" cleanup.
- The rules manager's resource limits (`src/rules-manager/resource-limits.ts`) and the parser's exhaustion budgets. `SECURITY.md` publishes their numbers; they are contract.
- Adversarial-looking strings in tests are analyzer input data, never executed. Do not propose removing them as dangerous or redundant without checking which contract row or residual-risk family they pin.

## What Counts As A Strong Candidate

A strong simplification removes, folds, or demotes something real, with evidence the current design costs more than it buys:

- An internal symbol, gate pipeline stage, host adapter method, or GUI implementation surface has no production consumer. For public exports (`src/entries/api.ts`), configuration, policy knobs, and CLI or GUI features, require contract or deprecation evidence; repository-local absence cannot prove that external users do not depend on them.
- Tests or comments are the only consumers, and the behavior they pin is not a mode-contract guarantee, a contract-corpus row, or a residual-risk fixture.
- Two representations mirror the same fact (e.g. a value stored on the shell model in `src/core/shell/model.ts` and re-derived in the analyzer, a fact computed in `src/gate/facts.ts` and again in a guard, or parallel per-host code that could share one path without weakening any host's enforcement). Note that `bun run check` already gates textual duplication via jscpd — focus on structural duplication it cannot see.
- Standard-mode parser or rule logic whose only justification is a deliberately crafted bypass shape: per `REVIEW.md` that belongs to strict/paranoid fail-closed handling or documented residual risk, not emulation code.
- Defensive copies, freezes, re-validation, or normalization applied to values a same-process trusted caller already owns. The trust boundary here is precise: hook payloads from host tools, user config/policy files, rulebooks fetched by the rules manager, and analyzed command strings are untrusted and deserve validation; values passed between this repo's own modules ordinarily do not.
- Speculative generality with no consumer: registries with one entry, schemas ahead of their first real user, fields whose values are forced constants, options no host or entry sets.
- An invariant, fallback, or special-case test that exists only to protect an unused API.
- The simplified behavior may differ slightly, but the new behavior is still reasonable, within the mode contract, and easier to explain.

Thin candidates are not enough: one typo, a single `knip` run, "this looks complex" without call-site proof, or anything whose removal would create a false negative for recognizable danger in standard mode.

## Survey Broadly

Use parallel subagents when the user asks for breadth. Give each a domain and require evidence, not guesses:

- Shell parser and model (`src/core/shell`): normalization passes, node kinds, fields nothing downstream reads.
- Analyzer and rules (`src/gate/analyzer`, `src/core/rules`): rule machinery, severity plumbing, contract-exceeding emulation.
- Guards, secret protection, and policy (`src/gate/guards`, `src/gate/secret`, `src/core/policy`): backstops mirroring the same fact, config knobs nothing sets.
- Gate pipeline and core utilities (`src/gate/*.ts`, `src/core/*.ts`, `src/core/io`, `src/core/git`, `src/core/paths`): intake/analysis/decision plumbing, trace and explain scaffolding, helpers with one caller.
- Rules manager and audit log (`src/rules-manager`, `src/audit`): sync and resolver states, retention and display paths no command reaches.
- CLI and entries (`src/cli`, `src/entries`): commands, flags, install/doctor/policy/rule flows, output formatting, entry files that re-export what nothing imports.
- Hosts (`src/hosts` per-host directories and shared machinery, `hooks/`, the plugin manifests): per-host duplication, unused adapter methods, template branches no host takes.
- GUI (`src/gui`, `src/gui/frontend`): surfaces or state with no interaction path.
- Tests, scripts, build, evals (`tests/`, `scripts/`, `evals/`): redundant fixtures, helpers duplicating each other, verification scripts checking what another gate already checks.

Do not let the first good candidate stop the survey, and start with the largest production files — duplicated lifecycle and defensive machinery costs more than stray unused symbols.

## Prove Or Reject Each Candidate

Classify consumers before writing anything up:

- Production corpus: `src/`, `hooks/`, `scripts/` used at build/publish time, the plugin manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `kimi.plugin.json`), package.json `bin`/`pi`/`peerDependencies` wiring, and the tracked `skills/` directory. Reachability runs through `src/entries/*`: a symbol only an entry file exports is still production if that entry is a published surface. Ignore `dist/` (generated) and anything `git ls-files` does not list.
- Non-production corpus: `tests/` and comments. README and other docs are non-runtime evidence, but count as contract consumers for public surfaces.
- Ambiguous corpus: `tests/e2e`, `tests/e2e-live`, and `evals/` exercise real host-tool wiring — these often pin integration contracts; read them before classifying.

Use `rg` first: the exact symbol, config key, CLI flag, rule id, host name string, and any wire/JSON strings (hosts dispatch on string tool names, so grep strings, not just identifiers). Then read the call sites. `knip` helps but runs in `--production` mode — a `/** @internal */` tag means test-only-by-design, not dead; and dynamic string dispatch hides real consumers from it.

Reject or downgrade when:

- A production consumer exists and removal would be a feature decision, not a cleanup.
- The surface is pinned by the mode contract, a contract-corpus row, a residual-risk family, or a documented decision in `docs/`, and the new evidence does not beat the recorded rationale.
- Removal would cause a standard-mode false negative for a plausible accidental command, or weaken strict/paranoid fail-closed behavior.
- Removal forces broad churn without reducing public surface or required behavior.

## Report, Don't Restructure

This repo has no notes system and a solo maintainer. The deliverable is a report to the user, strongest evidence first. For each candidate:

- **What**: the exact symbols/files to remove, fold, or demote, with `file:line` references.
- **Evidence**: production vs test/doc consumers found, and the searches that establish absence.
- **What we give up**: the strongest counterargument, stated honestly — including any behavior change and why it stays within the mode contract.
- **Blast radius**: tests, docs, fixtures, contract rows, and snapshots that would change with it.

Do not create new docs, directories, dependencies, or process files to hold findings — placement of new repo structure is the maintainer's call. Do not implement removals during a survey unless the user asked for fixes; when they do, implement the smallest change per candidate, keep `tests/` mirroring `src/`, and follow the Red–Green rule for any behavior change: the failing expectation (a contract row or stated assertion) lands first, and re-recording a snapshot or editing the verdict table is never the first step.

## Validation

A findings-only survey needs no checks. When candidates are implemented, run `bun run check` once at the end (never its pieces separately). If knip then flags fallout, fix the root cause per the Knip section of `AGENTS.md` — unexport, tag `/** @internal */`, or trim the barrel; never touch `ignoreIssues`. If a change flips a verdict-table row or re-records one of the two permitted snapshots, the commit message must name which entries changed and why.
