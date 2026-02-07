# App Store Release Process

**Last Updated:** 2026-01-20

## Purpose

Document a repeatable, reliable process for releasing updates to the App Store. Prevents shipping broken builds and ensures quality.

---

## Release Philosophy

**Key Principles:**
1. **Never rush a release** - Broken builds damage trust
2. **Test before shipping** - Always run full test suite
3. **Communicate clearly** - Users should know what changed
4. **Version consistently** - Follow semantic versioning
5. **Have a rollback plan** - Know how to revert if needed

---

## Versioning Strategy

Use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

### Version Number Meaning
- **MAJOR (1.x.x):** Breaking changes, major redesigns
  - Example: 1.0.0 → 2.0.0 (complete UI overhaul)

- **MINOR (x.1.x):** New features, significant enhancements
  - Example: 1.0.0 → 1.1.0 (added smart date parsing)

- **PATCH (x.x.1):** Bug fixes, small improvements
  - Example: 1.1.0 → 1.1.1 (fixed crash bug)

### Build Number
- Increments with every TestFlight or App Store build
- Never reuse build numbers
- Format: Integer starting at 1

**Example progression:**
- `1.0.0 (1)` - Initial release
- `1.0.1 (2)` - Bug fix
- `1.0.2 (3)` - Another bug fix
- `1.1.0 (4)` - New feature
- `1.1.1 (5)` - Bug fix for new feature

---

## Release Cadence

### Recommended Schedule

**Patch releases (x.x.1):**
- As needed for critical bugs
- Usually within 1-3 days of bug discovery
- No fixed schedule

**Minor releases (x.1.0):**
- Every 2-4 weeks
- Contains new features + bug fixes
- Scheduled cadence helps users know when to expect updates

**Major releases (2.0.0):**
- Rare (1-2 times per year max)
- Only for significant changes

### Monthly Release Cycle Example

**Week 1:** Planning
- Review feature requests
- Plan features for the month
- Update roadmap

**Week 2-3:** Development
- Build features
- Fix bugs
- Write tests

**Week 4:** Release
- Code freeze (Monday)
- Testing (Mon-Wed)
- TestFlight beta (Thursday)
- App Store submission (Friday)
- Release to users (following Tuesday)

---

## Pre-Release Checklist

### 1. Code Freeze
**When:** 3-5 days before planned release

**Actions:**
- [ ] Merge all planned features to `main` branch
- [ ] No new features after this point
- [ ] Bug fixes only

**Create release branch:**
```bash
git checkout -b release/v1.2.0
```

### 2. Testing Phase

#### Automated Tests
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All UI tests passing (if you have them)
- [ ] Code coverage ≥70% (check in Xcode)

```bash
# Run tests from command line
xcodebuild test \
  -scheme STASH \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

#### Manual Testing Checklist

**Core Functionality:**
- [ ] Capture thought with text input
- [ ] Capture thought with voice input
- [ ] Edit existing thought
- [ ] Delete thought (with confirmation)
- [ ] Add/remove tags
- [ ] Create task from thought
- [ ] Create reminder from thought
- [ ] Create event from thought
- [ ] Submit feedback on classification

**Context Gathering:**
- [ ] Location captured accurately
- [ ] Location name displays correctly
- [ ] Energy level calculated
- [ ] HealthKit data included (if permissions granted)
- [ ] Calendar availability showing

**Permissions:**
- [ ] Location permission request works
- [ ] HealthKit permission request works
- [ ] Calendar permission request works
- [ ] Microphone permission request works
- [ ] App works with permissions denied (fail-soft)

**UI/UX:**
- [ ] No visual glitches
- [ ] Smooth scrolling in thought list
- [ ] No crashes during normal use
- [ ] Dark mode looks correct
- [ ] All buttons/interactions work

**Edge Cases:**
- [ ] Offline mode (airplane mode)
- [ ] Low battery mode
- [ ] Low storage warning
- [ ] Very long thought content (>1000 characters)
- [ ] Special characters in input (emoji, unicode)

**Device Testing:**
- [ ] iPhone SE (small screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPhone 15 Pro Max (large screen)
- [ ] iPad (if supporting)

**iOS Version Testing:**
- [ ] iOS 18.0 (minimum supported)
- [ ] Latest iOS version

### 3. Update Version Numbers

**In Xcode:**
1. Select project in navigator
2. Select target "STASH"
3. General tab
4. Update "Version" (e.g., 1.2.0)
5. Update "Build" (increment by 1)

**Verify in code:**
```bash
# Check Info.plist values
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" STASH/Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" STASH/Info.plist
```

### 4. Update Release Notes

Create `CHANGELOG.md` in repo root (if not exists):

```markdown
# Changelog

All notable changes to STASH will be documented in this file.

## [1.2.0] - 2026-02-15

### Added
- Smart date/time parsing from natural language
- Calendar selection in settings
- Event duration intelligence

### Fixed
- Fixed crash when creating events (#47)
- Fixed step count not being collected (#23)
- Improved location name accuracy

### Changed
- Updated energy calculation to include HRV
- Improved UI performance in thought list

## [1.1.0] - 2026-01-20
...
```

**App Store "What's New" notes (max 4000 characters):**

Write user-friendly, benefit-focused notes:

```
✨ What's New in 1.2.0

NEW FEATURES
• Smart Date Parsing - Just say "tomorrow at 2pm" and we'll set it automatically
• Choose Your Calendar - Pick which calendar events are added to
• Smarter Event Durations - We now detect how long events should be

BUG FIXES
• Fixed crash when creating calendar events
• Improved step count tracking accuracy
• Location names now load more reliably

IMPROVEMENTS
• Faster performance when browsing thoughts
• Better energy level calculations

As always, thanks for using STASH! Questions or feedback? Tap Help in Settings.
```

**Tips for good release notes:**
- Lead with what's new and exciting
- Use emojis sparingly (one per section)
- Focus on benefits, not technical details
- Keep it concise and scannable
- Thank users

### 5. Build Archive

**In Xcode:**
1. Select "Any iOS Device (arm64)" as destination
2. Product → Archive
3. Wait for build to complete
4. Organizer window opens automatically

**Common build errors:**
- Signing issues: Check certificates in Xcode settings
- Missing dependencies: Run `swift package resolve`
- Build errors: Fix and try again

### 6. Upload to App Store Connect

**In Organizer:**
1. Select the archive you just created
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Click "Next"
5. Choose "Upload"
6. Select signing options:
   - Automatically manage signing (recommended)
   - Or: Manual signing if you have specific needs
7. Click "Upload"
8. Wait for upload to complete (5-10 min)

**Verify upload:**
1. Go to App Store Connect (appstoreconnect.apple.com)
2. My Apps → STASH
3. TestFlight tab
4. Should see new build processing

### 7. TestFlight Beta Testing (Optional but Recommended)

**After build finishes processing (30-60 min):**

1. In App Store Connect, go to TestFlight tab
2. Select the build
3. Add "What to Test" notes for testers:
   ```
   Thanks for testing 1.2.0!

   Please focus on:
   - New smart date parsing feature (try "tomorrow at 2pm")
   - Calendar selection in settings
   - Any crashes or bugs

   Known issues:
   - None currently

   Feedback: Use in-app feedback or email support@yourapp.com
   ```

4. Add testers (Internal: development team, External: beta users)
5. Click "Submit for Beta Review" (if external testing)

**Beta testing period:**
- Internal testers: 1-2 days
- External testers: 3-5 days
- Fix any critical bugs found
- If critical bugs found, fix and re-submit (don't release to App Store)

### 8. App Store Submission

**When beta testing complete and no critical bugs:**

1. In App Store Connect, go to App Store tab
2. Click "+ Version" under "iOS App"
3. Enter version number (1.2.0)
4. Fill out the form:

**Version Information:**
- **What's New:** Paste your release notes (from step 4)
- **Promotional Text:** (Optional) Short promo for this update
- **Description:** (Only edit if changed)
- **Keywords:** (Only edit if changed)
- **Support URL:** Link to help docs or website
- **Marketing URL:** (Optional) Your website

**Build:**
- Click "Select a build" and choose your uploaded build

**App Review Information:**
- **Demo Account:** (If app requires login, provide test credentials)
- **Notes for Reviewer:**
  ```
  This update adds smart date parsing and calendar selection features.

  To test:
  1. Capture a thought like "Remind me tomorrow at 2pm"
  2. Notice the date/time is automatically set
  3. Go to Settings → Calendar to choose calendar

  Permissions needed:
  - Location (for context gathering)
  - HealthKit (for energy tracking)
  - Calendar/Reminders (for creating events/reminders)
  - Microphone (for voice input)

  Please grant all permissions to test full functionality.
  ```

**Version Release:**
- **Manually release this version:** (Recommended for control)
- Or: **Automatically release after approval**

5. Click "Save"
6. Click "Submit for Review"

**App Review Process:**
- Usually 1-2 days
- Can be longer during holidays
- You'll get email when approved or rejected

### 9. Monitor Submission Status

**Check App Store Connect daily:**
- "Waiting for Review" → "In Review" → "Pending Developer Release" (or "Ready for Sale")

**If rejected:**
- Read rejection reason carefully
- Common reasons:
  - Missing functionality in reviewer's test
  - Confusing permissions requests
  - Crashes during review
  - Privacy policy issues
- Fix the issue
- Reply to reviewer with explanation
- Resubmit

**If approved:**
- You'll see "Pending Developer Release" (if manual release)
- Click "Release this Version" when ready
- Or: Automatically released if you chose auto-release

---

## Release Day

### When to Release

**Best days:** Tuesday, Wednesday, Thursday
- Avoid Monday (users busy catching up)
- Avoid Friday (if bugs found, you're working weekend)
- Avoid holidays

**Best times:** Morning (9-11am PST)
- Gives you full day to monitor for issues
- Users in US are awake

### Monitoring After Release

**First 24 hours (critical):**

**Check every 2-4 hours:**
- [ ] App Store Connect → Crashes (any spike?)
- [ ] Firebase Crashlytics (if set up) → Crash rate
- [ ] Support email → Any urgent bug reports?
- [ ] App Store reviews → Any new critical reviews?

**What to watch for:**
- Crash rate >2% → Investigate immediately
- Multiple reports of same bug → Potential critical issue
- App Store reviews mentioning crashes/bugs → Check crash logs

**If critical bug found:**
1. Assess severity (Is app unusable? Affects all users or subset?)
2. If severe: Immediately start working on hotfix
3. Follow expedited release process (skip beta testing if needed)
4. Submit as "Bug Fix" with explanation for fast review
5. Communicate to users via social/email if severe

**Days 2-7:**
- [ ] Daily check of crash reports
- [ ] Respond to App Store reviews
- [ ] Monitor support volume (spike = possible issue)
- [ ] Track user feedback on new features

**Week 2+:**
- [ ] Analyze adoption of new version (App Store Connect → Metrics)
- [ ] Review feature usage (if you have analytics)
- [ ] Plan next release based on feedback

---

## Rollback Plan

**If catastrophic bug shipped:**

**Option 1: Hotfix (Preferred)**
1. Fix bug immediately
2. Increment patch version (1.2.0 → 1.2.1)
3. Submit for expedited review
4. Mention "Critical bug fix" in notes to reviewer

**Option 2: Remove from Sale (Last Resort)**
1. App Store Connect → App Store → Pricing and Availability
2. Remove app from sale temporarily
3. Fix bug
4. Resubmit
5. Make available again

**Option 3: Revert to Previous Version**
- Not possible on App Store
- Users who updated are stuck with buggy version
- Only option: Ship hotfix

**Prevention is key:** Thorough testing prevents needing rollback

---

## Release Communication

### Internal Team (if you grow)
- Slack/Discord: "v1.2.0 is now live!"
- Share App Store link
- Thank everyone involved

### Beta Testers
Email:
```
Subject: STASH 1.2.0 is Now Live!

Hi [Name],

Thanks for beta testing version 1.2.0! It's now live on the App Store
with all the features you helped test.

Your feedback was invaluable - [specific example if possible].

I hope you enjoy the update!

Best,
[Your Name]
```

### All Users (Optional)
- In-app announcement banner when they open app
- Email newsletter (if you have one)
- Twitter/social media post
- Blog post with details (if you have blog)

### Marketing (If doing launch)
- ProductHunt post (for major versions)
- Twitter thread highlighting new features
- Reddit post in relevant communities
- Indie Hackers update

---

## Release Retrospective

**After each release, review:**

**What went well?**
- Smooth release process?
- No critical bugs?
- Positive user feedback?

**What went wrong?**
- Bugs found after release?
- Testing gaps?
- Delayed release?

**What to improve?**
- Add more tests?
- Better testing checklist?
- More thorough beta testing?

**Update this document with lessons learned.**

---

## Automation Opportunities

### Fastlane Setup (Future)

**Fastlane** automates building, signing, and uploading.

Basic `Fastfile`:
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "STASH")
    upload_to_testflight
    commit_version_bump(message: "Version bump for TestFlight")
    push_to_git_remote
  end

  desc "Push a new release to App Store"
  lane :release do
    increment_build_number
    build_app(scheme: "STASH")
    upload_to_app_store
    commit_version_bump(message: "Version bump for App Store")
    push_to_git_remote
  end
end
```

**Usage:**
```bash
fastlane beta    # Upload to TestFlight
fastlane release # Upload to App Store
```

**Benefits:**
- Consistent builds
- Faster releases
- Less manual work
- Fewer mistakes

**Setup time:** 2-4 hours initially, saves hours per release later

---

## Quick Reference Checklist

### Pre-Release (Week Before)
- [ ] Code freeze
- [ ] Run all automated tests
- [ ] Manual testing checklist complete
- [ ] Update version numbers
- [ ] Write release notes
- [ ] Build archive
- [ ] Upload to TestFlight
- [ ] Beta test for 3-5 days

### Release Day
- [ ] Fix any beta bugs (if found)
- [ ] Submit to App Store
- [ ] Wait for approval (1-2 days)
- [ ] Release to users
- [ ] Monitor crashes and feedback closely
- [ ] Respond to App Store reviews

### Post-Release (Week After)
- [ ] Continue monitoring
- [ ] Respond to support emails
- [ ] Track metrics
- [ ] Plan next release
- [ ] Update docs with lessons learned

---

## Next Steps

1. Create CHANGELOG.md in your repo
2. Do a practice run: Build and upload to TestFlight
3. Invite yourself as beta tester
4. Familiarize yourself with App Store Connect
5. Plan your first release timeline

Then move on to: **[MONITORING_SETUP.md](./MONITORING_SETUP.md)**
