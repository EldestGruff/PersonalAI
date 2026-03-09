# Current Session Task

## Goal
<!-- What is the ONE thing we're accomplishing this session? Be specific. -->
Start Phase 3B: medication module + AI intelligence UI.
Read `PhaseDocs/` spec before writing any code.


## Relevant Files
<!-- List the files Claude should focus on. Keeps context tight. -->
- `PhaseDocs/` — read spec first
- `Sources/` — implementation target
- `DECISIONS.md` — update at end of session


## Constraints
- Branch for all code changes (never commit to main)
- Spec-first: no code before reading PhaseDocs spec
- After Sonnet generates, ask Andy before chaining phases
- Watch target: `STASH Watch App Watch App/` uses `fileSystemSynchronizedGroups` — no pbxproj edits needed for new files
- Widget Extension: `STASH Watch Complications/` — same rule
- Swift concurrency: use `_Concurrency.Task {}` (project has `struct Task: Codable` that shadows Swift's Task)


## Done When
- [ ] Phase 3B spec read and understood
- [ ] Implementation complete per spec
- [ ] Builds without warnings
- [ ] DECISIONS.md updated with any architectural choices
- [ ] Committed and pushed on feature branch


## Context Notes
<!-- Clear each session — stale context is worse than no context. -->
Session 2026-03-09:
- Watch app polish complete (haptics, notification delegate, WidgetKit complications)
- Complications required a dedicated Widget Extension target — inline WidgetBundle without @main is not auto-discovered by watchOS
- Widget Extension needs SUPPORTED_PLATFORMS = "watchos watchsimulator" in pbxproj (doesn't inherit correctly from Watch app target)
- watchOS 26 device installation broken (known Apple bug) — use TestFlight or simulator
- Acorn balance bug fixed (was self-assigning instead of fetching from AcornLedger)
- dev-methodology session ritual now active (this file + Stop hook)
