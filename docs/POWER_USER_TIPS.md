# STASH Power User Tips

**Master STASH like a pro.** These tips unlock maximum productivity and ease of use — the iOS equivalent of keyboard shortcuts and Option-key tricks on macOS.

---

## Quick Capture Methods

### 1. Voice Capture via Siri (No App Launch)

**Primary method:** Say "Hey Siri, stash a thought in STASH"

**What happens:**
- Siri asks: "What's on your mind?"
- You speak your thought
- Siri transcribes and saves it
- Zero friction — works from lock screen, no app launch required

**Alternative phrases:**
- "Quick thought in STASH"
- "Save a note in STASH"
- "Remember something in STASH"

**Pro tip:** After using it a few times, create a custom Siri shortcut:
1. Open **Shortcuts app**
2. Find "Stash Thought" under STASH
3. Tap (•••) → **Add to Siri**
4. Record a shorter custom phrase like "stash it" or "quick stash"
5. Now your custom phrase works without saying the app name

### 2. Back Tap for Voice Capture (One Physical Gesture)

**Setup once, use forever:**

1. Open **Settings** → **Accessibility** → **Touch** → **Back Tap**
2. Choose **Double Tap** or **Triple Tap** (or both!)
3. Scroll to **Shortcuts** section
4. Select **Voice Capture** (under STASH)

**What happens:**
- Double/triple tap the back of your phone
- STASH opens directly to voice capture screen
- Starts listening immediately
- Real-time transcription displayed
- Auto-saves after 3 seconds of silence (or tap "Done")

**Pro tip:** Use Double Tap for quick captures, Triple Tap for screenshots (or vice versa based on your preference)

### 3. Control Center Widget (Coming Soon)

Quick capture button in Control Center for one-tap access.

### 4. Action Button (iPhone 15 Pro/16 Pro)

**Setup:**
1. **Settings** → **Action Button**
2. Choose **Shortcut**
3. Select "Voice Capture" (STASH)

Now press and hold the Action Button to start voice capture.

---

## Siri Shortcuts & Automation

### Create Custom Workflows

The Shortcuts app lets you build powerful automations:

**Example 1: Morning Journal Prompt**
1. Open **Shortcuts app**
2. Create new shortcut
3. Add "Show Notification" → "Time for your morning reflection"
4. Add "Run Shortcut" → "Stash Thought" (STASH)
5. Set time-based automation for 8:00 AM daily

**Example 2: Location-Based Capture**
- Trigger "Stash Thought" when you arrive at work
- Auto-tag with location context

**Example 3: NFC Tag Quick Capture**
- Place NFC tag on desk
- Tap phone to tag → instantly opens voice capture
- Perfect for ADHD "external brain" workflows

### Combine with Other Apps

**Share to STASH from any app:**
1. Open **Shortcuts app**
2. Create shortcut with "Receive text from Share Sheet"
3. Add "Run Shortcut" → "Stash Thought"
4. Now "Share" from Safari/Notes/Mail → "Stash Thought" saves it

---

## Accessibility Features for Productivity

### Voice Control (Hands-Free Everything)

**Setup:** Settings → Accessibility → Voice Control

**Commands:**
- "Open STASH"
- "Tap Capture" (to open capture screen)
- "Tap Done" (to save)

Perfect for multitasking or hands-busy situations.

### AssistiveTouch (One-Tap Custom Gestures)

**Setup:** Settings → Accessibility → Touch → AssistiveTouch

**Create custom menu:**
- Add "Open STASH"
- Add "Voice Capture" shortcut
- Now the floating AssistiveTouch button has quick STASH access

### Sound Recognition (Coming Soon)

Trigger capture when specific sounds are detected (e.g., baby crying, doorbell).

---

## Context & Smart Features

### Automatic Context Enrichment

Every thought you capture includes:
- **Location** (if enabled)
- **Time of day** (morning, afternoon, evening, night)
- **Calendar events** (what's on your schedule)
- **Activity** (walking, driving, stationary)
- **Weather** (temperature, conditions)

**Pro tip:** Grant location and calendar permissions during onboarding for richer context without manual tagging.

### Auto-Classification

STASH uses on-device AI to automatically detect:
- Notes vs. reminders vs. events vs. tasks
- Sentiment (positive, negative, neutral)
- Suggested tags
- Date/time parsing ("remind me tomorrow at 3pm")

**Pro tip:** Let auto-classification run in the background. Review and adjust in the Browse screen if needed.

---

## Search & Retrieval

### Natural Language Search

**Via Siri:**
- "Hey Siri, search my thoughts for project ideas in STASH"
- "What did I think about vacation in STASH?"

**In-app:**
- Semantic search finds related thoughts even without exact keyword matches
- Search by tag, type, date range, or content

**Pro tip:** Use tags like `#important` or `#follow-up` for instant filtering.

### Spotlight Integration (Coming Soon)

Search STASH thoughts directly from iOS Spotlight (swipe down on home screen).

---

## Focus & Context Modes

### Focus Filters (iOS 16+)

**Setup:**
1. **Settings** → **Focus** → (Work/Personal/etc.)
2. **Choose Apps and People** → Add STASH
3. STASH will show work-related thoughts during Work focus, personal thoughts during Personal focus

**Pro tip:** Create a "Deep Work" focus that silences everything except STASH capture.

### Time-Based Resurfacing

STASH automatically resurfaces thoughts based on:
- **Time of day:** Morning journal entries appear in mornings
- **Location:** Work thoughts appear at work
- **Calendar context:** Meeting notes appear before similar meetings

**Pro tip:** Review the "Insights" tab daily for AI-suggested resurfaces.

---

## Keyboard Shortcuts (iPad/Mac Catalyst - Future)

When STASH launches on iPad/Mac:

- `⌘N` — New thought
- `⌘F` — Search
- `⌘,` — Settings
- `⌘⇧V` — Voice capture
- `⌘1/2/3/4` — Switch tabs (Browse/Capture/Search/Insights)

---

## Advanced Tips

### Use App Intents with Third-Party Automation

**Scriptable (iOS automation app):**
```javascript
let intent = new Intent("com.withershins.stash.CaptureThought");
intent.content = "Automated thought from Scriptable";
await intent.run();
```

**Toolbox Pro:**
- Build custom STASH integrations
- Auto-capture from RSS feeds, web scraping, etc.

### iCloud Sync & Multi-Device (Coming Soon)

Thoughts sync across iPhone, iPad, Mac via iCloud.

**Pro tip:** Capture on Apple Watch (quick voice note), review on iPad.

### Export & Backup

**Current:** Manual export via Settings → Export Data

**Future:** Automatic daily backups to iCloud Drive or Files app.

---

## Troubleshooting Common Issues

### "Something went wrong" when enabling Siri shortcut

**Solutions:**
1. Launch STASH at least once after install
2. Wait 2-3 minutes for iOS to index shortcuts
3. Restart device
4. Settings → Siri & Search → STASH → ensure "Use with Siri" is enabled

### Back Tap not working

**Check:**
1. Settings → Accessibility → Touch → Back Tap → verify shortcut is assigned
2. Remove phone case (thick cases can interfere)
3. Tap firmly but not too hard
4. Try different tap rhythm

### Voice capture permission denied

**Fix:**
1. Settings → Privacy & Security → Microphone → enable for STASH
2. Settings → Privacy & Security → Speech Recognition → enable for STASH

### Thoughts not syncing (Future iCloud feature)

**Check:**
1. Settings → [Your Name] → iCloud → ensure iCloud is enabled
2. Settings → STASH → iCloud Sync → verify enabled
3. Check network connection

---

## Hidden Gems

### Squirrel-sona Personalization (Coming Soon)

Customize STASH's personality:
- Change squirrel avatar appearance
- Adjust message tone (chatty, minimal, encouraging)
- Set theme (Arcade, Dark Mode, Minimalist, Watership Down)

### Dark Mode & Theming

**Current themes:**
- **Arcade:** Retro pixel art, vibrant colors
- **Dark Mode:** OLED-friendly, deep blacks
- **Minimalist:** Clean, distraction-free
- **Watership Down:** Nature-inspired, parchment textures

**Pro tip:** Theme auto-switches with system appearance unless you set a manual preference.

### Streak Tracking

**View your capture streak:**
- Insights tab → Streak Visualization
- Goal: Daily capture habit

**Pro tip:** Set a daily reminder (Shortcuts automation) to maintain your streak.

---

## Recommended Workflows

### ADHD-Optimized "External Brain"

1. **Back Tap** for instant capture when thought strikes
2. **Morning review:** Browse → "Today" filter
3. **Weekly insights:** AI-generated patterns and suggestions
4. **Task extraction:** Thoughts auto-convert to reminders/tasks

### Meeting Notes Workflow

1. Before meeting: "Hey Siri, stash a thought about [meeting topic] in STASH"
2. During meeting: Back Tap to capture key points
3. After meeting: Review → Extract tasks → Add to calendar

### Journaling Workflow

1. Morning: "Stash a thought in STASH" → voice journal entry
2. Evening: Sentiment analysis shows mood trends
3. Weekly: Insights tab shows patterns

---

## Stay Updated

**Check for updates:** Settings → About STASH → Version

**Feature requests:** [GitHub Issues](https://github.com/EldestGruff/PersonalAI/issues)

**Community tips:** Share your workflows and discover new tricks

---

**Master STASH, master your thoughts.** 🧠✨
