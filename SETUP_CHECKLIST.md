# Business Systems Setup Checklist

**Follow these steps in order to set up your complete operational infrastructure**

Estimated time: 1-2 hours

---

## ☑️ Phase 1: GitHub Repository (15 min)

### Step 1: Create GitHub Repository
- [ ] Go to https://github.com and sign in
- [ ] Click "+" → "New repository"
- [ ] Name: `personal-ai-ios` (or your choice)
- [ ] Choose Private or Public
- [ ] **Do NOT initialize** (no README, no .gitignore)
- [ ] Click "Create repository"

### Step 2: Connect Local Repository
- [ ] Copy the commands GitHub shows for "push an existing repository"
- [ ] Run in terminal:
```bash
git remote add origin https://github.com/YOUR_USERNAME/personal-ai-ios.git
git branch -M main
git push -u origin main
```
- [ ] Refresh GitHub page - you should see all your files!

**See detailed instructions:** `.github/GITHUB_REPO_SETUP.md`

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 2: Issue Templates (5 min)

### Verify Templates Are Live
- [ ] Go to your GitHub repo
- [ ] Click "Issues" tab
- [ ] Click "New issue" button
- [ ] Confirm you see 3 templates:
  - 🐛 Bug Report
  - ✨ Feature Request
  - ❓ Support Question

**If you don't see them:**
- Wait 1-2 minutes (GitHub might be processing)
- Hard refresh page (Cmd+Shift+R)
- Check that `.github/ISSUE_TEMPLATE/` folder pushed correctly

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 3: Labels (15 min)

### Option A: Manual Creation (Recommended)
- [ ] Go to repo → Issues → Labels
- [ ] Open `.github/LABELS.md` in another tab
- [ ] For each label in the doc:
  - [ ] Click "New label"
  - [ ] Enter name (e.g., `bug`)
  - [ ] Enter color code (e.g., `#d73a4a`)
  - [ ] Enter description
  - [ ] Click "Create label"

**Labels to create:**
- [ ] Type labels (5): bug, enhancement, question, documentation, support
- [ ] Priority labels (4): priority: critical, priority: high, priority: medium, priority: low
- [ ] Status labels (5): needs-triage, in-progress, blocked, wontfix, duplicate
- [ ] Area labels (6): area: ai, area: context, area: ui, area: performance, area: backend, area: permissions

**Total: 20 labels**

### Option B: GitHub CLI (Faster)
- [ ] Install GitHub CLI: `brew install gh`
- [ ] Authenticate: `gh auth login`
- [ ] Copy all commands from `.github/LABELS.md`
- [ ] Paste in terminal and run

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 4: Project Board (20 min)

### Create Board
- [ ] Go to repo → Projects tab
- [ ] Click "New project"
- [ ] Select "Board" template
- [ ] Name: "STASH Development"
- [ ] Click "Create project"

### Customize Columns
- [ ] Rename columns:
  - [ ] "Todo" → "📋 Backlog"
  - [ ] "In Progress" → "🚧 In Progress"
  - [ ] "Done" → "✅ Done"
- [ ] Add new column: "📝 To Do" (between Backlog and In Progress)

**Column order:** 📋 Backlog | 📝 To Do | 🚧 In Progress | ✅ Done

### Set Up Automation
- [ ] Click "⋯" (three dots) on project
- [ ] Click "Workflows"
- [ ] Enable: "Auto-add to project"
  - When: Issues and PRs opened
  - Then: Add to "📋 Backlog"
- [ ] Enable: "Item closed"
  - When: Issue/PR closed
  - Then: Move to "✅ Done"

### Add Custom Fields (Optional but Useful)
- [ ] Click "+" in table header → "New field"
- [ ] Create "Priority" field:
  - Type: Single select
  - Options: 🔴 Critical, 🟠 High, 🟡 Medium, ⚪ Low
- [ ] Create "Effort" field:
  - Type: Single select
  - Options: 🟢 Small, 🟡 Medium, 🔴 Large, 🟣 Epic

**Detailed instructions:** `.github/PROJECT_BOARD_SETUP.md`

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 5: Initial Issues (30 min)

**Use `.github/INITIAL_ISSUES.md` as your reference**

### High-Priority Issues to Create

**Issue #1: HealthKit Step Count Bug**
- [ ] Click "New issue" → "Bug Report"
- [ ] Fill out form (copy from INITIAL_ISSUES.md)
- [ ] After creation:
  - [ ] Remove label: `needs-triage`
  - [ ] Add labels: `priority: high`, `area: context`
  - [ ] Add to project → 📝 To Do
  - [ ] Set custom field: Effort = 🟡 Medium

**Issue #2: Location Name Bug**
- [ ] Click "New issue" → "Bug Report"
- [ ] Fill out form (copy from INITIAL_ISSUES.md)
- [ ] After creation:
  - [ ] Remove label: `needs-triage`
  - [ ] Add labels: `priority: medium`, `area: context`
  - [ ] Add to project → 📋 Backlog
  - [ ] Set custom field: Effort = 🟢 Small

**Issue #3: Smart Date/Time Parsing**
- [ ] Click "New issue" → "Feature Request"
- [ ] Fill out form (copy from INITIAL_ISSUES.md)
- [ ] After creation:
  - [ ] Remove label: `needs-triage`
  - [ ] Add labels: `priority: high`, `area: ai`
  - [ ] Add to project → 📋 Backlog
  - [ ] Set custom field: Effort = 🔴 Large

**Issue #4: Calendar Selection Settings**
- [ ] Click "New issue" → "Feature Request"
- [ ] Fill out form (copy from INITIAL_ISSUES.md)
- [ ] After creation:
  - [ ] Remove label: `needs-triage`
  - [ ] Add labels: `priority: high`, `area: ui`, `area: context`
  - [ ] Add to project → 📋 Backlog
  - [ ] Set custom field: Effort = 🟡 Medium

### Optional Issues (Create if you have time)
- [ ] Issue #5: Search and filter
- [ ] Issue #6: Batch operations
- [ ] Issue #7: Add unit tests

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 6: Support Email (20 min)

### Choose Email Address
- [ ] Decision made:
  - Option A: Use existing Gmail + label
  - Option B: Create support.personalai@gmail.com
  - Option C: Buy domain + custom email (later)

**My choice:** _________________

### Set Up Gmail Templates
- [ ] Gmail → Settings → See all settings
- [ ] Advanced tab → Templates → Enable → Save
- [ ] Create canned responses (copy from `.github/SUPPORT_TEMPLATES.md`):
  - [ ] General Acknowledgment
  - [ ] Bug Report Acknowledgment
  - [ ] Feature Request Response
  - [ ] How-To Answer
  - [ ] Need More Info

### Test Templates
- [ ] Compose email to yourself
- [ ] Insert a template (⋯ → Templates → Select one)
- [ ] Verify it works
- [ ] Delete test email

### Set Up Tracking (Choose One)
- [ ] Option A: Gmail labels (Support/New, Support/In Progress, etc.)
- [ ] Option B: Notion database
- [ ] Option C: Google Sheets

**My choice:** _________________

**Detailed instructions:** `.github/SUPPORT_TEMPLATES.md`

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Phase 7: Verify Everything (10 min)

### GitHub Issues
- [ ] Go to repo → Issues tab
- [ ] See your created issues listed
- [ ] Click "New issue" → Templates work
- [ ] Labels are visible and organized

### Project Board
- [ ] Go to repo → Projects tab
- [ ] Open "STASH Development" board
- [ ] See 4 columns with appropriate issues
- [ ] Drag an issue between columns → works

### Support System
- [ ] Gmail templates accessible
- [ ] Tracking system set up
- [ ] Support email address chosen

### Documentation
- [ ] CHANGELOG.md exists and is accurate
- [ ] README.md updated with new docs
- [ ] Can navigate docs easily

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## ☑️ Bonus: Commit Setup Documentation (5 min)

If you created the GitHub repo setup doc:

```bash
git add .github/GITHUB_REPO_SETUP.md SETUP_CHECKLIST.md
git commit -m "Add GitHub repo setup guide and checklist"
git push
```

**Status:** ⬜ Not started → ⏳ In progress → ✅ Complete

---

## 🎉 Completion Summary

Once all phases are complete, you have:

✅ **GitHub repository** with all code and docs
✅ **Professional issue templates** for bugs, features, and support
✅ **20 organized labels** for categorization
✅ **Kanban project board** with automation
✅ **4-7 initial issues** documenting known work
✅ **Support email system** with templates
✅ **CHANGELOG.md** for release notes

**Total files created:** 26 documentation files
**Total time invested:** 1-2 hours
**Benefit:** Professional project management ready for users

---

## What's Next?

### Immediate
- [ ] Choose what to work on next:
  - Fix bugs (#1, #2)?
  - Build features (#3, #4)?
  - Add testing?
  - Set up backend?

### This Week
- [ ] Use the issue tracker! Create issues as bugs/ideas arise
- [ ] Move issues on project board as you work
- [ ] Reference issues in commits: `git commit -m "Fix step count (#1)"`

### Ongoing
- [ ] Weekly review (Fridays, 15 min):
  - Triage new issues
  - Plan next week's work
  - Update CHANGELOG.md
- [ ] Update docs as you learn
- [ ] Respond to support emails with templates

---

## Need Help?

**If stuck:**
- GitHub setup: `.github/GITHUB_REPO_SETUP.md`
- Labels: `.github/LABELS.md`
- Project board: `.github/PROJECT_BOARD_SETUP.md`
- Initial issues: `.github/INITIAL_ISSUES.md`
- Support: `.github/SUPPORT_TEMPLATES.md`
- Full guide: `.github/BUSINESS_SYSTEMS_SETUP_GUIDE.md`

**Questions?**
- GitHub Docs: https://docs.github.com
- GitHub Issues Guide: https://docs.github.com/en/issues
- Video tutorials: Search "GitHub Projects" on YouTube

---

## Progress Tracker

**Overall Completion:**

- [ ] Phase 1: GitHub Repository (15 min)
- [ ] Phase 2: Issue Templates (5 min)
- [ ] Phase 3: Labels (15 min)
- [ ] Phase 4: Project Board (20 min)
- [ ] Phase 5: Initial Issues (30 min)
- [ ] Phase 6: Support Email (20 min)
- [ ] Phase 7: Verify Everything (10 min)

**Estimated: 1h 55min total**

**Start time:** __:__
**End time:** __:__
**Actual duration:** ____

---

**Good luck! You've got this! 🚀**
