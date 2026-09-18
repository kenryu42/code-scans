# Shape of a generated code-scans skill

Both finished examples in [`examples/`](examples/) follow this skeleton. Each section exists for a reason a surveying agent needs; keep the reason, adapt the content, and drop a section only when the repo genuinely has nothing to say in it.

## Frontmatter

`name: code-scans-<project>`. The `description` names the repo, the surfaces it covers, and the candidate kinds (dead, duplicated, speculative, over-built, hand-rolled, contract-exceeding), and states what the deliverable is. It is the only thing an agent sees before deciding to load the skill, so it should be concrete about the repo and a little pushy.

## Opening paragraph

One or two paragraphs that say what the skill turns a request into and set the bar: a few well-proven candidates over many thin ones, judgment over checklist. If the repo documents its own dominant failure mode (over-engineering, speculative generality), say so here: it gives proposals a tailwind and also applies to the proposals themselves.

## Start With Repo Context

Which files to read before judging anything, and why each matters. Doctrine files, the contract or threat-model docs, the notes tree and its rules, and the specific documents that must be read before touching specific directories. Name the repo's central seam or contract when it has one; most reject-or-keep decisions hinge on it.

## Treat As Intentional By Default

Surfaces that look unused or over-built but are settled decisions. Every entry cites where the repo says so and says what inside the surface is still fair game (an unused method inside a protected seam, duplication that can fold into shared machinery without weakening any consumer). Include the dependency posture explicitly: whether introducing a dependency is a valid simplification move or a maintainer decision to propose separately. Include the test doctrine: whether tests and fixtures pin contracts or are merely consumers.

## What Counts As A Strong Candidate

Evidence-based criteria phrased for this repo's surfaces: no production consumer; tests or docs as the only consumers of something not load-bearing; two representations of one fact; seam methods no implementation needs; speculative generality with no owner; invariants or fallbacks protecting unused APIs; defensive machinery applied to values a trusted same-process caller owns; hand-rolled code where a package or builtin fits (only if the dependency policy allows).

Then set the materiality bar, because proving something is unused is the easy half and is not the same as it being worth reporting. Name what clears the bar in this repo's terms — a module or vendored tree that leaves the build, a fact duplicated where it can silently diverge, a hand-rolled routine with a dependency already in the manifest, a removal that retires a documented obligation — and name what does not: a single unused field, flag, parameter, type alias, or gated log line, which belongs in an inline TODO. Say plainly that three proven material candidates beat eight mixed ones, and that a survey stops when the material findings run out instead of filling the remaining slots with correct trivia.

State the proportionality rule alongside it, because the materiality bar on its own pushes a survey toward big targets and a repo's big surfaces are usually the ones it protects on purpose. The larger the proposed removal, the heavier the protection burden: name the doctrine file, spec, or note that a module, package, or subsystem answers to, and require the candidate to quote the line that permits removing it — or to say no such line was found and drop to a question for the maintainer rather than a proposal. An uncited large removal ranks below a cited small one.

## Survey Broadly

The survey domains, each mapped to real paths in the current tree, each phrased as what to look for there. Say how to split across subagents when breadth is requested, and to start with the largest production files rather than stray unused symbols. Say how to pick the domain when only one fits in a pass — expected payoff, not list order — and that a domain which turns out thin is reported as thin, with the next domain picked up on the following pass.

## Audit Trust And Lifecycle Boundaries (when the repo has them)

For repos with async lifecycles or trust boundaries: how to name where a value came from and who owns it next, and which separate mechanisms must stay separate (publication and rollback, callback containment, first-terminal-outcome arbitration, dispose-to-quiescence).

## Prove Or Reject Each Candidate

The corpus classification (production, non-production, ambiguous) with concrete roots and reachability rules; the search recipe (exact symbols, config keys, event and wire strings, method names in both call shapes); the gate's caveats; and the reject-or-downgrade rules, including the one that says a correct-but-tiny idea becomes an inline TODO rather than a proposal.

## The deliverable

One of two shapes, chosen by the interview:

- **Notes-driven repos:** where to create the note, its lifecycle and classification rules, its structure (problem with consumer evidence, proposal, what we give up, acceptance criteria, risks), and how to consolidate into an existing note instead of duplicating. Add inline TODO rules if the repo has urgency semantics for them.
- **Report-driven repos:** the report structure (what, evidence, what we give up, blast radius), strongest evidence first, and an explicit instruction not to create new docs, directories, or process files to hold findings, and not to implement during a survey unless asked.

## Validation And PR Hygiene

What to run for a findings-only survey (often nothing), what to run once candidates are implemented (the repo's single check command, never its pieces separately), how to handle gate fallout at the root cause, and what a PR body or commit message must name when a contract row, snapshot, or note changes.

## Rot resistance (a rule for the author, not a section)

These apply to every section above and do not become a section of the generated skill: paths verified against `git ls-files`; rules over enumerations; relative links; no machine paths; each protected surface cited. The maintenance skill checks these on every pass, so violations are cheaper to avoid now than to fix later.
