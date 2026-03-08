# STASH — Architectural Decision Log
Append-only. One entry per significant decision. Most recent first.

---

## 2026-03-07: Acorn balance uses CloudKit ledger, not KV Store
Acorn `currentBalance` is never stored directly. Architecture:
- `lifetimeEarned` → NSUbiquitousKeyValueStore (monotonically increasing, take max)
- Spend events → CloudKit `AcornSpendRecord` entity (append-only, one record per purchase)
- `currentBalance` → derived at runtime as `lifetimeEarned - sum(AcornSpendRecords)`

Rationale: KV Store is eventually consistent. Two simultaneous spends on different devices
before sync would cause one purchase to be silently dropped. Acorns represent real earned
effort — integrity of the economy is non-negotiable. CloudKit append-only records make
concurrent spends impossible to lose.

Migration note: existing `acorn.currentBalance` from UserDefaults is not migrated.
`lifetimeEarned` is migrated. One-time balance loss on first update accepted as the
price of correct behavior going forward.

---

## 2026-03-07: Adopt slim CLAUDE.md + DECISIONS.md pattern
Replaced verbose CLAUDE.md (1200 tokens) with reference-card style (450 tokens).
Moved future considerations to GitHub issues. Moved architectural decisions here.
Gotchas (NLTagger, pbxproj, ClassificationBiasStore) preserved as they have real rediscovery cost.
Backend (personal-ai-assistant) reclassified as deployed infrastructure — no active dev.

## 2026-02-11: 3D Charts deferred
Built interactive Chart3D visualizations (iOS 26). Rendering worked but point selection APIs not
available in iOS 26.0 beta, making them not useful. Code preserved in `Sources/UI/Charts/*3D.swift`.
Will revisit when Apple ships point selection support.

## 2026-02-01: Project Bootstrapper design spec written
Designed a full agent-based project bootstrapper (see `docs/PROJECT_BOOTSTRAPPER_DESIGN.md`).
Discovery interview system, pattern adaptation, GitHub integration. Not yet implemented.
This is the right next meta-project after STASH reaches 3B completion.

## Phase 3A: Spec-first + Sonnet/Opus model split established
Sonnet executes specs (speed + cost). Opus reviews architecture only (quality gate).
MANIFEST.md pattern prevents regenerating completed work across sessions.
80% test coverage required before any phase marked complete.
