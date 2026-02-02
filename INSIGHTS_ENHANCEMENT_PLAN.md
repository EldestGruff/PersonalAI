# Insights Screen Enhancement Plan
**Connecting Smart Resurfacing to AI Insights**

## 🎯 Goal
Transform the Insights screen into an AI-powered "therapist" that understands your thought patterns and asks probing questions.

---

## 💡 New Insights Types

### 1. **Recurring Themes Insight**
**What it shows:**
```
📊 You've thought a lot about exercise lately

7 thoughts over the last 14 days
Most recent: "Need to start working out" (2 days ago)

💬 "You seem focused on getting back to exercise.
    Want to create a plan?"

[Create Workout Plan] [View All 7 Thoughts]
```

**Implementation:**
- Use `SmartInsightsService.detectPatterns()`
- Show top 3 patterns
- Add conversational prompt
- Action buttons (create task, view pattern)

---

### 2. **Health Focus Insight**
**What it shows:**
```
🏥 You seem to be thinking about your health a lot

12 thoughts about health this month
Tags: exercise (7), diet (3), sleep (2)

💬 "Health is clearly on your mind. Do you want to
    dive deeper into tracking wellness?"

[Set Health Goals] [Track Progress]
```

**Implementation:**
- Detect health-related tags/content
- Count frequency
- Suggest deeper tracking (medication module, etc.)

---

### 3. **Unresolved Questions**
**What it shows:**
```
❓ You have 5 unresolved questions

"What's the best productivity system?" (5 days ago)
"How do I learn SwiftUI?" (12 days ago)
"Should I switch jobs?" (3 weeks ago)

💬 "These questions are still on your mind. Let's
    find answers or make decisions."

[Research] [Ask Someone] [Make Decision]
```

**Implementation:**
- Use `SmartInsightsService.findUnresolvedThoughts()`
- Filter for questions (contains "?")
- Show oldest first
- Action suggestions

---

### 4. **Repetitive Ideas (Never Acted On)**
**What it shows:**
```
💡 You keep thinking about starting a side project

Mentioned 9 times over 2 months
Never created a task or plan

💬 "This idea keeps coming back. It might be worth
    taking seriously. Should we break it down?"

[Create Project Plan] [Set Milestone] [Archive Idea]
```

**Implementation:**
- Find patterns with no related tasks
- High frequency + long timespan
- Conversational nudge
- Action-oriented buttons

---

### 5. **Mood Patterns**
**What it shows:**
```
😟 Your thoughts seem more stressed lately

Sentiment trending downward this week
Average: -0.3 (was 0.1 last week)

💬 "Your thoughts show increased stress. Want to
    explore what's causing it?"

[View Stress Triggers] [Mood Journal]
```

**Implementation:**
- Analyze sentiment trends from charts
- Compare week-over-week
- Gentle, supportive tone
- Mental health resources

---

### 6. **Connected Ideas**
**What it shows:**
```
🔗 These thoughts seem connected

"Project deadline approaching"
"Feeling overwhelmed"
"Need better time management"

💬 "These thoughts are all related to work pressure.
    Let's tackle the root cause."

[Link Thoughts] [Create Action Plan]
```

**Implementation:**
- Find high-similarity clusters
- Show 3-5 related thoughts
- Suggest connections user might miss
- Offer to link them

---

## 🎨 UI Design

### **Insight Card Template**
```swift
VStack(alignment: .leading, spacing: 12) {
    // Header with icon
    HStack {
        Image(systemName: icon)
            .foregroundColor(color)
        Text(title)
            .font(.headline)
    }

    // Data summary
    Text(summary)
        .font(.subheadline)
        .foregroundColor(.secondary)

    // AI Message (conversational)
    HStack(alignment: .top, spacing: 8) {
        Image(systemName: "brain")
            .foregroundColor(.blue)
        Text(aiMessage)
            .font(.callout)
            .italic()
    }
    .padding(10)
    .background(Color.blue.opacity(0.05))
    .cornerRadius(8)

    // Action buttons
    HStack {
        ForEach(actions) { action in
            Button(action.label) {
                action.handler()
            }
            .buttonStyle(.bordered)
        }
    }
}
.padding()
.background(Color.gray.opacity(0.05))
.cornerRadius(12)
```

---

## 📱 Insights Screen Layout

```
┌─────────────────────────────────────────┐
│ Insights                        [Filter] │
├─────────────────────────────────────────┤
│                                         │
│ 📊 Charts Summary                       │
│ [Existing charts section]               │
│                                         │
├─────────────────────────────────────────┤
│ 💡 AI Insights                          │
│                                         │
│ ┌─────────────────────────────────┐   │
│ │ 📊 You've thought a lot about   │   │
│ │    exercise lately               │   │
│ │                                  │   │
│ │ 7 thoughts • 14 days             │   │
│ │                                  │   │
│ │ 💬 "You seem focused on getting  │   │
│ │    back to exercise. Want to    │   │
│ │    create a plan?"              │   │
│ │                                  │   │
│ │ [Create Plan] [View All]         │   │
│ └─────────────────────────────────┘   │
│                                         │
│ ┌─────────────────────────────────┐   │
│ │ ❓ You have 5 unresolved         │   │
│ │    questions                     │   │
│ │                                  │   │
│ │ "What's the best productivity   │   │
│ │  system?" (5 days ago)          │   │
│ │                                  │   │
│ │ 💬 "Let's find answers or make  │   │
│ │    decisions."                  │   │
│ │                                  │   │
│ │ [Research] [Decide]              │   │
│ └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🛠️ Implementation Steps

### **Step 1: Create AIInsight Model**
```swift
struct AIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let summary: String
    let aiMessage: String
    let actions: [InsightAction]
    let priority: Int // 1-10, higher = more important
}

enum InsightType {
    case recurringTheme
    case unresolvedQuestions
    case healthFocus
    case repetitiveIdea
    case moodPattern
    case connectedIdeas
}

struct InsightAction: Identifiable {
    let id = UUID()
    let label: String
    let handler: () -> Void
}
```

### **Step 2: Extend SmartInsightsService**
```swift
extension SmartInsightsService {
    /// Generate AI-powered insights for the Insights screen
    func generateAIInsights(from thoughts: [Thought]) async -> [AIInsight] {
        var insights: [AIInsight] = []

        // Detect patterns and convert to insights
        let patterns = await detectPatterns(in: thoughts)
        for pattern in patterns.prefix(3) {
            insights.append(createRecurringThemeInsight(pattern))
        }

        // Find unresolved questions
        let unresolved = findUnresolvedThoughts(in: thoughts)
        if unresolved.count >= 3 {
            insights.append(createUnresolvedQuestionsInsight(unresolved))
        }

        // Detect health focus
        if hasHealthFocus(in: patterns) {
            insights.append(createHealthFocusInsight(patterns))
        }

        // Sort by priority
        return insights.sorted { $0.priority > $1.priority }
    }
}
```

### **Step 3: Update InsightsViewModel**
```swift
@Observable
final class InsightsViewModel {
    // Existing chart data
    var chartData: [ChartDataPoint] = []

    // NEW: AI insights
    var aiInsights: [AIInsight] = []
    var isLoadingInsights: Bool = false

    func loadAIInsights() async {
        isLoadingInsights = true

        let thoughts = await fetchAllThoughts()
        aiInsights = await SmartInsightsService.shared
            .generateAIInsights(from: thoughts)

        isLoadingInsights = false
    }
}
```

### **Step 4: Update InsightsScreen**
```swift
// Add AI Insights section after charts
if !viewModel.aiInsights.isEmpty {
    aiInsightsSection
}

private var aiInsightsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("💡 AI Insights")
            .font(.title2)
            .fontWeight(.bold)

        ForEach(viewModel.aiInsights) { insight in
            AIInsightCard(insight: insight)
        }
    }
}
```

---

## 🎯 Conversational Tone Examples

### **Supportive**
- "You've been thinking about this a lot. It clearly matters to you."
- "This pattern suggests something important is on your mind."
- "Let's explore this together."

### **Proactive**
- "You keep coming back to this idea. Maybe it's time to act?"
- "This question has been unanswered for 2 weeks. Want help finding clarity?"
- "You've thought about X 7 times. Should we make it a priority?"

### **Non-judgmental**
- "Your thoughts show you're processing something challenging."
- "It's okay to think about this repeatedly. Let's see if there's a pattern."
- "No pressure, but this might be worth exploring deeper."

### **Empowering**
- "You have the insights. Let's turn them into action."
- "Your patterns reveal what matters most to you."
- "You're already thinking deeply. Let's capture that energy."

---

## 📊 Priority Algorithm

```swift
func calculateInsightPriority(insight: AIInsight) -> Int {
    var priority = 5 // Base priority

    // Boost for frequency
    if insight.frequency > 10 { priority += 2 }

    // Boost for recency
    if insight.daysSinceFirst < 7 { priority += 2 }

    // Boost for health/wellbeing
    if insight.type == .healthFocus { priority += 1 }

    // Boost for unanswered questions
    if insight.type == .unresolvedQuestions { priority += 1 }

    return priority
}
```

---

## 🚀 Rollout Plan

### **Phase 2A: Basic Insights (1 week)**
- Recurring themes insight
- Unresolved questions insight
- AI Insights section in InsightsScreen

### **Phase 2B: Advanced Insights (1 week)**
- Health focus insight
- Repetitive ideas insight
- Mood patterns insight

### **Phase 2C: Polish (3 days)**
- Conversational tone refinement
- Action button implementations
- Empty states and loading states

---

## 💬 User Experience Flow

### **Example: Exercise Pattern**

**Day 1:** User captures "Need to exercise more"
→ No insight yet (need pattern)

**Day 5:** User captures "Should join a gym"
→ No insight yet (only 2 thoughts)

**Day 10:** User captures "Thinking about workout routine"
→ Pattern detected! 3+ thoughts about exercise

**Next time user opens Insights:**
```
📊 You've thought a lot about exercise lately

3 thoughts over 9 days

💬 "Exercise keeps coming up in your thoughts.
    You seem ready to make a change. Want to
    create a plan?"

[Create Workout Plan] [View All 3 Thoughts]
```

**User taps "Create Workout Plan":**
→ Opens CaptureScreen with template:
"Weekly workout schedule: [fill in details]"
Classification: task
Tags: exercise, health

---

## 🎁 Value Proposition

### **Before (Current State):**
- Charts show data
- User interprets patterns themselves
- No actionable guidance

### **After (With AI Insights):**
- App understands patterns
- Conversational guidance
- Actionable suggestions
- Feels like having a therapist/coach

**Key Insight:** Your app becomes less of a "notes graveyard" and more of an **AI thinking partner** that helps you understand yourself better.

---

## 🔧 Technical Notes

- All processing happens on-device
- No data sent to servers
- Uses existing SmartInsightsService
- Minimal new code (<500 lines)
- ~1 week implementation

---

**Ready to implement when you are!** 🚀

This will transform the Insights screen from "here's your data" to "here's what it means and what you should do about it."
