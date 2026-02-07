# Launch Checklist: STASH Go-to-Market

**Last Updated**: 2026-01-30
**Purpose**: Step-by-step guide to launch STASH successfully

## Launch Timeline Overview

```
T-8 weeks: Pre-Launch Preparation
T-4 weeks: Beta Testing & Marketing Setup
T-2 weeks: App Store Submission
T-1 week: Launch Prep
T-0: Launch Day
T+1 week: Post-Launch Optimization
T+1 month: Growth & Iteration
```

---

## Phase 1: Pre-Launch Preparation (T-8 to T-4 weeks)

### Product Readiness

#### Core Features ✅ (Already Complete)
- [x] Voice capture with Siri integration (#17)
- [x] AI classification (5 types: note, idea, task, event, question)
- [x] Context enrichment (location, energy, focus state)
- [x] Calendar/Reminder integration
- [x] Search functionality
- [x] Accessibility support (#19)
- [x] App Intents for Shortcuts

#### Features Needed Before Launch
- [ ] **Charts & Insights** (#18) - Premium differentiator
  - Sentiment trend line chart
  - Thought type distribution pie chart
  - Capture frequency heatmap
  - Priority: HIGH (selling point)

- [ ] **Theme System** (#10) - Polish & contrast fixes
  - Implement asset catalog colors
  - Fix 5 critical contrast issues
  - Light/dark mode refinement
  - Priority: MEDIUM (quality)

- [ ] **Subscription System** (NEW)
  - StoreKit 2 integration
  - Free tier enforcement (50 thoughts/month limit)
  - Trial management (7-day trial)
  - Paywall screens
  - Priority: CRITICAL (monetization)

- [ ] **Onboarding Flow** (NEW)
  - Welcome screens (3-4 slides)
  - Permission requests (Health, Location, Notifications)
  - Siri setup prompt
  - First thought tutorial
  - Priority: HIGH (conversion)

- [ ] **Export Functionality** (Premium feature)
  - JSON export
  - Markdown export
  - CSV export
  - Priority: MEDIUM (premium value)

---

### Legal & Compliance

#### Privacy Policy
- [ ] Draft privacy policy (TermsFeed generator or legal template)
  - Data collection disclosure (minimal: text for classification)
  - Third-party services (OpenAI API)
  - User rights (GDPR, CCPA compliance)
  - Local-first architecture emphasis
- [ ] Legal review (optional but recommended: $200-500)
- [ ] Host on website (personalai.app/privacy)
- [ ] Link in App Store listing
- [ ] Link in Settings screen

#### Terms of Service
- [ ] Draft TOS (TermsFeed generator)
  - Subscription terms (trial, cancellation, refunds)
  - Acceptable use policy
  - Liability limitations
- [ ] Host on website (personalai.app/terms)
- [ ] Link in App Store listing
- [ ] Link during onboarding

#### App Store Requirements
- [ ] Export Compliance: CCPA (if using encryption)
  - Likely: Self-classify as "No" (standard iOS encryption)
- [ ] Age rating: Determine appropriate rating (likely 4+)
- [ ] Content rights: Verify all assets owned or licensed
- [ ] Review Guidelines compliance check

---

### Marketing Assets

#### App Icon
- [ ] Finalize app icon design
  - 1024×1024 px master
  - All required sizes generated
  - Test on home screen (light/dark mode)
  - Distinctive, recognizable, professional

#### App Store Screenshots (Required: 6.7" and 5.5" iPhones)
**Set 1: iPhone 15 Pro Max (6.7")**:
1. Hero shot: Voice capture with "Hey Siri, capture a thought"
2. AI Classification: Show automatic type detection
3. Context enrichment: Location, energy, focus displayed
4. Insights: Chart showing productivity patterns
5. Search: Finding thoughts with semantic search
6. Calendar integration: One-tap task creation

**Set 2: iPhone SE (5.5")**: Resize/adapt above

- [ ] Design all 6+ screenshots with captions
- [ ] Export in required resolutions
- [ ] A/B test with beta users (which order converts best)

#### App Preview Video (Optional but Recommended)
- [ ] Script 15-30 second demo
  - Show: Voice capture → AI classification → Insights
- [ ] Screen record with voiceover or captions
- [ ] Edit with professional tool (iMovie, Final Cut, Descript)
- [ ] Export in App Store format

#### Website (Landing Page)
**Minimum Viable**:
- [ ] Domain: Register personalai.app ($12/year)
- [ ] Hero section: Tagline + App Store badge
- [ ] Features section: 3-4 key benefits
- [ ] Pricing section: Free vs. Pro comparison
- [ ] Privacy statement: "Your thoughts stay private"
- [ ] Footer: Privacy policy, TOS, Contact
- [ ] Host: Vercel, Netlify, or GitHub Pages (free)

**Tools**: Use Framer, Webflow, or hand-code with Tailwind CSS

- [ ] SEO optimization
  - Title tag: "STASH – Your thoughts, organized automatically"
  - Meta description: Benefits + CTA
  - OpenGraph tags for social sharing

#### Social Media Prep
- [ ] Create Twitter/X account (@STASH_app or similar)
- [ ] Create threads (draft 3-5):
  - Problem/solution thread
  - Behind-the-scenes build thread
  - Privacy-first positioning thread
  - Launch announcement thread
- [ ] Design social media graphics (hero image, feature highlights)
- [ ] Build small following pre-launch (engage in r/productivity, ADHD communities)

---

### Beta Testing

#### TestFlight Beta (Internal)
- [ ] Invite 10-20 friends/family
- [ ] Test core flows:
  - Onboarding
  - Capture thoughts (voice + text)
  - Classification accuracy
  - Search functionality
  - Subscription flow (Sandbox)
  - Export features
- [ ] Collect feedback on:
  - Bugs/crashes
  - Confusing UX
  - Feature requests
  - Pricing perception

#### TestFlight Beta (External - Optional)
- [ ] Recruit 50-100 beta testers
  - Post in r/ADHD, r/productivity, r/iOSBeta
  - ADHD Discord servers
  - Twitter/X community
- [ ] Send onboarding email with instructions
- [ ] Collect structured feedback (Typeform survey)
- [ ] Incentivize: Lifetime free Pro for top 50 testers

#### Beta Metrics to Track
- Crash rate (aim: <1%)
- Session length
- Thoughts captured per user
- Feature adoption (insights, export, search)
- Subscription conversion (in sandbox mode)

---

## Phase 2: App Store Submission (T-2 weeks)

### App Store Connect Setup

#### Account Setup
- [x] Apple Developer Program enrolled (waiting on approval)
- [ ] App Store Connect access confirmed
- [ ] Certificates & Provisioning Profiles updated
- [ ] Push notification certificates configured

#### App Information
- [ ] **App Name**: "STASH" (check availability)
  - Alternatives: "Personal AI", "MindAI", "ThoughtAI"
- [ ] **Subtitle** (80 chars): "Voice capture, AI classification, health context—your private thought companion"
- [ ] **Primary Category**: Productivity
- [ ] **Secondary Category**: Health & Fitness (due to Apple Health integration)

#### Keywords (100 characters max)
Optimize for search visibility:
```
thought,note,adhd,ai,voice,siri,journal,productivity,organize,idea,task,reminder,private,health,energy
```

Test with App Store optimization tools (AppTweak, Sensor Tower)

#### Description

**Short Description** (170 characters):
"Capture thoughts instantly with AI that organizes automatically. Voice-first, privacy-focused, with health insights. For ADHD, productivity enthusiasts, and everyone."

**Full Description** (4,000 characters max):
```markdown
Stop losing your best ideas to disorganization.

STASH is your intelligent thought companion. Capture ideas, tasks, and notes instantly—AI handles the rest.

🎤 VOICE-FIRST CAPTURE
"Hey Siri, capture a thought" and you're done. No app opening, no typing, no manual filing.

🤖 AUTOMATIC ORGANIZATION
AI classifies every thought:
• Notes for reference
• Ideas to explore
• Tasks to complete
• Events to schedule
• Questions to answer

No tags to add, no folders to create—it just works.

🧠 CONTEXT-AWARE
Every thought captures:
• Location: Where were you?
• Energy level: How did you feel?
• Focus state: Deep work or distracted?

Find thoughts later by when, where, and how you captured them.

📊 INSIGHTS & PATTERNS
Discover when you think best:
• Productivity trends over time
• Thought type distribution
• Energy correlation patterns
• Peak creativity hours

📅 ACTIONABLE IN ONE TAP
"Meeting Tuesday at 2pm" → Tap → Calendar event created.
"Buy milk" → Tap → Reminder set.

No context switching, no manual entry.

🔒 PRIVACY-FIRST
Your thoughts stay on your device. Local-first architecture means no cloud storage, no data mining, no privacy compromises.

We only use OpenAI's API for text classification—nothing else leaves your iPhone.

✨ BUILT FOR
• ADHD & neurodivergent users who need cognitive scaffolding
• Knowledge workers drowning in scattered notes
• Health-conscious individuals tracking mental patterns
• Anyone who thinks faster than they can organize

FREE TIER INCLUDES:
• 50 thoughts per month
• AI classification
• Voice capture with Siri
• Context enrichment
• Basic search
• Calendar/Reminder creation

PERSONALAI PRO ($39.99/year or $3.99/month):
• Unlimited thoughts
• Charts and insights
• AI auto-tagging
• Advanced semantic search
• Health correlation patterns
• Export (JSON, Markdown, CSV)
• Priority support

7-day free trial. Cancel anytime.

---

iPhone, iPad, and Mac (via Apple Silicon) supported.
Requires iOS 17.0 or later.

Privacy Policy: [URL]
Terms of Service: [URL]
Support: support@personalai.app
```

#### Screenshots & Preview
- [ ] Upload all 6+ screenshots (6.7" and 5.5")
- [ ] Add captions to screenshots (emphasize benefits)
- [ ] Upload app preview video (if created)
- [ ] Order screenshots by conversion priority (A/B test in beta)

#### Pricing & Availability
- [ ] Select all countries (or start with US, UK, Canada, Australia)
- [ ] Set pricing tier:
  - Monthly: $3.99 (Tier 4)
  - Annual: $39.99 (Tier 39)
- [ ] Enable 7-day free trial
- [ ] Allow family sharing (builds goodwill)

#### App Review Information
- [ ] Demo account (if needed for review): Not required for STASH
- [ ] Notes for reviewer:
  - Explain Siri integration requires device
  - Clarify AI classification uses OpenAI API
  - Mention Health permission is optional (for context enrichment)
- [ ] Contact info: Phone + email for urgent communication

---

### Submission

- [ ] Build release version (Archive in Xcode)
- [ ] Upload to App Store Connect (Xcode Organizer)
- [ ] Select build for release
- [ ] Submit for review
- [ ] Monitor status daily (typically 1-3 days for review)

**Common Rejection Reasons to Avoid**:
- Misleading screenshots (don't show features not implemented)
- Broken functionality (test thoroughly)
- Privacy policy missing or inadequate
- In-App Purchase not implemented correctly
- Health claims not substantiated (avoid making medical claims)

---

## Phase 3: Launch Week (T-1 week to T-0)

### Pre-Launch Marketing (T-1 week)

#### Content Creation
- [ ] Write launch announcement blog post
  - Why I built STASH (founder story)
  - Problem/solution narrative
  - Key features + screenshots
  - Launch date + CTA
- [ ] Record demo video (2-3 minutes)
  - Loom or screen recording
  - Show voice capture → classification → insights
  - Upload to YouTube
- [ ] Draft social media posts (schedule in advance)

#### Community Seeding
- [ ] Post in relevant subreddits:
  - r/ADHD: "I built an app that auto-organizes your thoughts (ADHD-friendly)"
  - r/productivity: "Show HN: AI-powered thought companion"
  - r/apple: "New iOS app with deep Siri integration"
  - r/ios: "Just launched: Private, local-first AI notes app"
- [ ] ADHD Discord/forums: Introduce app, ask for feedback
- [ ] Indie Hackers: Share founder story + metrics

#### Product Hunt Prep
- [ ] Create Product Hunt account (if none)
- [ ] Prepare Product Hunt post:
  - Tagline: "Your thoughts, organized automatically"
  - First comment: Founder intro, why I built this, key features
  - Gallery: 4-5 best screenshots + demo video
  - Topics: Productivity, AI, iOS, Health, Privacy
- [ ] Recruit "Hunter" (someone with PH following) or self-post
- [ ] Schedule for Tuesday-Thursday (best traffic days)

#### Email List (if exists)
- [ ] Send "We're launching!" email
  - Link to App Store (once live)
  - Limited-time launch discount (optional)
  - Ask for reviews

#### Press Outreach (Optional)
- [ ] Pitch to:
  - MacStories (Federico Viticci): iOS productivity focus
  - 9to5Mac: Apple ecosystem news
  - The Verge: Tech news
  - TechCrunch: Startups (unlikely without funding)
- [ ] Angle: "Privacy-first AI note-taking for ADHD users"

---

### Launch Day (T-0)

#### Morning (App Goes Live)
- [ ] Verify app is live on App Store
- [ ] Test download and installation
- [ ] Test In-App Purchase flow (real money)
- [ ] Monitor crash reports (Xcode Organizer, Sentry)

#### Product Hunt Launch
- [ ] Post on Product Hunt at 12:01 AM PT (PST)
- [ ] Engage with every comment (first 3-4 hours critical)
- [ ] Upvote other products (build karma)
- [ ] Share PH link on Twitter, LinkedIn, Facebook

#### Social Media Blitz
- [ ] Post launch thread on Twitter/X
  - Problem/solution
  - Key features (with GIFs/screenshots)
  - App Store link
  - Ask for retweets
- [ ] Post on LinkedIn (professional audience)
- [ ] Post in relevant Facebook groups
- [ ] Instagram story (if visually compelling)

#### Reddit Launch Posts
- [ ] r/ADHD: Personal story angle, ask for feedback
- [ ] r/productivity: "Show r/productivity: AI thought organizer"
- [ ] r/SideProject: Founder journey
- [ ] r/apple: "Just launched iOS app with Siri integration"

**Timing**: Stagger posts (don't spam all at once)
**Tone**: Authentic, helpful, not salesy

#### Community Engagement
- [ ] Monitor all channels for comments/questions
- [ ] Respond within 1 hour (shows you care)
- [ ] Thank everyone who tries the app
- [ ] Ask for App Store reviews (nicely)

---

### Week 1 Post-Launch (T+1 to T+7 days)

#### Monitoring & Support
- [ ] Check App Store reviews daily (respond to all)
- [ ] Monitor crash reports (fix critical bugs ASAP)
- [ ] Track analytics:
  - Downloads per day
  - Trial starts
  - Conversion rate
  - Retention (D1, D3, D7)
- [ ] Support inbox: Respond within 24 hours

#### Content Marketing
- [ ] Publish "Week 1 Lessons" blog post
  - Metrics (if good): "We got X users in week 1"
  - Feedback summary
  - Roadmap preview
- [ ] Share user testimonials (ask for permission)
- [ ] Create "How to use STASH" video tutorials

#### Optimization
- [ ] A/B test onboarding flow (if needed)
- [ ] Fix top 3 user-reported issues
- [ ] Improve upgrade prompts based on conversion data
- [ ] Adjust free tier limit if conversion is low

#### Outreach
- [ ] Email beta testers: "We launched! Thank you for your help"
- [ ] Ask satisfied users for App Store reviews
- [ ] Reach out to ADHD influencers (offer free lifetime Pro)
- [ ] Post update in launch channels (Reddit, PH, Twitter)

---

## Phase 4: Month 1 Growth (T+1 month)

### Feature Iteration
- [ ] Ship 1-2 most-requested features
- [ ] Fix all critical bugs
- [ ] Improve onboarding based on drop-off data
- [ ] Add more chart types (if insights are popular)

### Content Strategy
- [ ] Blog posts (2-4 per month):
  - "The Hidden Cost of Manual Organization"
  - "Privacy in the Age of AI"
  - "How Energy Levels Affect Productivity"
  - "ADHD-Friendly Productivity Systems"
- [ ] SEO optimization for "Apple Notes alternative", "ADHD note app"
- [ ] Guest posts on productivity blogs

### Community Building
- [ ] Create Discord server (if user base >500)
- [ ] Start email newsletter (weekly tips, feature updates)
- [ ] Engage with users on Twitter (retweet their posts)
- [ ] Run "Feature Friday" polls (what to build next)

### Growth Experiments
- [ ] Apple Search Ads ($100-200 test budget)
- [ ] Reddit ads in r/ADHD ($50-100 test)
- [ ] Referral program (give 1 month free, get 1 month free)
- [ ] Influencer partnerships (ADHD coaches, productivity YouTubers)

### Metrics to Hit (Month 1)
- [ ] 1,000+ downloads
- [ ] 100-200 paid subscribers
- [ ] <5% crash rate
- [ ] 4.5+ star rating on App Store
- [ ] 30%+ D7 retention

---

## Critical Success Factors

### Must-Haves Before Launch
1. ✅ Core features complete and bug-free
2. ⏳ Subscription system working (StoreKit 2)
3. ⏳ Onboarding flow polished
4. ⏳ Charts & insights implemented
5. ⏳ Privacy policy and TOS published
6. ⏳ App Store listing optimized

### Launch Day Priorities
1. Product Hunt top 5 (drives significant traffic)
2. Respond to every comment/question (builds trust)
3. Monitor for crashes (fix immediately)
4. Engage authentically (don't be salesy)

### Week 1 Priorities
1. Fix critical bugs reported by users
2. Respond to all App Store reviews
3. Collect feedback for next iteration
4. Thank early adopters publicly

### Month 1 Priorities
1. Hit 100-200 paid users (validates business model)
2. Maintain 4.5+ star rating (social proof)
3. Ship 1-2 most-requested features (show momentum)
4. Build email list for future launches

---

## Launch Day Checklist (Final 24 Hours)

### T-24 Hours
- [ ] App is approved and live on App Store
- [ ] All marketing materials ready (blog post, tweets, PH post)
- [ ] Support email set up (support@personalai.app)
- [ ] Analytics dashboards ready (Mixpanel, App Store Connect)
- [ ] Demo video published on YouTube

### T-12 Hours
- [ ] Schedule Product Hunt post for 12:01 AM PT
- [ ] Schedule social media posts (Buffer, Typefully)
- [ ] Notify friends/family to support launch
- [ ] Final test: Download app from App Store

### T-1 Hour
- [ ] Product Hunt post goes live
- [ ] Tweet launch thread
- [ ] Post in r/ADHD, r/productivity (stagger timing)
- [ ] Email beta testers

### Launch Day
- [ ] Monitor Product Hunt (engage with comments)
- [ ] Monitor social media mentions (respond quickly)
- [ ] Check App Store reviews (respond professionally)
- [ ] Track analytics (downloads, trial starts, crashes)
- [ ] Celebrate! 🎉 You launched a product.

### T+1 Day
- [ ] Post "Launch Day Recap" update
  - Metrics (if good): "We got X downloads in 24 hours!"
  - Thank everyone who supported
  - Preview what's coming next
- [ ] Fix any critical bugs reported
- [ ] Start planning Week 2 content

---

## Post-Launch Maintenance Checklist

### Daily (First Week)
- [ ] Check App Store reviews (respond within 24 hours)
- [ ] Monitor crash reports (fix critical bugs immediately)
- [ ] Check analytics (downloads, trials, conversions)
- [ ] Respond to support emails (within 12 hours)
- [ ] Engage on social media (Twitter, Reddit)

### Weekly (First Month)
- [ ] Publish blog post or tutorial
- [ ] Send newsletter to email list
- [ ] Review analytics (conversion funnel, retention, churn)
- [ ] Ship bug fixes or small improvements
- [ ] Plan next feature based on feedback

### Monthly (First Year)
- [ ] Review financial metrics (MRR, costs, profit)
- [ ] Analyze user feedback themes
- [ ] Plan next major feature
- [ ] Refresh marketing materials
- [ ] Outreach to press or influencers

---

## Backup Plans

### If App Store Rejects
- Review rejection reason carefully
- Fix issue or appeal (if unjust)
- Resubmit within 24-48 hours
- Communicate delay to community

### If Launch Flops (< 50 downloads Day 1)
- Don't panic—organic launches can be slow
- Double down on community engagement (Reddit, Discord)
- Offer free Pro to first 100 users (creates urgency)
- Reach out directly to ADHD communities for feedback

### If Conversion is Low (< 5%)
- Survey users: "Why didn't you upgrade?"
- Improve onboarding (show value faster)
- Lower free tier limit (30 thoughts instead of 50)
- Offer 1-month trial instead of 7-day

### If Churn is High (> 10%/month)
- Exit surveys: "Why are you canceling?"
- Improve engagement (push notifications, weekly emails)
- Add retention features (streaks, milestones)
- Offer win-back discount (50% off for 3 months)

---

## Resources & Tools

### Development
- Xcode (App Store submission)
- TestFlight (Beta testing)
- Sentry (Crash reporting)
- Mixpanel (Analytics)

### Marketing
- Figma/Canva (Design assets)
- Loom (Demo videos)
- Buffer/Typefully (Social media scheduling)
- Product Hunt (Launch platform)

### Legal
- TermsFeed (Privacy policy generator)
- Stripe Atlas (Optional: Incorporate if serious)

### Community
- Reddit (r/ADHD, r/productivity, r/SideProject)
- Twitter/X (Tech community)
- Indie Hackers (Founder community)
- Discord (User community building)

---

## Success Criteria

### Week 1
- ✅ 500+ downloads
- ✅ 50+ trial starts
- ✅ 5+ paid conversions
- ✅ 4.5+ star rating
- ✅ <1% crash rate

### Month 1
- ✅ 2,000+ downloads
- ✅ 200+ trial starts
- ✅ 100-200 paid users
- ✅ $400-800 MRR
- ✅ 30%+ D7 retention

### Month 3
- ✅ 5,000+ downloads
- ✅ 500+ paid users
- ✅ $2,000+ MRR
- ✅ Break-even on costs
- ✅ 4.6+ star rating

### Month 6
- ✅ 10,000+ downloads
- ✅ 1,000+ paid users
- ✅ $4,000+ MRR
- ✅ Profitable operation
- ✅ Featured in productivity blogs

---

## Final Thoughts

**Remember**:
- Launch is just the beginning, not the end
- Engage authentically, not transactionally
- Listen to users, iterate quickly
- Focus on one metric: paid subscribers
- Celebrate small wins along the way

**You've got this.** 🚀

---

## Quick Reference: Week Before Launch

```
7 days out: Finish charts, theme system, subscription integration
6 days out: Internal testing complete, all features working
5 days out: Submit to App Store for review
4 days out: Finalize marketing materials (blog, tweets, PH post)
3 days out: App approved (hopefully), test real download
2 days out: Schedule Product Hunt post, social media posts
1 day out: Notify friends/family, set up monitoring dashboards
Launch day: Product Hunt at midnight, engage all day
Day 2: Post recap, fix bugs, plan week 2 content
```

Good luck with the launch! 🎉
