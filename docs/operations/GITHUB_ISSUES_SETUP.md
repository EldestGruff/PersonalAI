# GitHub Issues Setup Guide

**Last Updated:** 2026-01-20

## Purpose

Set up GitHub Issues as your bug/feature tracking system. This is free, integrates with your code, and works well for solo/small teams.

---

## Why GitHub Issues?

**Pros:**
- Free and already have a GitHub repo
- Issues live next to the code
- Can reference commits/PRs from issues
- Templates for consistency
- Labels for categorization
- Milestones for release planning
- Projects for kanban boards

**Cons:**
- Not as polished as dedicated tools (Linear, Jira)
- Customers need GitHub account to file issues directly
- Less customer-friendly interface

**Verdict:** Perfect for starting out, can migrate later if needed

---

## Setup Steps

### Step 1: Enable Issues on Your Repo

1. Go to your GitHub repo settings
2. Ensure "Issues" is checked under Features
3. (Should be enabled by default)

### Step 2: Create Issue Templates

GitHub supports issue templates to guide users in filing good bug reports and feature requests.

**Create directory:**
```bash
mkdir -p .github/ISSUE_TEMPLATE
```

**Create three templates:**

#### Template 1: Bug Report

Create `.github/ISSUE_TEMPLATE/bug_report.yml`:

```yaml
name: Bug Report
description: Report a bug or issue with the app
title: "[Bug]: "
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to report this bug!

  - type: input
    id: ios-version
    attributes:
      label: iOS Version
      description: What version of iOS are you running?
      placeholder: "iOS 18.1"
    validations:
      required: true

  - type: input
    id: app-version
    attributes:
      label: App Version
      description: What version of PersonalAI? (Found in Settings → About)
      placeholder: "1.0.0 (123)"
    validations:
      required: true

  - type: input
    id: device
    attributes:
      label: Device
      description: What device are you using?
      placeholder: "iPhone 15 Pro"
    validations:
      required: true

  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: Describe the bug clearly and concisely
      placeholder: When I try to capture a thought with voice input, the app crashes
    validations:
      required: true

  - type: textarea
    id: steps-to-reproduce
    attributes:
      label: Steps to Reproduce
      description: How can we reproduce this issue?
      placeholder: |
        1. Open app
        2. Tap microphone button
        3. Speak for 5 seconds
        4. App crashes
    validations:
      required: true

  - type: textarea
    id: expected-behavior
    attributes:
      label: Expected Behavior
      description: What did you expect to happen?
      placeholder: Thought should be captured and saved
    validations:
      required: true

  - type: textarea
    id: actual-behavior
    attributes:
      label: Actual Behavior
      description: What actually happened?
      placeholder: App crashed and I was returned to home screen
    validations:
      required: true

  - type: textarea
    id: additional-context
    attributes:
      label: Additional Context
      description: Any other information (screenshots, logs, etc.)
      placeholder: This only happens when Bluetooth is connected
    validations:
      required: false
```

#### Template 2: Feature Request

Create `.github/ISSUE_TEMPLATE/feature_request.yml`:

```yaml
name: Feature Request
description: Suggest a new feature or enhancement
title: "[Feature]: "
labels: ["enhancement", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting a feature! We'd love to hear your ideas.

  - type: textarea
    id: feature-description
    attributes:
      label: Feature Description
      description: What feature would you like to see?
      placeholder: I'd like to be able to search thoughts by date range
    validations:
      required: true

  - type: textarea
    id: use-case
    attributes:
      label: Use Case
      description: Why do you need this feature? How would you use it?
      placeholder: |
        I capture a lot of thoughts and sometimes want to review what I was thinking
        during a specific week or month. Currently I have to scroll through everything.
    validations:
      required: true

  - type: textarea
    id: proposed-solution
    attributes:
      label: Proposed Solution (Optional)
      description: How do you envision this working?
      placeholder: |
        Maybe a filter button at the top of the thought list with date range options
        like "Last 7 days", "Last 30 days", "Custom range"
    validations:
      required: false

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: Are there other ways to solve this problem?
      placeholder: I've tried using tags but it's too manual
    validations:
      required: false

  - type: dropdown
    id: priority
    attributes:
      label: How important is this to you?
      options:
        - Nice to have
        - Would improve my workflow
        - Critical - I can't use the app effectively without this
    validations:
      required: true
```

#### Template 3: Support Question

Create `.github/ISSUE_TEMPLATE/support.yml`:

```yaml
name: Support Question
description: Ask a question about using the app
title: "[Question]: "
labels: ["question"]
body:
  - type: markdown
    attributes:
      value: |
        Have a question? We're here to help!

  - type: textarea
    id: question
    attributes:
      label: Your Question
      description: What would you like to know?
      placeholder: How do I change which calendar events are added to?
    validations:
      required: true

  - type: textarea
    id: context
    attributes:
      label: Additional Context
      description: Any other details that might help us answer your question
      placeholder: I have multiple calendars and want work events to go to my work calendar
    validations:
      required: false
```

### Step 3: Create Issue Labels

Labels help categorize and filter issues. Create these labels in your repo:

**By Type:**
- `bug` (red) - Something isn't working
- `enhancement` (blue) - New feature or request
- `question` (purple) - Support question
- `documentation` (teal) - Improvements to documentation

**By Priority:**
- `priority: critical` (dark red) - App-breaking, immediate fix needed
- `priority: high` (orange) - Important, fix soon
- `priority: medium` (yellow) - Standard priority
- `priority: low` (light gray) - Nice to have

**By Status:**
- `needs-triage` (dark gray) - Needs review and prioritization
- `in-progress` (green) - Currently being worked on
- `blocked` (dark orange) - Waiting on something
- `wontfix` (white) - Won't be fixed, with explanation
- `duplicate` (light gray) - Duplicate of another issue

**By Area:**
- `area: ai` - AI classification/sentiment
- `area: context` - Context gathering (location, health, etc.)
- `area: ui` - User interface
- `area: performance` - Speed/efficiency issues
- `area: backend` - Backend/sync issues

### Step 4: Set Up GitHub Projects (Kanban Board)

1. Go to your repo → Projects → New Project
2. Choose "Board" template
3. Name it "PersonalAI Development"
4. Create columns:
   - **Backlog** - Ideas, low priority
   - **To Do** - Planned for upcoming work
   - **In Progress** - Currently working on
   - **Done** - Completed

5. Set up automation:
   - New issues → Backlog
   - Issues with "in-progress" label → In Progress
   - Closed issues → Done

### Step 5: Create Milestones for Releases

Milestones help group issues for specific releases:

1. Go to Issues → Milestones → New Milestone
2. Create milestone: "v1.0 - Initial Release"
3. Set due date (optional)
4. Assign issues to milestone as you plan work

Example milestones:
- `v1.0 - Initial Release`
- `v1.1 - Smart Date Parsing`
- `v1.2 - Backend Integration`
- `v2.0 - Major Redesign`

---

## Workflow: From Bug Report to Fix

### 1. User Reports Bug (via GitHub Issue)
- User fills out bug report template
- Issue created with "bug" and "needs-triage" labels
- Automatically added to Backlog column

### 2. You Triage (Monday, weekly)
- Review new issues with "needs-triage" label
- Assess priority (critical/high/medium/low)
- Add priority label
- Remove "needs-triage" label
- Move to appropriate column (Backlog or To Do)
- Respond to user: "Thanks for reporting! I've triaged this as [priority]"

### 3. You Work on Issue
- Move issue to "In Progress" column
- Add "in-progress" label
- Create branch: `git checkout -b fix/issue-123-voice-crash`
- Fix the bug
- Reference issue in commits: `git commit -m "Fix voice crash (#123)"`

### 4. You Ship the Fix
- Merge PR (references issue)
- Close issue with comment: "Fixed in v1.2.0"
- Issue automatically moves to "Done" column
- User is notified

### 5. Release Notes
- Review closed issues in milestone
- Write "What's New" for App Store
- Tag release in GitHub: `git tag v1.2.0`

---

## Workflow: From Feature Request to Implementation

### 1. User Requests Feature
- User fills out feature request template
- Issue created with "enhancement" and "needs-triage" labels

### 2. You Evaluate
- Assess fit with roadmap
- Consider effort vs. value
- Decide: Build now / Build later / Won't build
- Label accordingly and move to appropriate column
- Respond with decision and reasoning

### 3. If Building:
- Add to CUSTOMER_REQUESTS.md for tracking
- Add detailed spec to FEATURES.md
- Assign to milestone
- Move to "To Do" when ready to work on

### 4. Build and Ship
- Same as bug fix workflow
- Announce in release notes
- Thank user for suggestion

---

## Customer-Facing vs. Internal Issues

**Problem:** Not all issues should be public (security issues, internal tasks)

**Solution:** Use private issues for sensitive stuff

1. For **security issues**: Email only, don't file public GitHub issue
2. For **internal tasks**: Create issues in a separate private repo or use GitHub Projects without linking to public issues

---

## Integration with CUSTOMER_REQUESTS.md

Your `CUSTOMER_REQUESTS.md` is your source of truth, GitHub Issues is your workflow tool.

**How they work together:**
1. Issue filed on GitHub
2. You triage and prioritize
3. Add to CUSTOMER_REQUESTS.md with link: `Related: #123`
4. Update status in CUSTOMER_REQUESTS.md as you work
5. Close GitHub issue when done

**Why both?**
- GitHub Issues: Active workflow, community visibility
- CUSTOMER_REQUESTS.md: Long-term tracking, historical record, planning

---

## Communication Best Practices

### When Responding to Bug Reports:
```markdown
Thanks for reporting this! I've confirmed the bug and prioritized it as [high/medium/low].

[If you can reproduce:] I was able to reproduce this on my device.
[If you can't:] I haven't been able to reproduce this yet - could you provide [additional info]?

I'll update this issue as I work on it.
```

### When Closing a Bug:
```markdown
This has been fixed in version 1.2.0, which is now available on the App Store!

Thanks again for reporting this - it really helps improve the app.
```

### When Declining a Feature Request:
```markdown
Thanks for the suggestion! I've thought about this carefully, and I've decided not to build this because [clear reason].

Here's my thinking: [explain reasoning]

I know this might be disappointing, but I want to be upfront about what I'm prioritizing. I appreciate you taking the time to share your idea!
```

### When Deferring a Feature Request:
```markdown
This is a great idea! I've added it to the roadmap for a future release.

I'm not working on it right now because [reason], but I'll revisit this in [timeframe or milestone].

I'll keep this issue open and update it when I make progress.
```

---

## Automation Opportunities

### GitHub Actions for Issue Management

Create `.github/workflows/issue-triage.yml`:

```yaml
name: Issue Triage

on:
  issues:
    types: [opened]

jobs:
  auto-label:
    runs-on: ubuntu-latest
    steps:
      - name: Add needs-triage label
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              labels: ['needs-triage']
            })

      - name: Thank the user
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: 'Thanks for filing this issue! I'll review it soon and follow up.'
            })
```

---

## Example: Full Bug Workflow

1. **Monday AM:** User files bug #47 "App crashes when creating event"
2. **Monday PM:** You triage:
   - Reproduce bug ✓
   - Add label: `priority: high`
   - Add label: `area: calendar`
   - Remove label: `needs-triage`
   - Move to "To Do"
   - Comment: "Thanks! Confirmed bug, working on fix this week"

3. **Tuesday:** Start working:
   - Move to "In Progress"
   - Create branch `fix/issue-47-event-crash`
   - Add commits: `Fix EventKit crash (#47)`

4. **Wednesday:** Fix complete:
   - Merge PR
   - Close issue with: "Fixed in v1.3.0, releasing Friday"
   - Move to "Done"

5. **Friday:** Release v1.3.0:
   - Tag release
   - Update App Store: "Fixed crash when creating events"
   - User gets notification

Total time: 2 hours of dev work, spread over 3 days. Customer gets fix within 1 week.

---

## Next Steps

1. Create the templates in `.github/ISSUE_TEMPLATE/`
2. Set up labels in your repo
3. Create a GitHub Project board
4. Create your first milestone
5. Start using issues for your own TODO tracking
6. When you have beta testers, share the GitHub Issues link

Then move on to: **[SUPPORT_WORKFLOW.md](./SUPPORT_WORKFLOW.md)**
