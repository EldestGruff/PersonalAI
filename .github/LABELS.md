# GitHub Labels Setup

**Instructions:** Create these labels in your GitHub repository

Go to: Repository → Issues → Labels → New label

---

## Labels to Create

### By Type

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | `#d73a4a` (red) | Something isn't working |
| `enhancement` | `#a2eeef` (blue) | New feature or request |
| `question` | `#d876e3` (purple) | Support question |
| `documentation` | `#0075ca` (teal) | Improvements to documentation |
| `support` | `#d876e3` (purple) | User support needed |

### By Priority

| Label | Color | Description |
|-------|-------|-------------|
| `priority: critical` | `#b60205` (dark red) | App-breaking, immediate fix needed |
| `priority: high` | `#d93f0b` (orange) | Important, fix soon |
| `priority: medium` | `#fbca04` (yellow) | Standard priority |
| `priority: low` | `#e4e669` (light yellow) | Nice to have |

### By Status

| Label | Color | Description |
|-------|-------|-------------|
| `needs-triage` | `#ededed` (light gray) | Needs review and prioritization |
| `in-progress` | `#0e8a16` (green) | Currently being worked on |
| `blocked` | `#d93f0b` (orange) | Waiting on something |
| `wontfix` | `#ffffff` (white) | Won't be fixed, with explanation |
| `duplicate` | `#cfd3d7` (gray) | Duplicate of another issue |

### By Area

| Label | Color | Description |
|-------|-------|-------------|
| `area: ai` | `#5319e7` (purple) | AI classification/sentiment |
| `area: context` | `#1d76db` (blue) | Context gathering (location, health, etc.) |
| `area: ui` | `#c5def5` (light blue) | User interface |
| `area: performance` | `#f9d0c4` (peach) | Speed/efficiency issues |
| `area: backend` | `#006b75` (teal) | Backend/sync issues (future) |
| `area: permissions` | `#fef2c0` (cream) | Permission-related issues |

---

## Quick Setup Instructions

### Option 1: Manual Creation (Recommended First Time)

1. Go to your GitHub repo: `https://github.com/yourusername/personal-ai-ios`
2. Click "Issues" tab
3. Click "Labels" (next to Milestones)
4. Click "New label" for each label above
5. Enter name, description, and color code
6. Click "Create label"

### Option 2: GitHub CLI (Faster if you have many repos)

If you have GitHub CLI installed:

```bash
# Install gh if needed
brew install gh

# Authenticate
gh auth login

# Create labels (run from repo root)
gh label create "bug" --color "d73a4a" --description "Something isn't working"
gh label create "enhancement" --color "a2eeef" --description "New feature or request"
gh label create "question" --color "d876e3" --description "Support question"
gh label create "documentation" --color "0075ca" --description "Improvements to documentation"
gh label create "support" --color "d876e3" --description "User support needed"

gh label create "priority: critical" --color "b60205" --description "App-breaking, immediate fix needed"
gh label create "priority: high" --color "d93f0b" --description "Important, fix soon"
gh label create "priority: medium" --color "fbca04" --description "Standard priority"
gh label create "priority: low" --color "e4e669" --description "Nice to have"

gh label create "needs-triage" --color "ededed" --description "Needs review and prioritization"
gh label create "in-progress" --color "0e8a16" --description "Currently being worked on"
gh label create "blocked" --color "d93f0b" --description "Waiting on something"
gh label create "wontfix" --color "ffffff" --description "Won't be fixed, with explanation"
gh label create "duplicate" --color "cfd3d7" --description "Duplicate of another issue"

gh label create "area: ai" --color "5319e7" --description "AI classification/sentiment"
gh label create "area: context" --color "1d76db" --description "Context gathering (location, health, etc.)"
gh label create "area: ui" --color "c5def5" --description "User interface"
gh label create "area: performance" --color "f9d0c4" --description "Speed/efficiency issues"
gh label create "area: backend" --color "006b75" --description "Backend/sync issues (future)"
gh label create "area: permissions" --color "fef2c0" --description "Permission-related issues"
```

---

## Default GitHub Labels to Remove

GitHub creates some default labels you probably don't need. Consider deleting:
- `good first issue` (you're solo, not recruiting contributors)
- `help wanted` (same reason)
- `invalid`

Keep these default ones (they're useful):
- Keep or rename to match your system

---

## Usage Guidelines

### Applying Labels

**Every issue should have:**
- 1 type label (bug, enhancement, question, etc.)
- 1 priority label (critical, high, medium, low)
- 1 status label (needs-triage → in-progress → done via closing)
- 0-2 area labels (what part of app)

**Example labeled issue:**
```
Title: Voice input crashes on iPhone 15
Labels: bug, priority: high, area: ui, needs-triage
```

### Label Workflow

1. **New issue filed** → Auto-gets `needs-triage`
2. **You review** → Add priority + area, remove `needs-triage`
3. **You start work** → Add `in-progress`
4. **You finish** → Close issue (auto-removes from project board)
5. **If blocked** → Add `blocked`, comment why
6. **If duplicate** → Add `duplicate`, link to original, close
7. **If won't fix** → Add `wontfix`, comment reasoning, close

---

## Next Step

After creating labels, set up GitHub Project board (see repository instructions or docs/operations/GITHUB_ISSUES_SETUP.md)
