# Business Systems Setup Guide

**Complete checklist for setting up your operational infrastructure**

This guide walks you through setting up all the "business side" systems before continuing development.

---

## Overview

You've created all the documentation and templates. Now you need to actually set them up in GitHub and Gmail.

**Estimated total time:** 1-2 hours

**What you'll have when done:**
- ✅ Professional issue tracking system
- ✅ Release notes and changelog
- ✅ Kanban board for project management
- ✅ Support email templates ready to use
- ✅ Clear view of all known work (bugs and features)

---

## Setup Checklist

### Part 1: GitHub Issue System (30-45 min)

#### Step 1: Verify Issue Templates ✅
**Already done!** Templates are in `.github/ISSUE_TEMPLATE/`

Test them:
1. Go to your GitHub repo
2. Click "Issues" → "New issue"
3. You should see three templates:
   - Bug Report
   - Feature Request
   - Support Question

If you don't see them, push the `.github` folder to GitHub:
```bash
git add .github
git commit -m "Add issue templates, labels guide, and setup docs"
git push
```

#### Step 2: Create Labels (10 min)

**Option A: Manual (Recommended for first time)**

1. Go to GitHub repo → Issues → Labels
2. Click "New label"
3. Create each label from `.github/LABELS.md`
4. Use the color codes provided

**Quick list to create:**
- Type labels: bug, enhancement, question, documentation, support
- Priority labels: priority: critical, priority: high, priority: medium, priority: low
- Status labels: needs-triage, in-progress, blocked, wontfix, duplicate
- Area labels: area: ai, area: context, area: ui, area: performance, area: backend, area: permissions

**Option B: GitHub CLI (Faster)**

If you have GitHub CLI installed:
```bash
# Copy the commands from .github/LABELS.md
# Run them in your terminal
gh label create "bug" --color "d73a4a" --description "Something isn't working"
# ... (see LABELS.md for full list)
```

#### Step 3: Create Project Board (15 min)

Follow instructions in `.github/PROJECT_BOARD_SETUP.md`:

1. Go to GitHub repo → Projects → New project
2. Select "Board" template
3. Name it "STASH Development"
4. Customize columns:
   - 📋 Backlog
   - 📝 To Do
   - 🚧 In Progress
   - ✅ Done
5. Set up automation:
   - Auto-add new issues to Backlog
   - Auto-move closed issues to Done
6. (Optional) Add custom fields:
   - Priority (🔴 Critical, 🟠 High, 🟡 Medium, ⚪ Low)
   - Effort (🟢 Small, 🟡 Medium, 🔴 Large, 🟣 Epic)

#### Step 4: Create Initial Issues (15-20 min)

Use `.github/INITIAL_ISSUES.md` as your guide:

**Create these first (high priority):**

1. **Issue #1:** HealthKit step count not collecting
   - Template: Bug Report
   - Labels: bug, priority: high, area: context
   - Add to: To Do

2. **Issue #2:** Location name occasionally blank
   - Template: Bug Report
   - Labels: bug, priority: medium, area: context
   - Add to: Backlog

3. **Issue #3:** Smart date/time parsing
   - Template: Feature Request
   - Labels: enhancement, priority: high, area: ai
   - Add to: Backlog
   - Milestone: Phase 4

4. **Issue #4:** Calendar selection settings
   - Template: Feature Request
   - Labels: enhancement, priority: high, area: ui, area: context
   - Add to: Backlog
   - Milestone: Phase 4

**Optional (lower priority):**

5. Issue #5: Search and filter thoughts
6. Issue #6: Batch operations
7. Issue #7: Add unit tests

**After creating each issue:**
- Remove `needs-triage` label
- Add appropriate labels (priority, area)
- Add to project board
- Set custom fields if configured

---

### Part 2: Changelog & Release Notes (5 min)

#### Step 1: Verify CHANGELOG.md ✅
**Already done!** `CHANGELOG.md` exists in project root

Review it:
1. Current version is documented (0.1.0 - Phase 3A)
2. Known issues are listed
3. Template for future releases is there

#### Step 2: Commit to Git

```bash
git add CHANGELOG.md
git commit -m "Add CHANGELOG.md with Phase 3A release notes"
git push
```

---

### Part 3: Support Email Setup (20-30 min)

#### Step 1: Choose Email Address

**Option A: Use personal Gmail (Quick start)**
- Use your existing Gmail
- Create label: "STASH Support"
- Set up filters to auto-label

**Option B: Custom domain (Professional, but costs $)**
- Buy domain: yourapp.com (~$12/year)
- Set up email forwarding to Gmail
- Send from custom address via Gmail

**Option C: Dedicated Gmail (Middle ground)**
- Create: support.personalai@gmail.com
- Free, dedicated, professional enough

**Recommendation:** Start with Option A, upgrade to B when you have revenue

#### Step 2: Set Up Gmail Canned Responses

Follow `.github/SUPPORT_TEMPLATES.md`:

1. **Enable Templates in Gmail:**
   - Settings → See all settings
   - Advanced tab
   - Templates → Enable
   - Save changes

2. **Create 3-5 key templates:**
   - General Acknowledgment
   - Bug Report Acknowledgment
   - Feature Request Response
   - How-To Answer
   - Need More Info

3. **Test:**
   - Compose email to yourself
   - Insert template
   - Verify it works

#### Step 3: Set Up Tracking (Optional)

**Option A: Notion Database**
- Create database with fields from SUPPORT_TEMPLATES.md
- Track: Email, Subject, Status, Priority, Type, GitHub link

**Option B: Simple Spreadsheet**
- Google Sheets
- Columns: Email | Subject | Priority | Type | Status | GitHub Link

**Option C: Just use Gmail labels**
- Support/New
- Support/In Progress
- Support/Waiting on Customer
- Support/Resolved

**Recommendation:** Start with Gmail labels, add Notion when you have >10 support emails/week

---

### Part 4: Git Commit & Push Everything (5 min)

Make sure all your new business systems are in version control:

```bash
# Check what's new
git status

# Add everything
git add .github/ CHANGELOG.md docs/operations/

# Commit
git commit -m "Set up business systems: issue tracking, changelog, support templates"

# Push
git push origin main
```

---

## Verify Everything Works

### Issue Tracking ✅
- [ ] Go to GitHub → Issues
- [ ] Click "New issue"
- [ ] See three templates (Bug, Feature, Support)
- [ ] Labels are created and visible
- [ ] Project board exists with 4 columns
- [ ] At least 2-4 initial issues created

### Release Notes ✅
- [ ] CHANGELOG.md exists and is committed
- [ ] Phase 3A is documented
- [ ] Template for future releases is ready

### Support System ✅
- [ ] Email address chosen
- [ ] Templates enabled in Gmail
- [ ] 3-5 canned responses created
- [ ] Tracking system set up (labels/Notion/spreadsheet)

---

## What's Next?

### You Now Have:

1. **Issue tracking system** for bugs and features
2. **Project board** to visualize work
3. **Changelog** for release notes
4. **Support infrastructure** ready for users
5. **Clear backlog** of known work

### Recommended Workflow Going Forward:

#### Before You Code
1. Check project board → 📝 To Do column
2. Pick an issue to work on
3. Move to 🚧 In Progress

#### While Coding
1. Reference issue in commits: `git commit -m "Fix step count collection (#1)"`
2. Add comments to issue with progress updates

#### When Done
1. Close the issue
2. It auto-moves to ✅ Done
3. Update CHANGELOG.md with what you fixed/added

#### Weekly Review (Fridays, 15 min)
1. Review 📋 Backlog - any new issues to triage?
2. Plan next week - move items to 📝 To Do
3. Update priorities if needed
4. Check metrics (how many done this week?)

---

## Decision Point: What to Work On Next?

Now that you have business systems set up, you have options:

### Option A: Fix Known Bugs First
**Pros:**
- Clean up technical debt
- Improve app stability
- Build confidence in the codebase

**Work on:**
- Issue #1: Fix HealthKit step count (2-4 hours)
- Issue #2: Fix location name (2-3 hours)

**Total time:** 4-7 hours, then move to features

---

### Option B: Jump to Phase 4 Features
**Pros:**
- Add user value immediately
- Make app more useful
- Build momentum

**Work on:**
- Issue #3: Smart date parsing (large effort, high value)
- Issue #4: Calendar selection (medium effort, high value)

**Total time:** 1-2 weeks for both features

---

### Option C: Add Testing Infrastructure
**Pros:**
- Prevent future bugs
- Make refactoring safer
- Professional development practice

**Work on:**
- Issue #7: Add unit tests (epic effort)
- Set up CI/CD (from docs/operations/CI_CD_SETUP.md)

**Total time:** 1-2 weeks to get to 70% coverage + CI

---

### Option D: Backend Setup (Big Undertaking)
**Pros:**
- Enable sync across devices
- Better AI classification
- Unlock future features

**Work on:**
- Follow docs/planning/BACKEND_STRATEGY.md
- Set up Supabase
- Create AI service

**Total time:** 2-4 weeks for MVP backend

---

## My Recommendation

Based on having business systems set up, here's what I'd suggest:

### Week 1: Quick Wins
- Fix bug #1 (step count) - HIGH IMPACT
- Fix bug #2 (location name) - MEDIUM IMPACT
- **Result:** More stable app, better data quality

### Week 2-3: High-Value Feature
- Implement Issue #4 (calendar selection) - EASIER than #3
- **Result:** Addresses common user pain point

### Week 4-5: Ambitious Feature
- Implement Issue #3 (smart date parsing) - HARDER but transformative
- **Result:** Makes app feel magical, significantly better UX

### Then Decide:
- More features (Phase 4 continues)?
- Backend setup (Phase 5)?
- Testing infrastructure?

**Why this order?**
1. Bugs first = solid foundation
2. Easier feature = build confidence
3. Ambitious feature = big UX improvement
4. Then reassess based on what you learned

---

## Success Metrics

**After 1 month with business systems:**

You should be able to answer:
- ✅ How many bugs are open?
- ✅ How many features are in the backlog?
- ✅ What did I ship this week?
- ✅ What am I working on right now?
- ✅ What's the plan for next week?

If you can answer these confidently, your business systems are working!

---

## Getting Help

**If stuck on GitHub setup:**
- GitHub Docs: https://docs.github.com/en/issues
- Video tutorials: Search "GitHub Projects setup" on YouTube

**If stuck on support setup:**
- Gmail help: https://support.google.com/mail
- See docs/operations/SUPPORT_WORKFLOW.md

**If stuck on what to work on next:**
- Review docs/planning/ROADMAP.md
- Check your GitHub project board
- Ask yourself: "What would make this app most useful to users?"

---

## Final Checklist

Before you start coding again:

- [ ] All GitHub issue templates working
- [ ] Labels created in GitHub
- [ ] Project board set up with automation
- [ ] 2-4 initial issues created
- [ ] CHANGELOG.md committed to git
- [ ] Support email decided
- [ ] Gmail templates set up
- [ ] Support tracking system ready
- [ ] Everything committed and pushed to GitHub

**If all checked:** You're ready to develop with proper business systems in place! 🎉

---

**Time invested:** 1-2 hours
**Benefit:** Professional project management, clear roadmap, ready for users

**Now go build something awesome!** 🚀
