# Feature Requests - 2026-02-11

## 1. Full Context for Voice-Captured Thoughts
**Priority:** High
**Status:** Planned (part of Siri integration)

**Issue:** Voice-captured thoughts (via Siri) currently use `Context.empty()` for speed. They're missing location, health, calendar, and activity data that in-app captures get.

**Desired behavior:**
- Voice-captured thoughts should have the same rich context as manual captures
- Location, health data, calendar events, activity, weather — all present
- No difference in context quality based on capture method

**Implementation notes:**
- Current: `CaptureThoughtIntent.perform()` uses minimal context for speed
- Solution: Fire context enrichment in background after initial save
- Pattern: Save fast with empty context → async enrich → update thought
- Already planned in `siri-integration-plan.md` Phase 1a

**Related:** Issue #27 (Siri Integration)

---

## 2. Dismissable Action Prompts
**Priority:** Medium
**Status:** New

**Issue:** Prompts like "add event to calendar" or task extraction appear repeatedly even after user ignores them. No way to permanently dismiss.

**Desired behavior:**
- Show prompt once (or until user acts)
- "Dismiss" button that permanently hides this specific prompt for this thought
- Or: "Don't ask again for this type" option
- Prompts should not re-appear on every view of the thought

**UX Pattern:**
```
┌─────────────────────────────────────┐
│ Add "Meeting with Sarah" to        │
│ calendar on Feb 12 at 2pm?          │
│                                     │
│ [Add to Calendar] [Dismiss] [×]     │
└─────────────────────────────────────┘
```

Where:
- **Add to Calendar** — creates event
- **Dismiss** — hides this prompt forever for this thought
- **×** — hides temporarily (might re-appear)

**Implementation notes:**
- Store dismissed prompts in thought metadata: `dismissedPrompts: ["calendar-event-123"]`
- Check before showing prompt
- OR: Add `userDismissed: Bool` field to auto-detected entities

**Affected screens:**
- DetailScreen (where prompts appear)
- ThoughtConversationScreen (AI suggestions)

---

## 3. Confirmation Dialogs for Calendar/Reminder Extraction
**Priority:** Low
**Status:** New (Design Decision Needed)

**Issue:** When STASH detects a calendar event or reminder in a thought, should it:
- A) Auto-create it silently (current)
- B) Show a confirmation dialog with editable parameters
- C) Make it user-configurable (setting toggle)

**User preference:** Leaning toward Option B or C

**Option B — Confirmation Dialog:**
```
┌─────────────────────────────────────┐
│ Create Calendar Event?              │
├─────────────────────────────────────┤
│ Title: Meeting with Sarah           │
│ Date:  Feb 12, 2026                 │
│ Time:  2:00 PM                      │
│ Duration: 1 hour                    │
│                                     │
│ [Edit] [Create] [Cancel]            │
└─────────────────────────────────────┘
```

**Option C — Setting Toggle:**
```
Settings → Capture
  ☐ Auto-create calendar events
  ☑ Ask before creating events
  ☐ Auto-create reminders
  ☑ Ask before creating reminders
```

**Trade-offs:**
- **Auto (current):** Fastest, but no control, mistakes happen
- **Confirmation:** Control + speed, one extra tap
- **Setting:** Best of both worlds, but requires user setup

**Recommendation:** Option C (setting-based) with default = "Ask before creating"

**Implementation notes:**
- Add `calendarAutoCreate` and `reminderAutoCreate` bools to Settings
- Show confirmation sheet when auto-create is disabled
- Confirmation sheet should be editable (title, date, time fields)
- "Don't ask again" checkbox to flip setting from dialog

**Related files:**
- `Sources/UI/ViewModels/CaptureViewModel.swift` (calendar integration logic)
- `Sources/UI/ViewModels/DetailViewModel.swift` (action prompts)
- `Sources/UI/Screens/SettingsScreen.swift` (toggle settings)

---

## Next Steps

1. **Context enrichment** — Already planned, part of Batch 2-4 implementation
2. **Dismissable prompts** — Add to Issue #27 or create separate issue
3. **Confirmation dialogs** — Decide on A/B/C approach, then spec it out
