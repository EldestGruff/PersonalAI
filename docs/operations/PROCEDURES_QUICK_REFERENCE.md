# Operations Procedures Quick Reference

**All business procedures in one place - Quick lookup for daily/weekly tasks**

Last Updated: 2026-01-20

---

## 📖 How to Use This Guide

**Bookmark this page** - You'll reference it often.

Each procedure is:
- ✅ **Step-by-step** - No fluff, just actions
- ⏱️ **Time-estimated** - Know how long it takes
- 🔗 **Linked** - Deep dive links if needed

---

## Table of Contents

### Daily Operations
- [Morning Routine (15 min)](#morning-routine)
- [Support Email Triage (10 min)](#support-email-triage)
- [Quick Issue Check (5 min)](#quick-issue-check)

### Weekly Operations
- [Monday: Weekly Planning (30 min)](#monday-weekly-planning)
- [Friday: Weekly Review (30 min)](#friday-weekly-review)

### Development Workflows
- [Starting Work on an Issue](#starting-work-on-an-issue)
- [Committing Code with Issue References](#committing-code)
- [Completing an Issue](#completing-an-issue)
- [Creating a New Issue](#creating-a-new-issue)

### Release Workflows
- [Creating a Bug Fix Release (Patch)](#bug-fix-release)
- [Creating a Feature Release (Minor)](#feature-release)
- [Creating a TestFlight Beta Build](#testflight-beta)
- [Submitting to App Store](#app-store-submission)

### Support Workflows
- [Responding to Bug Report](#responding-to-bug-report)
- [Responding to Feature Request](#responding-to-feature-request)
- [Responding to How-To Question](#responding-to-how-to)
- [Can't Reproduce Issue](#cant-reproduce-issue)

---

## Daily Operations

### Morning Routine
⏱️ **Time:** 15 minutes

**Every morning (or when you start work):**

1. **Check support email** (5 min)
   - Open Gmail → "STASH Support" label (or your label)
   - Triage new emails (see [Support Email Triage](#support-email-triage))

2. **Check GitHub Issues** (5 min)
   - Go to repo → Issues
   - Look for `needs-triage` label
   - Triage any new issues (see [Creating a New Issue](#creating-a-new-issue))

3. **Check Project Board** (5 min)
   - Go to repo → Projects → STASH Development
   - Review "🚧 In Progress" - continue where you left off
   - Check "📝 To Do" - today's priorities

**Output:** You know what to work on today

---

### Support Email Triage
⏱️ **Time:** 10 minutes per batch

**For each new support email:**

1. **Read quickly** (30 sec)
   - What's the issue/question?
   - Is it urgent?

2. **Categorize** (10 sec)
   - Bug report?
   - Feature request?
   - How-to question?
   - Out of scope?

3. **Prioritize** (10 sec)
   - **Critical:** App broken for user → Respond within 4 hours
   - **High:** Major feature broken → Respond within 24 hours
   - **Medium:** Minor issue → Respond within 48 hours
   - **Low:** General question → Respond within 48 hours

4. **Take action** (varies)
   - **If quick answer:** Reply immediately with template
   - **If needs investigation:** Send acknowledgment, add to inbox
   - **If it's a bug:** Create GitHub issue, send bug report ack template
   - **If it's a feature:** Send feature request template, add to backlog

5. **Apply labels** (10 sec)
   - Gmail: `Support/In Progress` or `Support/Waiting on Customer`
   - Add to Notion/Spreadsheet tracker (if using)

**Templates:** See [Support Workflows](#support-workflows) below

**Detailed guide:** [SUPPORT_WORKFLOW.md](./SUPPORT_WORKFLOW.md#email-management-system)

---

### Quick Issue Check
⏱️ **Time:** 5 minutes

**Check GitHub several times a day:**

1. **Go to repo → Issues**
2. **Filter:** `is:open is:issue label:needs-triage`
3. **For each untriaged issue:**
   - Read quickly
   - Remove `needs-triage`
   - Add priority label (critical/high/medium/low)
   - Add area label (ai/context/ui/performance/backend)
   - Add to project board (Backlog or To Do)
4. **Check for high-priority items** needing immediate attention

**When to create issues:** Anytime you find a bug or have an idea

---

## Weekly Operations

### Monday: Weekly Planning
⏱️ **Time:** 30 minutes

**Every Monday morning:**

1. **Review last week** (5 min)
   - Project board → "✅ Done" column
   - What did you ship?
   - Update CHANGELOG.md if needed

2. **Triage backlog** (10 min)
   - Project board → "📋 Backlog"
   - Any new issues since last week?
   - Re-prioritize if needed
   - Close stale/duplicate issues

3. **Plan this week** (10 min)
   - What's the goal for this week?
   - Move 3-7 items from Backlog → "📝 To Do"
   - Prioritize To Do column (most important at top)

4. **Check support metrics** (5 min)
   - How many support emails last week?
   - Any patterns? (Same question asked 3+ times = needs better docs)
   - Response time acceptable? (<48 hours?)

**Output:** Clear plan for the week ahead

---

### Friday: Weekly Review
⏱️ **Time:** 30 minutes

**Every Friday afternoon:**

1. **Clean up project board** (10 min)
   - Move completed items to ✅ Done (if not auto-moved)
   - Archive old Done items (optional, monthly)
   - Update status on blocked items
   - Comment on in-progress items with status

2. **Update CHANGELOG.md** (5 min)
   - Add any features/fixes from this week to [Unreleased] section
   - Note any known issues discovered

3. **Review support** (10 min)
   - Close resolved support emails (Gmail → Archive)
   - Follow up on "Waiting on Customer" items >5 days old
   - Note any common questions → needs FAQ/docs

4. **Reflect and plan** (5 min)
   - What went well this week?
   - What was harder than expected?
   - Adjust next week's plan if needed

**Output:** Clean slate for Monday, clear sense of progress

---

## Development Workflows

### Starting Work on an Issue
⏱️ **Time:** 2 minutes

**Before you start coding:**

1. **Find issue on project board**
   - Project board → "📝 To Do"
   - Choose highest priority item

2. **Move to In Progress**
   - Drag issue to "🚧 In Progress" column
   - Add label: `in-progress`

3. **Create git branch** (optional but recommended)
   ```bash
   # For bug fixes
   git checkout -b fix/issue-NUMBER-short-description

   # For features
   git checkout -b feature/issue-NUMBER-short-description

   # Example:
   git checkout -b fix/issue-3-date-parsing
   ```

4. **Add comment to issue** (optional)
   - "Started working on this"
   - Useful for tracking time/progress

**Now code!**

---

### Committing Code
⏱️ **Time:** 30 seconds per commit

**When committing code related to an issue:**

**Format:**
```bash
git commit -m "Brief description of what changed (#ISSUE_NUMBER)"
```

**Examples:**
```bash
git commit -m "Add date parsing for natural language (#3)"
git commit -m "Fix step count collection from HealthKit (#1)"
git commit -m "Implement calendar selection in settings (#4)"
```

**Why:** GitHub auto-links commits to issues, creates audit trail

**Special keywords that auto-close issues:**
```bash
# These close the issue when merged to main:
git commit -m "Fix crash on voice input (fixes #42)"
git commit -m "Add search feature (closes #17)"
git commit -m "Resolve calendar bug (resolves #8)"
```

**Detailed guide:** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#git-commit--push-everything)

---

### Completing an Issue
⏱️ **Time:** 2 minutes

**When you've finished work on an issue:**

1. **Commit final changes**
   ```bash
   git commit -m "Final touches on date parsing (#3)"
   ```

2. **Push to GitHub**
   ```bash
   git push origin main
   # Or if you used a branch:
   git push origin feature/issue-3-date-parsing
   ```

3. **Close the issue on GitHub**
   - Go to issue page
   - Add comment: "Fixed in commit abc123" or "Implemented in version X.X.X"
   - Click "Close issue"
   - Issue auto-moves to "✅ Done"

4. **Remove `in-progress` label** (if not auto-removed)

5. **Update CHANGELOG.md**
   - Add to [Unreleased] section under appropriate heading (Added/Fixed/Changed)

**If shipping immediately:**
- Follow [Bug Fix Release](#bug-fix-release) or [Feature Release](#feature-release)

---

### Creating a New Issue
⏱️ **Time:** 3-5 minutes

**When you discover a bug or have an idea:**

1. **Go to repo → Issues → New issue**

2. **Choose template:**
   - 🐛 Bug Report (for bugs)
   - ✨ Feature Request (for ideas)
   - ❓ Support Question (rarely used by you)

3. **Fill out the form**
   - Be specific but concise
   - If bug: steps to reproduce
   - If feature: use case and why it's valuable

4. **Submit**

5. **After creation, triage it:**
   - Remove `needs-triage` label
   - Add priority label (critical/high/medium/low)
   - Add area label (ai/context/ui/performance/backend/permissions)
   - Add to project board (Backlog or To Do)
   - Set custom fields (Effort: small/medium/large/epic)

**Template:** Use `.github/INITIAL_ISSUES.md` as examples

---

## Release Workflows

### Bug Fix Release
⏱️ **Time:** 30-60 minutes (including testing)

**For urgent bug fixes (patch version: 1.0.0 → 1.0.1):**

1. **Verify bug is fixed**
   - Test on device
   - Verify steps to reproduce no longer work

2. **Update version number** in Xcode
   - MAJOR.MINOR.PATCH (increment PATCH)
   - Example: 1.0.0 → 1.0.1
   - Increment build number

3. **Update CHANGELOG.md**
   ```markdown
   ## [1.0.1] - 2026-01-21

   ### Fixed
   - Fixed crash when capturing voice input (#42)
   - Fixed step count not loading from HealthKit (#1)
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "Bump version to 1.0.1 - Bug fixes"
   git push
   ```

5. **Run full test suite** (if you have tests)

6. **Build and archive** in Xcode
   - Product → Archive
   - Upload to App Store Connect

7. **Submit to App Store** with notes:
   ```
   Bug fix release:
   - Fixed crash affecting users when using voice input
   - Fixed HealthKit data not loading correctly

   Please expedite review if possible.
   ```

8. **Notify affected users** (if you know who they are)
   - Use bug fix notification email template

**Detailed guide:** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#pre-release-checklist)

---

### Feature Release
⏱️ **Time:** 2-3 hours (including testing)

**For new features (minor version: 1.0.0 → 1.1.0):**

1. **Code freeze**
   - All features for this release are complete
   - No new features after this point (bug fixes only)

2. **Update version number** in Xcode
   - MAJOR.MINOR.PATCH (increment MINOR, reset PATCH to 0)
   - Example: 1.0.5 → 1.1.0
   - Increment build number

3. **Update CHANGELOG.md**
   ```markdown
   ## [1.1.0] - 2026-02-01

   ### Added
   - Smart date/time parsing from natural language (#3)
   - Calendar selection in settings (#4)

   ### Fixed
   - Minor bug fixes

   ### Changed
   - Improved energy calculation accuracy
   ```

4. **Write App Store release notes**
   ```
   ✨ What's New in 1.1.0

   NEW FEATURES
   • Smart Date Parsing - Just say "tomorrow at 2pm" and we'll set it automatically
   • Choose Your Calendar - Pick which calendar events are added to

   BUG FIXES
   • Fixed minor issues

   IMPROVEMENTS
   • Better energy level calculations

   Questions? Tap Help & Feedback in Settings.
   ```

5. **Run full testing checklist** (see [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#2-testing-phase))
   - Manual testing on device
   - Test all core features
   - Test new features thoroughly

6. **Commit everything**
   ```bash
   git add .
   git commit -m "Release 1.1.0 - Smart date parsing and calendar selection"
   git tag v1.1.0
   git push && git push --tags
   ```

7. **Build for TestFlight first** (recommended)
   - Upload to TestFlight
   - Beta test for 3-5 days
   - Fix any critical bugs found

8. **Submit to App Store**

9. **Monitor after release** (see [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#release-day))

**Detailed guide:** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md)

---

### TestFlight Beta
⏱️ **Time:** 30 minutes

**For beta testing before App Store release:**

1. **Build and archive** in Xcode
   - Product → Archive

2. **Upload to TestFlight**
   - Distribute App → App Store Connect → Upload
   - Select build
   - Add "What to Test" notes for testers

3. **Wait for processing** (30-60 min)

4. **Add beta testers** (if not already added)
   - Internal testers: Team members
   - External testers: Beta program users

5. **Notify testers**
   ```
   Thanks for testing 1.1.0!

   Please focus on:
   - New smart date parsing (try "tomorrow at 2pm")
   - Calendar selection in settings

   Known issues: None currently

   Report bugs: In-app feedback or support@yourapp.com
   ```

6. **Collect feedback** for 3-5 days

7. **Fix critical bugs** if found (iterate)

8. **When ready:** Submit to App Store

**Detailed guide:** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#7-testflight-beta-testing-optional-but-recommended)

---

### App Store Submission
⏱️ **Time:** 20-30 minutes

**Submitting a build to App Store:**

1. **Go to App Store Connect**
   - appstoreconnect.apple.com
   - My Apps → STASH

2. **Create new version**
   - Click "+ Version" under iOS App
   - Enter version number (e.g., 1.1.0)

3. **Fill out form:**
   - **What's New:** Paste your release notes
   - **Build:** Select the uploaded build
   - **Screenshots:** Update if UI changed (usually not needed)
   - **App Review Notes:**
     ```
     This update adds [key features].

     To test:
     1. [Test step 1]
     2. [Test step 2]

     Permissions needed:
     - Location (for context gathering)
     - HealthKit (for energy tracking)
     - Calendar/Reminders (for events/reminders)
     - Microphone (for voice input)

     Please grant all permissions to test full functionality.
     ```

4. **Choose release option:**
   - Manual release (recommended): You control when it goes live
   - Automatic: Goes live immediately after approval

5. **Submit for Review**

6. **Wait for review** (usually 1-2 days)

7. **When approved:**
   - If manual: Click "Release this Version"
   - If automatic: Already live

8. **Monitor first 24 hours** closely

**Detailed guide:** [RELEASE_PROCESS.md](./RELEASE_PROCESS.md#8-app-store-submission)

---

## Support Workflows

### Responding to Bug Report
⏱️ **Time:** 5 minutes

**When user reports a bug via email:**

1. **Send acknowledgment immediately** (use template)
   - Gmail → Templates → "Bug Report Acknowledgment"
   - Customize with specifics

   ```
   Hi [Name],

   Thanks for reporting this bug! I really appreciate you taking the time.

   I've filed this as issue #[number] and I'm investigating it now.

   [If reproducible:] I was able to reproduce this on my device.
   [If not:] I haven't been able to reproduce this yet - could you provide...

   I'll keep you updated on progress.

   Best,
   Andy

   GitHub: https://github.com/username/personal-ai-ios/issues/[number]
   ```

2. **Create GitHub issue**
   - Use Bug Report template
   - Copy details from email
   - Add labels and priority

3. **Add to project board**
   - Based on priority: To Do or Backlog

4. **Update email tracker**
   - Gmail label: `Support/In Progress`
   - Link to GitHub issue

5. **When fixed:**
   - Send "Bug Fixed" template
   - Close GitHub issue
   - Gmail label: `Support/Resolved` → Archive

**Template:** `.github/SUPPORT_TEMPLATES.md` - "Bug Report Acknowledgment"

---

### Responding to Feature Request
⏱️ **Time:** 3-5 minutes

**When user suggests a feature:**

1. **Evaluate the idea** (1 min)
   - Does it fit the roadmap?
   - Would others benefit?
   - Effort vs. value?

2. **Reply with appropriate template:**

   **If good idea / high priority:**
   ```
   Hi [Name],

   Great suggestion! I've added this to the feature backlog.

   This is something I've been thinking about too, and it's high on my priority list.
   I'll keep you posted when I start working on it.

   You can follow progress: [GitHub issue link]

   Best,
   Andy
   ```

   **If maybe later:**
   ```
   Hi [Name],

   Thanks for the suggestion! I've added this to the backlog.

   I can see how this would be useful. It's not in the immediate roadmap,
   but I'll keep it in mind for future updates.

   Best,
   Andy
   ```

   **If won't build:**
   ```
   Hi [Name],

   Thanks for the suggestion! I've thought about this carefully, and I've
   decided not to pursue this right now because [clear reason].

   I know this might be disappointing, but I want to be upfront about
   what I'm prioritizing.

   Best,
   Andy
   ```

3. **Create GitHub issue** (if you might build it)
   - Feature Request template
   - Add to Backlog

4. **Gmail label:** `Support/Resolved` → Archive

**Template:** `.github/SUPPORT_TEMPLATES.md` - "Feature Request Response"

---

### Responding to How-To
⏱️ **Time:** 5-10 minutes

**When user asks how to do something:**

1. **Answer the question** (use template)
   ```
   Hi [Name],

   Great question! Here's how to do that:

   1. [Step 1]
   2. [Step 2]
   3. [Step 3]

   Let me know if you have any other questions!

   Best,
   Andy

   P.S. I'm adding this to the FAQ so others can find it easily.
   ```

2. **If this is asked frequently:**
   - Add to FAQ documentation (create if needed)
   - Or consider improving UI to make it more obvious

3. **Gmail label:** `Support/Resolved` → Archive

**Template:** `.github/SUPPORT_TEMPLATES.md` - "How-To Answer"

---

### Can't Reproduce Issue
⏱️ **Time:** 5 minutes

**When you can't reproduce a reported bug:**

1. **Send "Need More Info" template**
   ```
   Hi [Name],

   Thanks for the report! I've tried to reproduce this on my test devices,
   but I haven't been able to yet.

   Could you help me with a few more details?

   - iOS version? (Settings → General → About)
   - App version? (Settings → About in STASH)
   - Device model?
   - [Specific question about the issue]
   - Can you share a screenshot?

   Also, have you tried:
   - [Potential fix 1]
   - [Potential fix 2]

   This will help me track it down. Thanks!

   Best,
   Andy
   ```

2. **Gmail label:** `Support/Waiting on Customer`

3. **If no response in 5 days:**
   - Send follow-up: "Just checking if you still need help with this?"

4. **If no response in 10 days:**
   - Close issue (if created)
   - Archive email

**Template:** `.github/SUPPORT_TEMPLATES.md` - "Can't Reproduce / Need More Info"

---

## Quick Decision Trees

### "I found a bug while coding"

```
Found bug
    ↓
Create GitHub issue
    ↓
Is it critical? (App broken)
    ├─ YES → Add to "To Do", fix immediately
    └─ NO → Add to "Backlog", fix when convenient
```

---

### "I have an idea for a feature"

```
Feature idea
    ↓
Create GitHub issue (Feature Request template)
    ↓
Does it align with roadmap?
    ├─ YES → Add to Backlog, prioritize
    └─ NO → Close with explanation, or keep for future
```

---

### "User emailed about a bug"

```
Bug report email
    ↓
Send acknowledgment (template)
    ↓
Can you reproduce it?
    ├─ YES → Create issue, fix it, notify when done
    └─ NO → Ask for more info, iterate
```

---

### "Should I release this?"

```
Ready to release?
    ↓
Run testing checklist
    ↓
All tests pass?
    ├─ YES → Update version, TestFlight beta, then App Store
    └─ NO → Fix issues, test again
```

---

## Emergency Procedures

### Critical Bug in Production
⏱️ **Time:** Immediate

**If app is broken for users in production:**

1. **Assess severity**
   - How many users affected?
   - Is app completely broken or just one feature?

2. **Create hotfix branch**
   ```bash
   git checkout -b hotfix/critical-issue
   ```

3. **Fix the bug** (as fast as possible)

4. **Test fix thoroughly**

5. **Bump patch version**
   - Example: 1.1.0 → 1.1.1

6. **Skip TestFlight** (emergency only)

7. **Submit to App Store** with expedited review request
   ```
   CRITICAL BUG FIX

   This release fixes a critical bug that makes the app unusable for users.

   Issue: [Brief description]
   Fix: [What was changed]

   Please expedite review.
   ```

8. **Communicate to users** (if possible)
   - Social media: "We're aware of the issue and fix is pending review"
   - Email (if you have list)

9. **Monitor App Store review status** closely

**Prevention:** Thorough testing before releases!

---

### Support Email Backlog
⏱️ **Time:** 1-2 hours

**If support emails pile up (>20 unread):**

1. **Block time** (1-2 hours)

2. **Batch process:**
   - Sort by date (oldest first)
   - Send acknowledgment to all (templates)
   - Categorize each (bug/feature/question)
   - Create GitHub issues for bugs
   - Answer quick questions immediately

3. **Set expectations:**
   - Let users know current response time
   - "I'm catching up on support emails, I'll get to yours by [date]"

4. **Prevent future backlog:**
   - Check email daily (even if just 10 min)
   - Hire VA for support (if volume is consistently high)

---

## Time-Saving Tips

### Gmail Shortcuts
- `c` - Compose new email
- `r` - Reply
- `a` - Reply all
- `e` - Archive
- `l` - Apply label
- `/` - Search

**Enable:** Gmail Settings → General → Keyboard shortcuts → Enable

### GitHub Shortcuts
- `c` - Create new issue
- `g i` - Go to issues
- `g p` - Go to pull requests
- `?` - Show all shortcuts

### Templates Usage
- **Name templates clearly:** "Support - Bug Ack", "Support - Feature Request"
- **Customize before sending:** Replace [Name], add specifics
- **Update templates:** As you learn common responses

---

## Metrics to Track

### Weekly
- Issues opened vs. closed
- Support emails received vs. resolved
- Time spent on support (should be <5 hours/week)

### Monthly
- Features shipped
- Bugs fixed
- App Store rating
- Crash-free rate (should be >99.5%)

**Where to track:** Simple spreadsheet or Notion dashboard

---

## Getting Help

**If a procedure isn't clear:**
- Check the detailed guide (linked in each section)
- Ask in GitHub Discussions (if you set it up)
- Google "GitHub [topic]"

**If you're overwhelmed:**
- Focus on essentials: Support triage, critical bugs
- Defer everything else
- Consider time-boxing (support = 1 hour max per day)

---

## Customizing These Procedures

**These are starting points** - Adjust as you learn:

- Add your own shortcuts
- Modify time estimates
- Change priorities
- Create new templates
- Skip steps that don't apply

**Update this document** as you refine your process!

---

**Remember:** The goal is sustainable operations, not perfect operations. Do what works for you.

**Bookmark this page:** You'll reference it daily/weekly.

---

**Quick links:**
- [Support Templates](./.github/SUPPORT_TEMPLATES.md)
- [Release Process](./RELEASE_PROCESS.md)
- [Monitoring Setup](./MONITORING_SETUP.md)
- [Full Operations Guide](./OPERATIONS_OVERVIEW.md)
