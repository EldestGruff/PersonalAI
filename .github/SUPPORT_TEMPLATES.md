# Support Email Templates (Canned Responses)

**For use with Gmail or any email client**

These templates help you respond quickly and consistently to common support questions.

---

## How to Set Up in Gmail

### Create Canned Responses

1. **Enable Canned Responses (Templates)**
   - Gmail Settings → "See all settings"
   - Advanced tab
   - Find "Templates" → Enable
   - Save changes

2. **Create a Template**
   - Compose new email
   - Type the template text (see below)
   - Click three dots (⋮) → Templates → Save draft as template → Save as new template
   - Name it (e.g., "Support - General Acknowledgment")

3. **Use a Template**
   - When replying to support email
   - Click three dots (⋮) → Templates → Select template
   - Customize as needed
   - Send

---

## Template 1: General Acknowledgment

**Use when:** First response to any support email

**Template name:** `Support - General Ack`

**Subject:** `Re: [keep original subject]`

**Body:**
```
Hi [Name],

Thanks for reaching out! I've received your message and I'm looking into it.

I'll get back to you within 24-48 hours with an update or solution.

In the meantime, if you have any additional details that might help (screenshots, specific error messages, etc.), feel free to reply to this email.

Best,
Andy
PersonalAI Developer
```

---

## Template 2: Bug Report Acknowledgment

**Use when:** User reports a bug

**Template name:** `Support - Bug Report Ack`

**Body:**
```
Hi [Name],

Thanks for reporting this bug! I really appreciate you taking the time to help improve PersonalAI.

I've filed this as issue #[number] in my bug tracker and I'm investigating it now.

[If reproducible:]
I was able to reproduce this on my device and I'm working on a fix.

[If not reproducible:]
I haven't been able to reproduce this yet on my test devices. Could you provide a bit more info:
- [Specific question 1]
- [Specific question 2]

I'll keep you updated on progress, and I'll let you know when a fix is released.

Thanks again for helping make the app better!

Best,
Andy

---
Reported issue: [brief description]
GitHub: https://github.com/[username]/personal-ai-ios/issues/[number]
```

---

## Template 3: Bug Fixed Notification

**Use when:** Bug has been fixed and shipped

**Template name:** `Support - Bug Fixed`

**Body:**
```
Hi [Name],

Good news! The bug you reported has been fixed in version [X.X.X], which is now available on the App Store / TestFlight.

To update:
[App Store:] Open the App Store, go to your account, and check for updates
[TestFlight:] TestFlight should auto-update, or you can manually update from the TestFlight app

What was fixed:
[Brief description of the fix]

Thanks again for reporting this - it really helps make PersonalAI better for everyone.

If you run into any other issues, don't hesitate to reach out!

Best,
Andy
```

---

## Template 4: Feature Request Response

**Use when:** User suggests a feature

**Template name:** `Support - Feature Request`

**Body:**
```
Hi [Name],

Great suggestion! I really appreciate you sharing your ideas for PersonalAI.

I've added this to my feature request backlog. I can't promise when (or if) this will be built, but I review feature requests regularly when planning new updates.

[If high-value idea:]
This is something I've been thinking about too, and it's high on my priority list. I'll keep you posted if I start working on it.

[If maybe later:]
I can see how this would be useful. It's not in the immediate roadmap, but I'll keep it in mind for future updates.

[If probably not:]
I've thought about this carefully, and I've decided not to pursue this right now because [clear reason]. I know this might be disappointing, but I want to be upfront about what I'm prioritizing.

You can follow the public roadmap here: [link to GitHub project or ROADMAP.md]

Thanks for helping shape the future of PersonalAI!

Best,
Andy
```

---

## Template 5: How-To Answer

**Use when:** User asks how to do something

**Template name:** `Support - How To`

**Body:**
```
Hi [Name],

Great question! Here's how to do that:

[Step-by-step instructions:]
1. [Step 1]
2. [Step 2]
3. [Step 3]

[If there's a workaround:]
Note: This isn't ideal, but it's the current way to accomplish this. I'm planning to make this easier in a future update.

[If it's not possible:]
Unfortunately, this isn't currently possible in the app. However, I've noted this as a feature request and I'll consider adding it in a future update.

Let me know if you have any other questions!

Best,
Andy

P.S. I'm also adding this to the FAQ/documentation so others can find this info easily.
```

---

## Template 6: Can't Reproduce / Need More Info

**Use when:** You can't reproduce the issue

**Template name:** `Support - Need More Info`

**Body:**
```
Hi [Name],

Thanks for the report! I've tried to reproduce this issue on my test devices, but I haven't been able to yet.

Could you help me out with a few more details?

- What version of iOS are you running? (Settings → General → About → Software Version)
- What version of PersonalAI? (Settings → About in the app)
- Which device? (iPhone model)
- [Specific question about the issue]
- [Another specific question]
- Can you share a screenshot if possible?

Also, have you tried:
- [Potential fix 1, e.g., restarting the app]
- [Potential fix 2, e.g., checking permissions in Settings]

This will help me track down the issue. Thanks for your patience!

Best,
Andy
```

---

## Template 7: Permission Issue

**Use when:** Issue is due to denied permissions

**Template name:** `Support - Permissions`

**Body:**
```
Hi [Name],

It looks like this might be related to permissions. PersonalAI needs certain permissions for some features to work:

- **Location** ("When in Use") - For context gathering
- **HealthKit** - For energy tracking (sleep, activity, HRV)
- **Calendar/Reminders** - For creating events and reminders
- **Microphone** - For voice input
- **Speech Recognition** - For transcribing voice to text

The app is designed to work even without permissions (features gracefully degrade), but for the feature you're trying to use, you'll need to grant [specific permission].

To check/grant permissions:
1. Open iPhone Settings
2. Scroll to "PersonalAI"
3. Check that [specific permission] is enabled
4. Return to PersonalAI and try again

If you've already granted permission and it's still not working, let me know and I'll investigate further!

Best,
Andy
```

---

## Template 8: Sorry, Can't Help / Out of Scope

**Use when:** Request is outside the scope of support

**Template name:** `Support - Out of Scope`

**Body:**
```
Hi [Name],

Thanks for reaching out! Unfortunately, this is outside the scope of what I can help with for PersonalAI.

[If it's an iOS system issue:]
This looks like an iOS system issue rather than something specific to PersonalAI. I'd recommend:
- Checking Apple's support site: https://support.apple.com
- Contacting Apple Support directly

[If it's another app:]
This seems to be related to [other app], which I don't have control over. You might want to contact their support team.

[If it's a hardware issue:]
This sounds like a hardware issue with your device. Apple Support would be the best resource for this.

If there's anything specific to PersonalAI I can help with, please let me know!

Best,
Andy
```

---

## Template 9: Thank You (Positive Feedback)

**Use when:** User sends positive feedback or thanks

**Template name:** `Support - Thank You`

**Body:**
```
Hi [Name],

Thank you so much for the kind words! It really means a lot to hear that PersonalAI is helping you [specific benefit they mentioned].

Feedback like this is what keeps me motivated to keep improving the app. If you have any suggestions for how to make it even better, I'm all ears!

If you're enjoying the app, I'd be incredibly grateful if you could leave a review on the App Store. It helps other people discover PersonalAI:
[Link to App Store review page]

Thanks again for your support!

Best,
Andy
```

---

## Template 10: Refund Request (if applicable)

**Use when:** User requests refund (if you have paid version)

**Template name:** `Support - Refund`

**Body:**
```
Hi [Name],

I'm sorry to hear PersonalAI didn't meet your needs.

Refunds are handled directly by Apple, not by me as the developer. Here's how to request a refund:

1. Go to: https://reportaproblem.apple.com
2. Sign in with your Apple ID
3. Find PersonalAI in your purchase history
4. Click "Report a Problem"
5. Select "I'd like to request a refund"
6. Submit your request

Apple typically processes refund requests within a few days.

Before you go, I'd love to know what didn't work for you. Is there something I could improve? Your feedback helps make the app better.

Best,
Andy
```

---

## Template 11: Beta Tester Thank You

**Use when:** Thanking beta testers

**Template name:** `Support - Beta Thanks`

**Body:**
```
Hi [Name],

Thanks for beta testing PersonalAI! Your feedback has been incredibly valuable.

Version [X.X.X] is now live on the App Store with [features/fixes you helped test].

Specific changes based on your feedback:
- [Change 1]
- [Change 2]

I really appreciate you taking the time to help make PersonalAI better. If you'd like to continue beta testing future releases, you're welcome to stay on the TestFlight beta!

Best,
Andy
```

---

## Creating Your Own Templates

### Template Structure

```
Subject: [Clear, specific subject line]

Hi [Name],

[Opening - acknowledge their message]

[Main content - answer question/address issue]

[Next steps or call to action if applicable]

[Closing]

Best,
Andy
[Signature]
```

### Tips for Good Templates

1. **Personalize:** Always use [Name] placeholders and customize before sending
2. **Be clear:** Short sentences, simple language
3. **Be helpful:** Anticipate follow-up questions
4. **Be human:** Friendly, not robotic
5. **Include links:** Direct links to relevant resources
6. **Set expectations:** When will they hear back? What happens next?

---

## Support Email Signature

Add this to all your support emails:

```
Best,
Andy

---
PersonalAI - Context-aware thought capture
Support: support@yourapp.com
Roadmap: https://github.com/yourusername/personal-ai-ios
```

Or shorter:
```
Best,
Andy
PersonalAI Support
```

---

## Tracking Support Conversations

### Simple Notion Database

Create a Notion database with these fields:
- **Email:** Text (user's email)
- **Subject:** Text
- **Status:** Select (New, In Progress, Waiting, Resolved)
- **Priority:** Select (Critical, High, Medium, Low)
- **Type:** Select (Bug, Feature, Question, Billing)
- **Created:** Date
- **GitHub Issue:** URL (if linked to issue)
- **Notes:** Text

### Or Simple Spreadsheet

Google Sheets with columns:
- Email | Subject | Priority | Type | Status | Created | GitHub Link | Notes

---

## Next Steps

1. **Enable Templates in Gmail** (5 min)
2. **Create 3-5 most useful templates** (15 min)
   - General Ack
   - Bug Report Ack
   - Feature Request
   - How-To
   - Need More Info
3. **Set up tracking** (Notion or spreadsheet) (10 min)
4. **Test with a practice email to yourself** (5 min)

**Total time:** ~35 minutes

**Benefit:** Fast, consistent support responses that feel personal

---

**Remember:** Always personalize templates before sending. Add specific details about their issue, use their name, and adjust tone as needed. Templates are starting points, not copy-paste scripts.
