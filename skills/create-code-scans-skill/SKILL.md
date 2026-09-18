---
name: create-code-scans-skill
description: "Generate a project-local code-scans skill (`code-scans-<project>`) that teaches an agent to find evidence-backed simplification candidates in one repo: dead, duplicated, speculative, over-built, hand-rolled, or contract-exceeding surfaces, judged against that repo's own doctrine, protected seams, corpora, and deliverable channel. Use for /create-code-scans-skill, \"make a simplification survey skill for this repo\", \"find-simplifications skill\", or when a repo has no scripted way to audit its own surface area."
disable-model-invocation: true
---

# Create a code-scans skill

A code-scans skill turns a vague "find things to simplify" request into a few well-proven candidates instead of a pile of guesses, and keeps a surveying agent from proposing to delete the product. Generic advice cannot do that; what makes the survey safe and useful is repo judgment: which surfaces are intentional even when nothing calls them, what counts as a production consumer here, where the trust boundary sits, which gate already catches the easy cases, and where a finding is supposed to go. This skill extracts that judgment from the repo and writes it into `.agents/skills/code-scans-<project>/SKILL.md`, with `.claude/skills/code-scans-<project>` as a symlink to the same directory for Claude Code. Write it for the next agent, not for a human: it will be read cold, mid-task, by an agent that has never seen the repo.

## 1. Interview the repo, not the user

Answer these from the checkout and only ask the user what you cannot observe:

- **Doctrine.** Read `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `REVIEW.md`, `SECURITY.md`, and `docs/` for anything that names a failure mode (over-engineering, scope discipline), a testing doctrine (are tests golden truth or not?), a dependency policy (zero runtime dependencies, or dependencies-over-hand-rolling?), a prose standard, or a documented contract with published numbers. Each of these changes what a "strong candidate" means.
- **Layout and corpora.** Walk the tree and decide what is production, non-production, and ambiguous. Production is what ships or runs: source roots, entry points, manifests, build-time scripts, tracked skills. Non-production is tests, docs, comments, snapshots, generated expected outputs. Ambiguous is anything that might be a product smoke path or an integration contract (examples, evals, e2e suites). Note reachability rules (a symbol only an entry file exports is still production if that entry is published), generated directories to ignore, and that anything `git ls-files` does not list is out of scope.
- **Protected surfaces.** Find what is intentional even when it looks unused: documented decisions (a notes tree, ADRs, residual-risk registries), contract corpora and snapshot surfaces that are byte contracts, published limits, per-integration directories that each exist for a real external host, deliberate twins or seams, and public exports where repository-local absence cannot prove no external consumer. Cite where the repo says each one is intentional; do not invent protected seams.
- **Trust boundary.** Name which inputs are untrusted (wire payloads, user config, fetched rulebooks, model output, durable files, worker or process boundaries) and which are same-process handoffs that ordinarily borrow values. This decides whether a defensive copy, freeze, or re-validation is contract or bloat.
- **Tooling.** Find the existing gates and their caveats: dead-code and duplication tools (`knip`, `jscpd`, `ts-prune`, `vulture`, `cargo udeps`, and similar), the one check command the repo wants run, lint, and pre-push hooks. Record what the tools cannot see (dynamic string dispatch, `@internal` tags that mean test-only-by-design, production-only modes) so the survey does not stop where the tool stops.
- **Deliverable channel.** Decide where findings go. A repo with a notes or ADR system that has lifecycle and placement rules wants proposals written there in its format; a repo with a solo maintainer and no notes system wants a report and no new structure. Record inline TODO conventions and urgency semantics, PR conventions, and the base branch name.
- **Validation.** Record which commands prove a docs-only change versus an implemented removal, and which pieces must never be run separately.
- **Recent history.** Skim `git log` for cutovers, retired directories, removed dependencies, and renamed terminology. The skill must describe the current tree, not the one that existed when the docs were written.

Ask the user only for the unobservable: seams that are off-limits beyond what the docs say, and whether the surveying agent may implement removals when the docs are silent.

## 2. Generate the skill

Write `.agents/skills/code-scans-<project>/SKILL.md`, where `<project>` is the short name the repo already uses for itself in an existing project-local skill (`verify-<project>`, for instance) and otherwise the repository directory name. Give it YAML frontmatter: `name: code-scans-<project>` and a `description` that names the repo, the surfaces it covers, and the kinds of candidates it finds, so the skill triggers on "find things to simplify" requests in that repo. Without frontmatter the skill never registers. Do not set `disable-model-invocation`; the survey should be reachable when an agent recognizes the request.

Shape the body per [`references/generated-skill-outline.md`](references/generated-skill-outline.md), grounding every section in what the interview found. The two finished skills in [`references/examples/`](references/examples/) show the shape for a notes-driven monorepo and for a report-driven security tool; read both before writing so the section weights and tone are right, then write the repo's own version rather than a search-and-replace of either.

Rules that keep the generated skill honest over time, because a survey skill that names a retired directory teaches wrong searches:

- Every path in backticks exists in `git ls-files` now. Run `scripts/check-skill-paths.sh <generated SKILL.md>` and fix every `MISSING` line before handing over. `untracked` lines are acceptable only for generated output the skill tells the reader to ignore.
- Prefer a rule to an enumeration wherever membership changes over time: "every directory under `src/hosts`" beats a list of hosts, "whatever `git ls-files` does not list" beats a list of scratch files. Never write a machine-specific absolute path.
- Every protected surface cites its source (a doc, a note, a contract file). Every "treat as intentional" entry also says what inside it is still fair game, so the protection does not become a blanket exemption.
- Name the repo's own gates with their caveats instead of generic advice about dead-code tools.
- Leave no placeholders. If a section has nothing repo-specific to say, cut it rather than pad it.

Then create `.claude/skills/code-scans-<project>` as a symlink to `../../.agents/skills/code-scans-<project>` so Claude Code loads the same skill.

## 3. Prove the generated skill before handing it over

Run its own instructions once, bounded: pick one survey domain, and using only the generated skill's corpus classification and search recipes, prove or reject at least two candidates end to end. Produce the deliverable in the shape the skill prescribes, but keep it in a scratch location: a trial survey's findings are input for the user, not a commit, and the trial never implements removals.

The trial exists to break the skill, not to find simplifications. Watch for a candidate the skill's rules call strong that turns out to be protected by something the skill did not list, a corpus rule that misclassifies a real consumer, a search recipe that finds nothing because the repo's naming differs, or a deliverable instruction that cannot be followed. Each one is a bug in the skill: fix the skill, not the candidate. Rerun the path checker after edits. A generated skill that was never executed is a draft, not a deliverable.

## 4. Offer the maintenance loop

Point the user at `/maintain-code-scans-skill` for keeping the skill aligned as the tree, the doctrine, and the tooling change. Suggest a cadence only if they ask.
