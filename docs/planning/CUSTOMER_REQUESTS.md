# Customer Requests & Feedback

**Last Updated:** 2026-01-20

## Purpose

This document tracks feature requests, bug reports, and feedback from users. Each item should be categorized, prioritized, and linked to implementation tracking.

---

## Feature Requests

### High Priority

#### FR-001: Smart Date/Time Parsing
- **Requested By:** Internal (planned feature)
- **Date:** 2026-01-19
- **Description:** Parse natural language dates and times from thought content
- **Use Case:** "Remind me to call mom tomorrow at 2pm" should auto-populate date/time
- **Status:** Planned for Phase 4
- **Related Issues:** None yet
- **Notes:** See FEATURES.md for detailed spec

#### FR-002: Calendar Selection
- **Requested By:** Internal (planned feature)
- **Date:** 2026-01-19
- **Description:** Allow users to choose which calendar to add events to
- **Use Case:** Work events → Work calendar, Personal → Personal calendar
- **Status:** Planned for Phase 4
- **Related Issues:** None yet
- **Priority Justification:** Essential for users with multiple calendars

### Medium Priority

#### FR-003: Search Filters
- **Requested By:** Internal (planned feature)
- **Date:** 2026-01-19
- **Description:** Advanced search with filters (date range, type, sentiment, tags)
- **Use Case:** Find all tasks from last week, or all happy notes
- **Status:** Planned for future
- **Related Issues:** None yet

#### FR-004: Batch Operations
- **Requested By:** Internal (planned feature)
- **Date:** 2026-01-19
- **Description:** Select multiple thoughts for bulk actions (tag, archive, delete)
- **Use Case:** Clean up old thoughts efficiently
- **Status:** Planned for future
- **Related Issues:** None yet

### Low Priority

#### FR-005: Dark Mode Customization
- **Requested By:** TBD (example)
- **Date:** TBD
- **Description:** Allow customization of dark mode colors
- **Status:** Not planned
- **Notes:** iOS already has system dark mode

---

## Bug Reports

### Critical

*None currently*

### High Priority

#### BUG-001: Step Count Not Collecting
- **Reported By:** Internal testing
- **Date:** 2026-01-19
- **Description:** HealthKit step count not being collected properly
- **Steps to Reproduce:**
  1. Grant HealthKit permissions
  2. Capture thought
  3. Check context data
  4. Step count is 0 or missing
- **Expected Behavior:** Should show actual step count for the day
- **Actual Behavior:** Returns 0 or null
- **Status:** Investigating
- **Priority:** High (affects energy calculation)
- **Assigned To:** TBD
- **Related Code:** `Sources/Services/Context/HealthKitService.swift`

#### BUG-002: Location Name Sometimes Blank
- **Reported By:** Internal testing
- **Date:** 2026-01-19
- **Description:** Location name occasionally shows as blank even when coordinates available
- **Steps to Reproduce:**
  1. Grant location permissions
  2. Capture thought
  3. Sometimes location name is empty
- **Expected Behavior:** Should reverse geocode coordinates to location name
- **Actual Behavior:** Occasionally returns empty string
- **Status:** Investigating
- **Priority:** Medium (cosmetic, doesn't affect core functionality)
- **Assigned To:** TBD
- **Related Code:** `Sources/Services/Context/LocationService.swift`

### Medium Priority

*None currently*

### Low Priority

*None currently*

---

## User Feedback

### Positive Feedback

*Track what users love - helps prioritize keeping these experiences great*

#### FB-001: Voice Input
- **From:** Internal testing
- **Date:** 2026-01-19
- **Feedback:** "Voice input is incredibly fast and accurate"
- **Action:** Ensure voice quality remains high in future updates

#### FB-002: Energy Tracking
- **From:** Internal testing
- **Date:** 2026-01-19
- **Feedback:** "Energy tracking is surprisingly insightful"
- **Action:** Consider surfacing energy insights more prominently

### Constructive Feedback

*Areas for improvement*

#### FB-003: Manual Date Entry
- **From:** Internal testing
- **Date:** 2026-01-19
- **Feedback:** "Having to manually pick dates for events is tedious"
- **Action:** Prioritize smart date/time parsing (FR-001)
- **Status:** Planned

---

## Categorization Guidelines

### Priority Levels

**Critical:** App-breaking, data loss, security issues
**High:** Major functionality impaired, significant user friction
**Medium:** Minor functionality issues, nice-to-have features
**Low:** Cosmetic issues, edge cases, future enhancements

### Status Values

**New:** Just reported, not yet triaged
**Investigating:** Team is looking into it
**Planned:** Accepted, scheduled for implementation
**In Progress:** Actively being worked on
**Completed:** Implemented and deployed
**Won't Fix:** Decided not to implement (with reasoning)
**Duplicate:** Same as another issue (link to primary)

---

## Request Template

When adding new requests, use this template:

```markdown
#### [TYPE]-[NUMBER]: [Brief Title]
- **Requested/Reported By:** [Name/source]
- **Date:** [YYYY-MM-DD]
- **Description:** [Detailed description]
- **Use Case / Steps to Reproduce:** [Context or reproduction steps]
- **Expected Behavior:** [What should happen]
- **Actual Behavior:** [What actually happens - bugs only]
- **Status:** [New/Investigating/Planned/etc.]
- **Priority:** [Critical/High/Medium/Low]
- **Assigned To:** [Developer name or TBD]
- **Related Issues:** [Links to related items]
- **Related Code:** [File paths if known]
- **Notes:** [Any additional context]
```

---

## Integration with Development

### Linking to Implementation
- Feature requests → Update `FEATURES.md` with detailed specs
- Bugs → Create GitHub issues or track in project management tool
- High-priority items → Add to sprint planning

### Review Cadence
- **Weekly:** Review new submissions, triage priority
- **Bi-weekly:** Update status on in-progress items
- **Monthly:** Analyze trends, adjust roadmap

---

## Analytics Integration

*Once analytics are set up, track:*

- Feature usage rates (which features are most/least used?)
- User retention by feature adoption
- Common user paths and friction points
- Crash rates and error frequencies

---

## Resources

- Link to bug tracking system: TBD
- Link to user feedback form: TBD
- Link to public roadmap: TBD
