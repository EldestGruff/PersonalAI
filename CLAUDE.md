# STASH — Claude Code Reference

## Project Identity
iOS thought-capture app. Offline-first SwiftUI. Squirrelsona companion system.
Backend API: https://ai.gruff.icu (deployed, not active dev — treat as infrastructure).
Xcode project: `PersonalAI.xcodeproj` | Swift 6.0+ | iOS 18+ target

## Session Start — Read This First
At the start of every session, read `TASK.md` in the project root.
It contains the session goal, relevant files, constraints, and done-when criteria.
If TASK.md is empty or stale, ask Andy what we're working on before proceeding.

## Active Phase
<!-- UPDATE THIS EACH SESSION -->
Phase: 3A + 3B complete | Next: TBD (ask Andy)
Branch: (update when active)
Last decision: 2026-03-07 — Acorn balance via CloudKit ledger + iCloud KV sync complete
Full phase docs: `PhaseDocs/` | Architecture: `docs/development/`

## Workflow Rules
- **Spec-first always.** Read spec from `PhaseDocs/` before writing any code.
- **Branch for all code changes.** Never commit code to `main`. Docs-only is the only exception.
- **Sonnet executes specs. Opus reviews architecture only.**
- After Sonnet generates, ask Andy before proceeding — don't chain phases.
- Commit frequently. Atomic commits with conventional messages.
- Use `sosumi` MCP for Apple docs before implementing any new framework feature.

## Branch Naming
`feature/`, `fix/`, `refactor/`, `experiment/` — delete after merge.

## Code Quality Gates (non-negotiable)
- Compiles without warnings
- Theme-aware: `ThemeEngine.shared.getCurrentTheme()`
- Accessibility: VoiceOver labels, dynamic type
- Xcode pbxproj: new Swift files need manual entry in 3 places (see Critical Gotchas)

## Key Patterns
**Theme:** `let theme = themeEngine.getCurrentTheme()` — use `theme.textColor` etc., never hardcode colors.
**Squirrelsona personas:** Supportive Listener · Brainstorm Partner · Socratic Questioner · Journal Guide · Devil's Advocate. Pattern: see `SquirrelReminderService.swift`.
**AI:** `ClaudeService.shared` with `ResponseFormat<T>` for structured outputs. Always handle errors gracefully.
**Storage:** SwiftData local. `ThoughtService.shared` · `ContextService.shared`.

## Critical Gotchas (do not rediscover these)

**Xcode pbxproj — new Swift files require 3 manual additions:**
1. `PBXFileReference` section
2. Group `children` array (correct folder group)
3. `PBXSourcesBuildPhase` sources list
CLI builds fail without this even if Xcode UI auto-resolves.

**NLTagger returns a tuple, not an optional:**
```swift
let (lemmaTag, _) = tagger.tag(at: range, unit: .word, scheme: .lemma)
```
Optional chaining on the return value is a compile error.

**ClassificationBiasStore:** `@unchecked Sendable` — all mutation via thread-safe `UserDefaults`.
Pattern key = first 5 words lowercased. Use `feedbackType: FeedbackType` (not `isPositive: Bool`) to preserve 3-state feedback.

**Swift Charts 3D (iOS 26+):** `symbolSize` uses viewport units (0.01–0.1), not pixels.
Scale modifiers need BOTH `domain` (data range) AND `range` (viewport range).
Point selection not available in iOS 26.0 beta — code preserved, feature hidden.

## DECISIONS.md
Append-only architectural decision log. Update at end of each session.
Format: `## YYYY-MM-DD: [decision title]` → one paragraph rationale.
