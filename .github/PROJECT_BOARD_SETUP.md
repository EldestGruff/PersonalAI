# GitHub Project Board Setup

**Instructions for creating a kanban board to track issues**

---

## Create the Project Board

### Step 1: Navigate to Projects

1. Go to your GitHub repository
2. Click "Projects" tab (top navigation)
3. Click "New project" (green button)

### Step 2: Choose Template

1. Select **"Board"** template (kanban-style)
2. Click "Create"

### Step 3: Name and Configure

1. **Project name:** "PersonalAI Development"
2. **Description:** "Bug tracking, feature planning, and development workflow"
3. **Visibility:** Private (or Public if you want community visibility)
4. Click "Create project"

---

## Customize Columns

The Board template comes with columns: "Todo", "In Progress", "Done"

**Rename them for clarity:**

### Column 1: 📋 Backlog
- **Purpose:** Ideas, low priority items, future considerations
- **Status:** Not actively working on, but captured for later

### Column 2: 📝 To Do
- **Purpose:** Planned work for current sprint/week
- **Status:** Ready to work on

### Column 3: 🚧 In Progress
- **Purpose:** Currently being worked on
- **Status:** Active development
- **Limit:** Try to keep this to 1-3 items (focus!)

### Column 4: ✅ Done
- **Purpose:** Completed and shipped
- **Status:** Closed issues automatically go here

---

## Set Up Automation

GitHub Projects has built-in automation:

### Auto-add Items

1. Click "..." (three dots) on project board
2. Click "Workflows"
3. Enable: **"Auto-add to project"**
   - When: Issues and PRs are opened
   - Then: Add to "📋 Backlog"

### Auto-move Items

4. Enable: **"Item closed"**
   - When: Issue or PR is closed
   - Then: Move to "✅ Done"

5. Enable: **"Pull request merged"**
   - When: PR is merged
   - Then: Move to "✅ Done"

### Manual Workflows (You'll do these)

- Move from Backlog → To Do when planning work
- Move from To Do → In Progress when starting
- Close issue (auto-moves to Done)

---

## Add Custom Fields (Optional but Useful)

### Priority Field

1. Click "+" in table header
2. "New field"
3. Name: "Priority"
4. Type: "Single select"
5. Options:
   - 🔴 Critical
   - 🟠 High
   - 🟡 Medium
   - ⚪ Low

### Status Field

GitHub automatically tracks status based on column, but you can add explicit status:

1. "New field"
2. Name: "Status"
3. Type: "Single select"
4. Options:
   - 🆕 New
   - 🔍 Investigating
   - 📋 Planned
   - 🚧 In Progress
   - ⏸️ Blocked
   - ✅ Done
   - ❌ Won't Fix

### Effort Field (For planning)

1. "New field"
2. Name: "Effort"
3. Type: "Single select"
4. Options:
   - 🟢 Small (< 2 hours)
   - 🟡 Medium (2-8 hours)
   - 🔴 Large (1+ days)
   - 🟣 Epic (multi-day)

---

## Using the Project Board

### Daily Workflow

**Morning:**
1. Check "🚧 In Progress" - continue where you left off
2. If stuck, move to Backlog with comment

**During work:**
1. Move card to "🚧 In Progress" when starting
2. Add comments as you work
3. Link commits by mentioning issue number: `Fixes #42`

**When done:**
1. Close the issue (it auto-moves to Done)
2. Pick next item from "📝 To Do"

### Weekly Planning

**Friday or Monday:**
1. Review "📋 Backlog" - triage new items
2. Move items you'll work on this week to "📝 To Do"
3. Set Priority field for To Do items
4. Limit To Do to ~5-10 items (realistic for the week)

### Filtering and Views

**Create custom views:**

1. **Current Sprint** (Tab 1)
   - Filter: Status is "To Do" or "In Progress"
   - Shows only active work

2. **Bugs Only** (Tab 2)
   - Filter: Label includes "bug"
   - Sort: Priority (high → low)

3. **Feature Requests** (Tab 3)
   - Filter: Label includes "enhancement"
   - Group by: Priority

---

## Linking Issues to Project

### Automatic (with workflow enabled)
New issues automatically added to Backlog

### Manual
1. Open any issue
2. Right sidebar → "Projects"
3. Click "Add to project"
4. Select "PersonalAI Development"
5. Issue appears in Backlog

---

## Example Workflow in Action

### Scenario: User reports bug

1. **User creates issue** using bug template
   - Auto-labeled: `bug`, `needs-triage`
   - Auto-added to project → 📋 Backlog

2. **You triage (Monday)**
   - Read issue
   - Add label: `priority: high`, `area: context`
   - Remove label: `needs-triage`
   - Move to → 📝 To Do (planning to fix this week)

3. **You start work (Tuesday)**
   - Move to → 🚧 In Progress
   - Add label: `in-progress`
   - Create branch: `git checkout -b fix/issue-1-step-count`

4. **You commit fix**
   - `git commit -m "Fix step count collection (#1)"`
   - GitHub auto-links commit to issue

5. **You finish (Wednesday)**
   - Push code
   - Close issue with comment: "Fixed in commit abc123"
   - Issue auto-moves to → ✅ Done
   - Label `in-progress` removed

---

## Tips for Solo Developer

### Keep It Simple
- Don't over-organize
- Only move cards when it makes sense
- Weekly triage is enough (don't need daily)

### Use it for Planning
- Friday: Review what got done, plan next week
- Monday: Quick look at priorities
- Don't need to update every minute

### Link Everything
- Reference issues in commits: `#1`, `#2`
- Reference issues in PRs: `Closes #1`
- Comment on issues with progress

### Archive Old Items
- Every month, archive completed items in ✅ Done
- Keeps board clean
- History still accessible

---

## Mobile App (Optional)

GitHub has a mobile app for checking issues on the go:
- iOS: GitHub Mobile
- Useful for quick triage during coffee breaks
- Not required, but handy

---

## Next Steps

1. Create the project board (5 min)
2. Customize columns (2 min)
3. Set up automation (3 min)
4. Add custom fields if desired (5 min)
5. Create initial issues and add them to board (see next doc)

**Total setup time: ~15 minutes**

Then you'll have a working kanban board for all future work!
