# Customer Support Workflow

**Last Updated:** 2026-01-20

## Purpose

Define a sustainable process for handling customer support as a solo developer. Focus on efficiency without sacrificing customer satisfaction.

---

## Support Channels

### In-App (Primary)
**Setup:** Add "Help & Feedback" button in Settings

**Pros:**
- Captures device/app info automatically
- Low friction for users
- Can pre-populate email with diagnostics

**Cons:**
- Requires implementing feedback UI

**Implementation:**
```swift
// In SettingsScreen
Button("Help & Feedback") {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let iosVersion = UIDevice.current.systemVersion
    let deviceModel = UIDevice.current.model

    let body = """


    ---
    App Version: \(appVersion) (\(buildNumber))
    iOS Version: \(iosVersion)
    Device: \(deviceModel)
    """

    let email = "support@yourapp.com"
    let subject = "STASH Support Request"
    let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

    if let url = URL(string: urlString ?? "") {
        UIApplication.shared.open(url)
    }
}
```

### Email (support@yourapp.com)
**Setup:**
- Option A: Gmail with custom domain (~$12/year for domain)
- Option B: Generic Gmail (support.personalai@gmail.com)

**Pros:**
- Everyone knows email
- Can use canned responses
- Persistent history

**Cons:**
- Can get overwhelming
- Requires manual tracking

### App Store Reviews
**Setup:** Monitor and respond via App Store Connect

**Pros:**
- Shows you care publicly
- Can convert negative → positive reviews

**Cons:**
- Can't have back-and-forth
- Public forum

**Strategy:**
- Check App Store Connect daily (5 min)
- Respond to all reviews, especially negative ones
- For bugs: "Thanks for reporting! Please email support@... so I can help fix this"
- For positive: "Thanks for the kind words! Glad you're enjoying it"

---

## Support SLAs (Service Level Agreements)

**Set expectations for yourself:**

| Priority | First Response | Resolution |
|----------|---------------|------------|
| Critical (app broken for all users) | 4 hours | 24 hours |
| High (major feature broken) | 24 hours | 3 days |
| Medium (bug affecting some users) | 48 hours | 1 week |
| Low (questions, minor issues) | 48 hours | N/A |

**Why SLAs for yourself?**
- Prevents support from piling up
- Users appreciate predictability
- Keeps you accountable

---

## Email Management System

### Setup Gmail Labels

Create these labels:
- `Support/New` - Unread support emails
- `Support/In Progress` - Waiting on you
- `Support/Waiting on Customer` - Waiting for customer reply
- `Support/Resolved` - Closed
- `Priority/Critical`
- `Priority/High`
- `Priority/Medium`
- `Priority/Low`
- `Type/Bug`
- `Type/Feature Request`
- `Type/Question`
- `Type/Billing` (future)

### Filters (Auto-label)

Create Gmail filter:
- **From:** *
- **To:** support@yourapp.com
- **Apply label:** `Support/New`
- **Mark as important**

### Daily Workflow

**Morning (15 min):**
1. Check `Support/New` label
2. Triage each email:
   - Read quickly
   - Apply priority label
   - Apply type label
   - Move to `Support/In Progress` if you'll work on it
   - Move to `Support/Waiting on Customer` if you need more info
3. Respond to critical/high priority immediately

**Afternoon (15 min):**
- Work through `Support/In Progress`
- Use canned responses for common questions

**End of day (5 min):**
- Check for any new critical issues
- Archive resolved issues to `Support/Resolved`

**Weekly (30 min):**
- Review `Support/Waiting on Customer` - follow up if >5 days
- Clean up old resolved items

---

## Canned Responses (Templates)

### General Acknowledgment
```
Subject: Re: [original subject]

Hi [Name],

Thanks for reaching out! I've received your message and I'm looking into it.

I'll get back to you within [24/48] hours with an update.

Best,
[Your Name]
STASH Support
```

### Bug Report Acknowledgment
```
Subject: Re: [original subject]

Hi [Name],

Thanks for reporting this bug! I really appreciate you taking the time to help improve the app.

I've filed this as issue #[number] and I'm investigating it now. I'll keep you updated on progress.

In the meantime, [if there's a workaround, mention it here].

Best,
[Your Name]
```

### Feature Request Response
```
Subject: Re: [original subject]

Hi [Name],

Great suggestion! I've added this to the feature request backlog.

I can't promise when (or if) this will be built, but I review these regularly and prioritize based on user demand and feasibility.

You can follow progress on our public roadmap: [link]

Thanks for helping shape the future of STASH!

Best,
[Your Name]
```

### Bug Fixed Notification
```
Subject: Re: [original subject] - FIXED

Hi [Name],

Good news! The bug you reported has been fixed in version [X.X.X], which is now available on the App Store.

Thanks again for reporting this - it really helps make the app better for everyone.

Let me know if you run into any other issues!

Best,
[Your Name]
```

### "I Can't Reproduce This" Response
```
Subject: Re: [original subject]

Hi [Name],

Thanks for the report! I've tried to reproduce this issue on my device but haven't been able to yet.

Could you help me out with a few more details?
- [Specific question 1]
- [Specific question 2]
- [Can you share a screenshot?]

This will help me track down the issue.

Thanks!
[Your Name]
```

### How-To Answer
```
Subject: Re: [original subject]

Hi [Name],

Great question! Here's how to do that:

1. [Step 1]
2. [Step 2]
3. [Step 3]

Let me know if you have any other questions!

Best,
[Your Name]

P.S. I'm also adding this to our documentation so others can find it easily.
```

---

## Tracking Support Conversations

### Option A: Notion Database (Free)

Create a Notion database with these fields:
- **Title:** Short description
- **Customer Email:** Text
- **Status:** Select (New, In Progress, Waiting, Resolved)
- **Priority:** Select (Critical, High, Medium, Low)
- **Type:** Select (Bug, Feature, Question, Billing)
- **Created:** Date
- **Last Updated:** Date
- **GitHub Issue:** URL (if linked to issue)
- **Notes:** Text

**Workflow:**
1. Receive support email
2. Create Notion entry
3. Update as you work on it
4. Mark resolved when done

**Why Notion?**
- Free for personal use
- Flexible database views
- Can link to GitHub issues
- Good for seeing patterns (lots of questions about X feature = needs better docs)

### Option B: Simple Spreadsheet

Google Sheets with columns:
- Email | Subject | Priority | Type | Status | Created | GitHub Link | Notes

**Pros:** Super simple, works offline
**Cons:** Less flexible than Notion

---

## Escalation Process

### When You Can't Fix It Immediately

1. **Acknowledge quickly:**
   ```
   Thanks for reporting this! This is trickier than I initially thought.
   I'm working on a fix but it might take [X days].
   ```

2. **Provide workaround if possible:**
   ```
   In the meantime, you can [workaround] to avoid the issue.
   ```

3. **Update periodically:**
   ```
   Quick update: I'm still working on this. I've identified the root cause
   and I'm testing a fix. Should have this resolved by [date].
   ```

4. **When fixed:**
   ```
   Good news! This is fixed in version X.X.X. Thanks for your patience!
   ```

### When You Can't/Won't Fix It

Be honest:
```
Thanks for the report. I've looked into this and unfortunately it's not
something I can fix in the near term because [reason].

I know this is frustrating - I'm sorry I can't help more with this right now.

If anything changes, I'll let you know.
```

---

## Dealing with Difficult Customers

### The Angry Customer
**Approach:** Empathy + Action

```
I'm really sorry you're experiencing this issue - I can understand how
frustrating that must be.

Here's what I'm going to do:
1. [Specific action]
2. [Specific action]

I'll have an update for you by [specific time].

Thanks for your patience.
```

### The Demanding Customer
**Approach:** Set boundaries politely

```
I appreciate your feedback! I want to set the right expectations:

I'm a solo developer working on this app, so I prioritize fixes based on
impact and feasibility. I can't commit to a specific timeline for this,
but I've added it to the backlog.

I'll keep you posted if/when I'm able to work on it.
```

### The Serial Requester
**Approach:** Gratitude + Gentle redirect

```
I love that you're so engaged with the app! You've sent several great ideas.

To keep things organized, could you file these as feature requests on GitHub?
[link to GitHub Issues]

That way the community can also vote and discuss, which helps me prioritize.

Thanks!
```

---

## Support Metrics to Track

### Weekly:
- **Volume:** How many support emails?
- **Average response time:** Are you meeting your SLAs?
- **Resolution rate:** What % are resolved vs. still open?

### Monthly:
- **Common issues:** What are people asking about most?
- **Feature requests:** What features are most requested?
- **Time spent:** How many hours/week on support?

**Why track?**
- Identify patterns (lots of questions about X = needs better UI/docs)
- Catch problems early (spike in crash reports = urgent bug)
- Improve efficiency (create docs for common questions)

---

## Proactive Support (Reduce Volume)

### 1. In-App Help
- Tooltips on confusing features
- Onboarding tour for new users
- Contextual help ("What is energy level?")

### 2. Documentation
- FAQ page on website
- Video tutorials (if applicable)
- Changelog with details

### 3. Better Error Messages
Instead of: "Error occurred"
Use: "Couldn't save thought. Please check your internet connection and try again."

### 4. Feature Announcements
When shipping new features, explain them:
- In-app announcement banner
- "What's New" in App Store
- Email to users (if you have newsletter)

---

## When to Upgrade to Help Desk Software

**Stick with Gmail + Notion until:**
- You're spending >10 hours/week on support
- You have >100 active support conversations/month
- You're losing track of conversations
- You need multiple people helping with support

**Then consider:** Plain ($20/month), Crisp ($25/month), or Intercom ($74/month)

**Benefits of help desk software:**
- Better conversation tracking
- Shared inbox for team
- Canned responses built-in
- Analytics on response times
- Customer history in one place

---

## Support as Product Development

**Key insight:** Support emails are product feedback

### Extract Value:
1. **Bug reports** → Fix bugs, improve quality
2. **Feature requests** → Understand user needs
3. **Questions** → Improve UI/UX, add docs
4. **Complaints** → Fix pain points

### Monthly Review:
- Read through all support conversations
- Look for patterns
- Ask: "What could I build/change to reduce this type of support request?"

**Example:**
- 5 people asked "How do I change calendars?" this month
- **Action:** Add calendar selection to settings + in-app help
- **Result:** Fewer support emails next month

---

## Sample Weekly Support Schedule

**Monday:**
- 9:00-9:30am: Triage weekend support emails
- 5:00-5:30pm: Respond to high priority

**Tuesday:**
- 9:00-9:15am: Check for new emails
- 2:00-2:30pm: Work through in-progress support items

**Wednesday:**
- 9:00-9:15am: Check for new emails
- 5:00-5:30pm: Respond to anything from last 24 hours

**Thursday:**
- 9:00-9:15am: Check for new emails
- 2:00-2:30pm: Follow up on waiting-on-customer items

**Friday:**
- 9:00-9:30am: Check for new emails
- 4:00-4:30pm: Clean up resolved items, weekly metrics review

**Total time: ~3-4 hours/week for moderate volume**

---

## Next Steps

1. Set up support email (Gmail or custom domain)
2. Add "Help & Feedback" button to app
3. Create Gmail labels and canned responses
4. Set up Notion database for tracking
5. Commit to your SLAs (write them down!)
6. Test the workflow with beta users

Then move on to: **[RELEASE_PROCESS.md](./RELEASE_PROCESS.md)**
