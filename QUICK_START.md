# STASH Quick Start Guide

**Fast navigation to what you need right now**

---

## 🔥 Most Used Documents (Bookmark These!)

### For Daily Development Work

**📋 [Procedures Quick Reference](./docs/operations/PROCEDURES_QUICK_REFERENCE.md)**
→ All workflows in one place: morning routine, support, releases, etc.
→ **USE THIS DAILY**

**📊 Your GitHub Project Board**
→ `https://github.com/EldestGruff/STASH/projects`
→ See what's in progress, what's next

**📝 [CHANGELOG.md](./CHANGELOG.md)**
→ Track what you've built, document releases

---

## 🎯 Common Tasks

### "I want to..."

**...start working on something**
1. Go to GitHub Project Board → "📝 To Do"
2. Pick highest priority item
3. Follow: [Starting Work on an Issue](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#starting-work-on-an-issue)

**...respond to a support email**
→ [Support Email Triage](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#support-email-triage)
→ [Support Workflows](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#support-workflows)

**...release an update**
→ [Bug Fix Release](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#bug-fix-release) (patch: 1.0.0 → 1.0.1)
→ [Feature Release](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#feature-release) (minor: 1.0.0 → 1.1.0)

**...create a GitHub issue**
→ [Creating a New Issue](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#creating-a-new-issue)

**...plan my week**
→ [Monday: Weekly Planning](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#monday-weekly-planning)

**...understand the architecture**
→ [Development Docs](./docs/development/)

**...see the roadmap**
→ [ROADMAP.md](./docs/planning/ROADMAP.md)

**...set up backend**
→ [BACKEND_STRATEGY.md](./docs/planning/BACKEND_STRATEGY.md)

---

## 📂 Documentation Map

```
STASH/
│
├── QUICK_START.md ← You are here!
├── README.md ← Project overview
├── CHANGELOG.md ← Release notes
├── FEATURES.md ← Feature specifications
│
├── docs/
│   ├── DOCUMENTATION_INDEX.md ← Complete doc navigation
│   │
│   ├── operations/ ← HOW TO RUN THE BUSINESS
│   │   ├── PROCEDURES_QUICK_REFERENCE.md ⭐ DAILY USE
│   │   ├── OPERATIONS_OVERVIEW.md
│   │   ├── GITHUB_ISSUES_SETUP.md
│   │   ├── SUPPORT_WORKFLOW.md
│   │   ├── RELEASE_PROCESS.md
│   │   ├── MONITORING_SETUP.md
│   │   └── CI_CD_SETUP.md
│   │
│   ├── planning/ ← WHAT TO BUILD
│   │   ├── ROADMAP.md
│   │   ├── BACKEND_STRATEGY.md
│   │   ├── CUSTOMER_REQUESTS.md
│   │   ├── TESTING_STRATEGY.md
│   │   ├── TECHNICAL_DEBT.md
│   │   └── QUICK_REFERENCE.md
│   │
│   └── development/ ← HOW TO BUILD IT
│       ├── ARCHITECTURE_AS_PROTOCOL.md
│       ├── ORCHESTRATION_STRATEGY.md
│       └── STANDARDS_INTEGRATION.md
│
└── .github/ ← GitHub configuration
    ├── ISSUE_TEMPLATE/ (bug report, feature request, support)
    ├── LABELS.md
    ├── SUPPORT_TEMPLATES.md
    └── INITIAL_ISSUES.md
```

---

## 🔄 Typical Workflows

### Morning Workflow (15 min)
```
1. Check email → Triage support
2. Check GitHub Issues → Triage new issues
3. Check Project Board → See what's in progress
4. Start coding!
```

### Committing Work
```
1. Make changes
2. git add .
3. git commit -m "Description (#ISSUE_NUMBER)"
4. git push
```

### Weekly Review (Friday, 30 min)
```
1. Clean up project board
2. Update CHANGELOG.md
3. Review support metrics
4. Plan next week
```

### Shipping a Release
```
1. Update version in Xcode
2. Update CHANGELOG.md
3. Run tests
4. Build & archive
5. Upload to TestFlight (beta for 3-5 days)
6. Submit to App Store
7. Monitor crashes
```

---

## 🆘 Emergency Contacts

### Something's Broken in Production
→ [Emergency Procedures](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#emergency-procedures)

### Support Emails Piling Up
→ [Support Email Backlog](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#support-email-backlog)

### Can't Remember How to Do Something
→ [PROCEDURES_QUICK_REFERENCE.md](./docs/operations/PROCEDURES_QUICK_REFERENCE.md)

---

## 📊 Your Tools

### GitHub
- **Issues:** `https://github.com/EldestGruff/STASH/issues`
- **Project Board:** `https://github.com/EldestGruff/STASH/projects`
- **Repo:** `https://github.com/EldestGruff/STASH`

### Gmail
- Support label/folder
- Canned response templates
- [Support Templates](./github/SUPPORT_TEMPLATES.md)

### App Store Connect
- https://appstoreconnect.apple.com
- Check: Crashes, analytics, reviews

---

## 🎯 Current Focus

**Phase:** 3A Complete ✅

**Next Up:**
- Phase 4: Intelligence & Automation
  - Smart date/time parsing
  - Calendar selection
  - Event duration intelligence

**Known Bugs:**
- (Check GitHub Issues with `bug` label)

**Backlog:**
- (Check GitHub Project Board → Backlog)

---

## 💡 Tips

### Keep These Open
1. GitHub Project Board (tab 1)
2. This Quick Start (tab 2)
3. Procedures Quick Reference (tab 3)
4. Gmail (tab 4)

### Keyboard Shortcuts
- `⌘K` in GitHub → Quick search
- `c` in Gmail → Compose
- `g i` in GitHub → Go to issues

### Weekly Habits
- **Monday AM:** Plan the week
- **Daily:** Quick issue/support check (15 min)
- **Friday PM:** Review and clean up

---

## 📖 Full Documentation

**For complete documentation navigation:**
→ [docs/DOCUMENTATION_INDEX.md](./docs/DOCUMENTATION_INDEX.md)

**26 documentation files covering:**
- Operations (7 files)
- Planning (7 files)
- Development (3 files)
- GitHub setup (7 files)
- Root docs (2 files)

---

## 🚀 Getting Started Today

**If you're starting fresh:**
1. Read [PROCEDURES_QUICK_REFERENCE.md](./docs/operations/PROCEDURES_QUICK_REFERENCE.md) (30 min)
2. Bookmark it
3. Start using it!

**If you're continuing development:**
1. Check Project Board → Pick issue
2. Follow [Starting Work](./docs/operations/PROCEDURES_QUICK_REFERENCE.md#starting-work-on-an-issue)
3. Code!

**If you have questions:**
1. Check [PROCEDURES_QUICK_REFERENCE.md](./docs/operations/PROCEDURES_QUICK_REFERENCE.md) first
2. Then check specific doc (operations/planning/development)
3. Then [DOCUMENTATION_INDEX.md](./docs/DOCUMENTATION_INDEX.md)

---

**Remember:** You don't need to read everything. Start with what you need right now.

**Most important:** [PROCEDURES_QUICK_REFERENCE.md](./docs/operations/PROCEDURES_QUICK_REFERENCE.md)

**Bookmark this page for quick navigation!**

---

Last Updated: 2026-01-20
