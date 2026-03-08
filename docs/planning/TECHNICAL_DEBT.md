# Technical Debt & Implementation Notes

**Last Updated:** 2026-01-20

## Purpose

Track technical debt, known issues, workarounds, and areas needing refactoring. This helps prioritize cleanup work and prevents accumulation of problematic code.

---

## Technical Debt Items

### High Priority

#### TD-001: HealthKit Step Count Collection
- **Category:** Bug/Implementation Issue
- **Description:** Step count from HealthKit is not being collected properly, sometimes returns 0
- **Impact:** Affects energy calculation accuracy (25% weight)
- **Root Cause:** Likely query construction or permission handling issue
- **Location:** `Sources/Services/Context/HealthKitService.swift`
- **Workaround:** None currently
- **Fix Estimate:** 2-4 hours
- **Priority:** High (affects core feature)
- **Related:** BUG-001 in CUSTOMER_REQUESTS.md

#### TD-002: Location Name Geocoding Reliability
- **Category:** Bug/Inconsistency
- **Description:** Reverse geocoding occasionally fails to produce location name despite valid coordinates
- **Impact:** Missing location context in thought snapshots
- **Root Cause:** Possible CLGeocoder timeout or rate limiting
- **Location:** `Sources/Services/Context/LocationService.swift`
- **Workaround:** Manual refresh button available
- **Fix Estimate:** 2-3 hours
- **Priority:** Medium (cosmetic, doesn't break core functionality)
- **Related:** BUG-002 in CUSTOMER_REQUESTS.md

### Medium Priority

#### TD-003: Classification Service Coupling
- **Category:** Architecture/Coupling
- **Description:** ClassificationService is currently using a mock/local implementation but expects future backend integration
- **Impact:** Will require refactoring when backend is added
- **Location:** `Sources/Services/AI/ClassificationService.swift`
- **Proposed Fix:**
  - Create `ClassificationProvider` protocol
  - Implement `LocalClassificationProvider` and `RemoteClassificationProvider`
  - Inject provider into service
- **Fix Estimate:** 4-6 hours
- **Priority:** Medium (planning ahead for Phase 5)

#### TD-004: Error Handling Consistency
- **Category:** Code Quality
- **Description:** Error handling patterns vary across services (some throw, some return optionals, some use Result type)
- **Impact:** Inconsistent error propagation and handling
- **Location:** Various service files
- **Proposed Fix:** Standardize on Result<T, Error> for service methods
- **Fix Estimate:** 6-8 hours (affects many files)
- **Priority:** Medium (affects maintainability)

#### TD-005: Core Data Concurrency
- **Category:** Performance/Threading
- **Description:** Some Core Data operations may not be properly isolated to background contexts
- **Impact:** Potential UI blocking on main thread
- **Location:** `Sources/Services/Persistence/PersistenceService.swift`
- **Proposed Fix:** Audit all Core Data calls, ensure proper context usage
- **Fix Estimate:** 4-5 hours
- **Priority:** Medium (affects user experience)

### Low Priority

#### TD-006: Test Coverage Gaps
- **Category:** Testing
- **Description:** No unit tests for ViewModels and many service methods
- **Impact:** Harder to refactor with confidence
- **Location:** `/Tests/` directory
- **Fix Estimate:** 10-15 hours for 70% coverage
- **Priority:** Low (but should increase for Phase 4)
- **Related:** TESTING_STRATEGY.md

#### TD-007: Hardcoded Strings
- **Category:** Code Quality/i18n
- **Description:** Many UI strings are hardcoded rather than using localization
- **Impact:** Future internationalization will be more difficult
- **Location:** Various UI files
- **Proposed Fix:** Extract to Localizable.strings
- **Fix Estimate:** 3-4 hours
- **Priority:** Low (unless i18n becomes priority)

#### TD-008: Magic Numbers in Energy Calculation
- **Category:** Code Quality/Maintainability
- **Description:** Energy calculation weights are hardcoded (40%, 25%, 20%, 15%)
- **Impact:** Hard to experiment with different weight distributions
- **Location:** `Sources/Services/Context/ContextService.swift`
- **Proposed Fix:** Extract to configuration or settings
- **Fix Estimate:** 1-2 hours
- **Priority:** Low (current weights working well)

---

## Code Smells & Refactoring Candidates

### CS-001: Large ViewModel Classes
- **Description:** Some ViewModels (e.g., CaptureViewModel) are growing large with multiple responsibilities
- **Impact:** Harder to test and maintain
- **Proposed Fix:** Extract concerns into smaller, focused ViewModels or helper classes
- **Priority:** Low (wait until ViewModels exceed ~300 lines)

### CS-002: Duplicate Permission Logic
- **Description:** Permission handling code is similar across LocationService, HealthKitService, CalendarService
- **Impact:** Duplication, potential for inconsistency
- **Proposed Fix:** Create `PermissionHandler` protocol and shared utilities
- **Priority:** Low (current duplication manageable)

### CS-003: Context Model Growing
- **Description:** Context struct is accumulating many optional properties
- **Impact:** Harder to reason about what's available when
- **Proposed Fix:** Consider breaking into smaller, focused context types (LocationContext, HealthContext, etc.)
- **Priority:** Low (current structure reasonable for now)

---

## Implementation Notes & Decisions

### IN-001: Deployment Target Strategy
- **Date:** 2026-01-19
- **Decision:** Initially set iOS 26.0 deployment target, then reverted to iOS 18
- **Reasoning:** iOS 26 APIs caused build issues; iOS 18 provides good market coverage
- **Impact:** Need to avoid iOS 26+ exclusive APIs
- **Review:** Consider iOS 19 minimum when adoption reaches 80%

### IN-002: Energy Calculation Formula
- **Date:** Phase 3A
- **Decision:** Use weighted average: Sleep 40%, Activity 25%, HRV 20%, Time 15%
- **Reasoning:** Sleep has largest impact on energy, time of day provides baseline rhythm
- **Data Source:** Initial hypothesis, to be validated with user feedback
- **Review:** Monitor user feedback, consider making weights configurable

### IN-003: Context Gathering Timeout
- **Date:** Phase 3A
- **Decision:** 300ms target for cached context gathering
- **Reasoning:** Balance between comprehensive context and UX responsiveness
- **Implementation:** Parallel TaskGroup with fail-soft pattern
- **Review:** Monitor actual performance, adjust if needed

### IN-004: Classification Model Choice
- **Date:** Phase 3A
- **Decision:** Start with simple local classification (mock/rule-based)
- **Reasoning:** Get app working end-to-end before investing in ML infrastructure
- **Future:** Transition to cloud-based model with fine-tuning in Phase 5
- **Review:** When backend is ready (Phase 5)

### IN-005: Permission Fail-Soft Pattern
- **Date:** Phase 3A
- **Decision:** All features work with degraded functionality when permissions denied
- **Reasoning:** Avoid blocking users who are privacy-conscious
- **Examples:**
  - Location denied → still capture thought, just no location context
  - HealthKit denied → still calculate energy from time of day only
- **Review:** Monitor if lack of permissions significantly degrades UX

---

## Performance Optimization Opportunities

### PO-001: Context Caching Strategy
- **Current:** Basic caching with time-based invalidation
- **Opportunity:** Smarter invalidation based on significant changes (location moved >100m, time >30min, etc.)
- **Impact:** Reduce unnecessary HealthKit/Location queries
- **Effort:** 3-4 hours
- **Priority:** Low (current caching working well)

### PO-002: Thought List Pagination
- **Current:** Load all thoughts into memory
- **Opportunity:** Implement pagination/infinite scroll
- **Impact:** Better performance with 1000+ thoughts
- **Effort:** 6-8 hours
- **Priority:** Low (defer until users have >500 thoughts)

### PO-003: Image/Audio Attachment Lazy Loading
- **Current:** Not implemented yet
- **Opportunity:** Design for lazy loading from start when adding media support
- **Impact:** Prevent memory bloat with many media attachments
- **Effort:** 4-6 hours (when implementing media)
- **Priority:** Future (Phase 6)

---

## Dependency & Library Decisions

### LD-001: No Third-Party Dependencies (Currently)
- **Date:** Phase 3A
- **Decision:** Use only Apple frameworks and Swift standard library
- **Reasoning:**
  - Reduce complexity and security surface
  - No dependency management overhead
  - Faster compile times
- **Reconsider When:**
  - Backend integration (will need HTTP client, possibly Supabase SDK)
  - Advanced ML (may need additional frameworks)
  - Analytics (Sentry, Mixpanel, etc.)

### LD-002: Core Data for Persistence
- **Date:** Phase 3A
- **Decision:** Use Core Data despite newer alternatives (SwiftData)
- **Reasoning:**
  - Mature, well-documented
  - Better control over migration
  - Compatible with iOS 18+
- **Alternatives Considered:** SwiftData (too new, limited iOS 17+), Realm (adds dependency)
- **Review:** Consider SwiftData when iOS 17 adoption >80%

---

## Migration & Deprecation Plans

### MP-001: Data Model Migrations
- **Current Version:** Version 1 (Phase 3A)
- **Strategy:** Lightweight migrations for simple changes, heavyweight for complex
- **Test Plan:** Create migration tests with realistic data sets
- **Rollback Plan:** Maintain previous app versions for emergency downgrades

### MP-002: API Versioning (Future)
- **Strategy:** Semantic versioning for backend API (v1, v2, etc.)
- **Backwards Compatibility:** Support N-1 version for smooth upgrades
- **Deprecation Policy:** 6-month notice before removing API versions

---

## Lessons Learned

### LL-001: EventKit Permission Complexity
- **Issue:** EventKit requires separate permissions for events and reminders
- **Learning:** Always check both permissions, auto-request when needed
- **Applied:** Added comprehensive permission handling and debug logging
- **Location:** Commits around 2026-01-15 (see git log)

### LL-002: Actor Isolation Challenges
- **Issue:** SpeechService actor isolation caused issues with @MainActor ViewModels
- **Learning:** Carefully consider actor boundaries, use nonisolated where appropriate
- **Applied:** Fixed with proper async/await boundaries
- **Location:** Commit 79015ae

### LL-006: Apple Watch Architecture Decisions
- **Issue:** Watch apps require deliberate scoping — too little and it feels like a gimmick, too much and it becomes a maintenance burden for a solo developer.
- **Learning:** For v1, restrict Watch to voice capture only. No browsing, no gamification detail, no text input. Classification stays on iPhone — never run ML on Watch. Offline queue is non-negotiable; capture must work when iPhone is unreachable.
- **Applied:** Native watchOS target with single capture screen, WatchConnectivity sync, local queue persistence, 3-tier variable reward acknowledgment animations, complications in Circular/Modular/Graphic Rectangular families.
- **Location:** New watchOS target — `WatchApp/`, `Sources/Services/Framework/PhoneConnectivityManager.swift`
- **Review:** After v1 ships, evaluate whether Watch users want read access to recent thoughts. Resist scope creep until data supports it.

### LL-004: Tag Generation Creates Word Fragments
- **Issue:** Keyword-based fallback in `ClassificationService.generateTags()` splits compound concepts into individual lemmas. "Server issues" becomes "server" + "issues" rather than "server-issues". Affects all devices without Foundation Models (iPhone 14 and below, iPhone 15 non-Pro).
- **Learning:** NLP lemmatization must detect noun phrases as compound units before splitting. Individual word extraction is insufficient for meaningful tag generation.
- **Applied:** GitHub Issue filed — implement bigram/phrase detection using NLTagger `.noun` scheme before falling back to individual keywords.
- **Location:** `Sources/Services/Intelligence/ClassificationService.swift` — `generateTags(content:entities:)`, `extractKeywords(from:)`

### LL-005: Tag Fragmentation from Lack of Library Awareness
- **Issue:** Tag input and AI classification have no awareness of the user's existing tag library. Results in multiple variants of the same concept ("server issues", "server-issues", "serverissues").
- **Learning:** The user's own tag history is the best normalization signal available. Fuzzy matching against existing tags should be the first step before creating anything new.
- **Applied:** GitHub Issue filed — implement `TagNormalizationService` with fuzzy matching (prefix, contains, Levenshtein, hyphen/space normalization). Surface suggestions in `TagInputView` as user types. Cross-reference in `ClassificationService` before returning suggested tags.
- **Location:** `Sources/UI/Components/TagInputView.swift`, `Sources/Services/Intelligence/ClassificationService.swift`, new `TagNormalizationService.swift`

### LL-003: Core Data Attribute Naming
- **Issue:** Mismatch between Core Data entity attribute names and Swift property names
- **Learning:** Use Xcode code generation or be very explicit with @NSManaged
- **Applied:** Fixed FineTuningDataEntity naming mismatch
- **Location:** Commit fac5a79

---

## Review Cadence

- **Weekly:** Review new debt items, prioritize
- **Monthly:** Address 1-2 high-priority items
- **Quarterly:** Refactoring sprint for medium-priority items
- **Per Phase:** Major cleanup and architectural improvements

---

## Next Cleanup Sprint

**Target:** Before Phase 4 implementation

**Focus Areas:**
1. Fix HealthKit step count collection (TD-001)
2. Improve location name reliability (TD-002)
3. Add basic unit test coverage (TD-006)
4. Standardize error handling (TD-004)

**Estimated Effort:** 1-2 weeks
