# Initial GitHub Issues to Create

**After setting up labels and project board, create these initial issues**

These are your known bugs and planned features from Phase 3A completion.

---

## Known Bugs (Create These First)

### Issue #1: HealthKit step count not collecting properly

**Use template:** Bug Report

**Title:** `[Bug]: HealthKit step count returns 0 or null`

**Fill out form:**
- **iOS Version:** iOS 18+ (affects all versions)
- **App Version:** 0.1.0 (development)
- **Device:** All devices
- **What happened?**
  ```
  The HealthKit step count data is not being collected properly. The context
  snapshot often shows 0 steps or null, even when the user has granted
  HealthKit permissions and has step data in the Health app.
  ```
- **Steps to Reproduce:**
  ```
  1. Grant HealthKit permissions when prompted
  2. Ensure you have step data in Health app (walk around)
  3. Capture a thought
  4. Check energy breakdown or context data
  5. Step count is often 0 or missing
  ```
- **Expected Behavior:**
  ```
  Should show actual step count for today from HealthKit, matching what's
  in the Health app.
  ```
- **Actual Behavior:**
  ```
  Returns 0 or null for step count, even though data exists in Health app.
  ```
- **Additional Context:**
  ```
  This affects the energy calculation, which uses step count as 25% of the
  total energy score. Currently energy calculation falls back to other
  components when step count is missing.

  Location: Sources/Services/Context/HealthKitService.swift
  Likely issue: HKStatisticsQuery construction or permission check
  ```

**After creation:**
- Add labels: `priority: high`, `area: context`, remove `needs-triage`
- Add to project board → To Do
- Set custom field: Effort = Medium

---

### Issue #2: Location name occasionally blank

**Use template:** Bug Report

**Title:** `[Bug]: Reverse geocoding sometimes fails to produce location name`

**Fill out form:**
- **iOS Version:** iOS 18+ (affects all versions)
- **App Version:** 0.1.0 (development)
- **Device:** All devices
- **What happened?**
  ```
  When capturing a thought, the location name is sometimes blank/empty even
  though coordinates are available and the user has granted location permissions.
  ```
- **Steps to Reproduce:**
  ```
  1. Grant location permissions ("When in Use")
  2. Ensure location services are enabled
  3. Capture multiple thoughts in different locations
  4. Some thoughts have blank location name despite having coordinates
  ```
- **Expected Behavior:**
  ```
  Should reverse geocode coordinates to a human-readable location name like
  "San Francisco, CA" or "123 Main St, City, State"
  ```
- **Actual Behavior:**
  ```
  Occasionally returns empty string for location name, even though coordinates
  are present in the context snapshot.
  ```
- **Additional Context:**
  ```
  This is intermittent - sometimes it works fine, sometimes fails. Possibly
  related to:
  - CLGeocoder timeout
  - Rate limiting from Apple
  - Network connectivity
  - Background vs. foreground execution

  Location: Sources/Services/Context/LocationService.swift
  Manual refresh button usually works as a workaround

  This is cosmetic - doesn't affect core functionality, just missing context.
  ```

**After creation:**
- Add labels: `priority: medium`, `area: context`, remove `needs-triage`
- Add to project board → Backlog (lower priority than step count)
- Set custom field: Effort = Small

---

## High-Priority Feature Requests

### Issue #3: Smart date/time parsing

**Use template:** Feature Request

**Title:** `[Feature]: Parse natural language dates and times from thought content`

**Fill out form:**
- **Feature Description:**
  ```
  Parse natural language dates and times from thought content when creating
  reminders and events. For example, "Remind me to call mom tomorrow at 2pm"
  should automatically set the reminder for tomorrow at 2:00 PM.
  ```
- **Use Case:**
  ```
  Currently, when I capture a thought like "Meeting with John on Thursday at 3pm",
  the app creates a reminder or event but I have to manually pick the date and time.

  This breaks the flow and makes quick capture tedious. I want to just speak or type
  naturally and have the app understand when things should happen.

  Examples:
  - "tomorrow at 2pm" → Set for tomorrow at 14:00
  - "next Thursday" → Set for next Thursday (reasonable default time)
  - "in 2 hours" → Set for 2 hours from now
  - "January 15th" → Set for Jan 15 (reasonable default time)
  ```
- **Proposed Solution:**
  ```
  Enhance the Classification model to:
  1. Extract date/time entities from thought content
  2. Parse natural language dates using a library or API
  3. Pre-fill date/time when creating reminders/events
  4. Fall back to manual picker if parsing fails or is ambiguous

  Could use:
  - NSDataDetector (built-in iOS date detection)
  - Custom regex patterns
  - Or backend NLP service (when backend is set up)
  ```
- **Alternatives Considered:**
  ```
  - Manual date picker (current approach) - works but tedious
  - Voice shortcuts ("Hey Siri, remind me...") - doesn't capture context
  ```
- **How important:** Would improve my workflow - I'd use this regularly

**After creation:**
- Add labels: `priority: high`, `area: ai`, remove `needs-triage`
- Add to project board → Backlog (planned for Phase 4)
- Add milestone: "Phase 4: Intelligence & Automation"
- Set custom field: Effort = Large

---

### Issue #4: Calendar selection settings

**Use template:** Feature Request

**Title:** `[Feature]: Choose which calendar to add events to`

**Fill out form:**
- **Feature Description:**
  ```
  Add settings to let users choose which calendar events are added to, and which
  reminder list reminders are added to.
  ```
- **Use Case:**
  ```
  I have multiple calendars (Work, Personal, Family) and multiple reminder lists.
  When STASH creates an event or reminder, it currently goes to the default
  calendar/list.

  I want work-related thoughts to create events in my Work calendar, and personal
  thoughts to go to my Personal calendar.

  Ideal workflow:
  - Settings screen has "Default Calendar" picker
  - Settings screen has "Default Reminder List" picker
  - Maybe in the future: auto-detect which calendar based on thought content
  ```
- **Proposed Solution:**
  ```
  Add to Settings screen:
  - Calendar picker (shows all available calendars from EventKit)
  - Reminder list picker (shows all reminder lists)
  - Save user preference to UserDefaults
  - Use selected calendar/list when creating events/reminders

  Future enhancement: AI could suggest calendar based on content
  (e.g., "team meeting" → Work calendar)
  ```
- **Alternatives Considered:**
  ```
  - Manual editing after creation (current workaround) - tedious
  - Always use default calendar - doesn't work for multi-calendar users
  ```
- **How important:** Would improve my workflow - I'd use this regularly

**After creation:**
- Add labels: `priority: high`, `area: ui`, `area: context`, remove `needs-triage`
- Add to project board → Backlog (planned for Phase 4)
- Add milestone: "Phase 4: Intelligence & Automation"
- Set custom field: Effort = Medium

---

## Enhancement Ideas (Lower Priority)

### Issue #5: Search and filter thoughts

**Use template:** Feature Request

**Title:** `[Feature]: Search and filter thoughts by date, type, sentiment, tags`

**Fill out form:**
- **Feature Description:**
  ```
  Add search and filtering capabilities to the thought list:
  - Search by text content
  - Filter by date range
  - Filter by classification type
  - Filter by sentiment
  - Filter by tags
  ```
- **Use Case:**
  ```
  As my thought collection grows (100s of thoughts), I need ways to find specific
  thoughts or review thoughts from a specific time period.

  Examples:
  - "Show me all tasks from last week"
  - "Show me all ideas about [project name]"
  - "Show me happy thoughts from December"
  ```
- **Proposed Solution:**
  ```
  Add search bar at top of thought list with filter chips:
  [Search: ___________] [Filters: Date ▼ | Type ▼ | Sentiment ▼ | Tags ▼]

  Could use Core Data predicates for efficient filtering.
  ```
- **How important:** Would improve my workflow - I'd use this regularly

**After creation:**
- Add labels: `priority: medium`, `area: ui`, remove `needs-triage`
- Add to project board → Backlog (future phase)
- Set custom field: Effort = Large

---

### Issue #6: Batch operations on thoughts

**Use template:** Feature Request

**Title:** `[Feature]: Select multiple thoughts for bulk actions`

**Fill out form:**
- **Feature Description:**
  ```
  Add ability to select multiple thoughts and perform bulk actions:
  - Bulk delete
  - Bulk tag application
  - Bulk archive
  ```
- **Use Case:**
  ```
  Sometimes I want to clean up old thoughts or tag a bunch of related thoughts
  at once. Currently I have to do it one by one, which is tedious.
  ```
- **Proposed Solution:**
  ```
  Add "Edit" button to thought list that enables multi-select mode:
  - Checkboxes appear on each thought
  - Action bar at bottom with: Delete, Tag, Archive
  - Select all / deselect all option
  ```
- **How important:** Nice to have - would be cool but not essential

**After creation:**
- Add labels: `priority: low`, `area: ui`, remove `needs-triage`
- Add to project board → Backlog (future)
- Set custom field: Effort = Medium

---

## Documentation Tasks

### Issue #7: Add unit tests for core services

**Use template:** Feature Request (or create custom "Technical Task" template)

**Title:** `[Tech Debt]: Add unit tests for ViewModels and Services`

**Fill out form:**
- **Feature Description:**
  ```
  Add unit test coverage for:
  - ViewModels (CaptureViewModel, BrowseViewModel, etc.)
  - Services (ClassificationService, ContextService, etc.)
  - Models (data validation, computed properties)

  Target: 70% code coverage
  ```
- **Use Case:**
  ```
  Currently there are minimal tests. This makes refactoring risky and slows
  down development because I'm afraid of breaking things.

  With good test coverage:
  - Can refactor with confidence
  - Catch bugs before they reach users
  - Document expected behavior
  ```
- **How important:** Would improve my workflow - essential for long-term maintainability

**After creation:**
- Add labels: `priority: medium`, `area: testing`, `technical-debt`, remove `needs-triage`
- Add to project board → Backlog (before Phase 4)
- Set custom field: Effort = Epic

---

## Instructions for Creating Issues

1. **Go to your repo's Issues tab**
2. **Click "New issue"**
3. **Choose the appropriate template**
4. **Copy the content from above** and fill out the form
5. **Submit issue**
6. **After creation:**
   - Apply labels (remove `needs-triage`, add priority and area)
   - Add to project board
   - Set custom fields if configured
   - Add to milestone if applicable

---

## Suggested Order of Creation

1. Bug #1 (step count) - High priority
2. Bug #2 (location name) - Medium priority
3. Feature #3 (date parsing) - High priority, Phase 4
4. Feature #4 (calendar selection) - High priority, Phase 4
5. Feature #5 (search/filter) - Medium priority, future
6. Feature #6 (batch operations) - Low priority, future
7. Task #7 (unit tests) - Medium priority, before Phase 4

This gives you:
- 2 active bugs to fix
- 4 feature requests to plan
- 1 technical debt item to address

---

## After Creating Issues

### Immediate (Today)
- Create the high-priority issues (#1-4)
- Organize on project board
- You now have a backlog to work from!

### This Week
- Triage and prioritize
- Decide: Fix bugs first, or continue with Phase 4 features?
- Update CUSTOMER_REQUESTS.md to link to GitHub issues

### Ongoing
- Create new issues as bugs/ideas arise
- Reference issues in commits: `git commit -m "Fix step count (#1)"`
- Close issues when complete

---

**Total time to create these 7 issues:** ~30-45 minutes

**Benefit:** Clear tracking of all known work, organized backlog, foundation for project management
