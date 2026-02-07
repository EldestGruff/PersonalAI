# STASH Development Roadmap

**Last Updated:** 2026-01-20

## Executive Summary

STASH is a thought-capture and context-aware system currently in Phase 3A development. This roadmap outlines the strategic direction for future development, backend infrastructure, and sustainable maintenance.

---

## Current State (Phase 3A Complete)

### ✅ Working Features
- Thought capture (voice/text input)
- AI classification (task/note/idea/reminder/event)
- Sentiment analysis
- Multi-source context gathering:
  - Location (reverse geocoding, manual refresh, 10m precision)
  - HealthKit (sleep, activity/steps, HRV)
  - Calendar availability
  - Time of day tracking
  - Energy calculation (4-component: sleep 40%, activity 25%, HRV 20%, time 15%)
- Task/Reminder/Event creation from classified thoughts
- Full CRUD operations on thoughts
- Tag management
- User feedback system for classification fine-tuning
- Energy breakdown debug view with raw HealthKit values

### 🏗️ Technical Foundation
- Core Data persistence layer
- All iOS framework integrations (CoreLocation, HealthKit, EventKit)
- Permission handling with fail-soft patterns
- Context service with parallel data gathering (<300ms target)
- Complete UI: thought list, detail view, capture screen

---

## Phase 4: Intelligence & Automation (Next)

### Goals
- Enhance AI capabilities with learned patterns
- Improve context awareness and prediction
- Reduce manual intervention through smart automation

### Features
1. **Smart Date/Time Extraction**
   - Natural language parsing ("Thursday at 2pm", "next week")
   - Event duration intelligence
   - Reminder due date extraction
   - Calendar conflict detection

2. **Pattern Learning**
   - Learn from user feedback corrections
   - Improve classification accuracy over time
   - Personalized context patterns
   - Smart default suggestions based on history

3. **Proactive Assistance**
   - Context-based thought prompting
   - Energy-aware task scheduling suggestions
   - Location-triggered reminders

---

## Phase 5: Backend Infrastructure (Critical)

### Goals
- Establish sustainable backend for app maintenance
- Enable data sync across devices
- Support advanced AI features requiring server-side processing

### Architecture Options

#### Option A: Serverless (Firebase/Supabase)
**Pros:**
- Quick to implement
- Low maintenance overhead
- Built-in auth, storage, sync
- Pay-as-you-grow pricing

**Cons:**
- Vendor lock-in
- Limited control over AI/ML pipeline
- Potential cost scaling issues

#### Option B: Custom Backend (Node.js/Python)
**Pros:**
- Full control over AI pipeline
- Flexible model deployment
- Custom fine-tuning infrastructure
- Better data privacy controls

**Cons:**
- Higher development overhead
- Infrastructure management
- Scaling complexity

#### Option C: Hybrid Approach (Recommended)
**Stack:**
- Supabase for: Auth, data sync, file storage
- Custom service for: AI classification, model fine-tuning
- CloudKit for: iOS-specific features, privacy-first sync

**Benefits:**
- Balance of speed and control
- Serverless for commodity features
- Custom logic where it matters
- Apple ecosystem integration

### Required Backend Services
1. **User Management**
   - Authentication & authorization
   - User profiles and preferences
   - Subscription/licensing (if applicable)

2. **Data Sync**
   - Thought synchronization across devices
   - Conflict resolution
   - Offline-first with eventual consistency

3. **AI/ML Pipeline**
   - Classification service (scalable)
   - Model fine-tuning from user feedback
   - A/B testing for model improvements
   - Versioned model deployments

4. **Context Services**
   - Weather integration
   - Advanced location services (POI, semantic locations)
   - Third-party integrations (email, calendar, etc.)

5. **Analytics & Monitoring**
   - App performance metrics
   - Feature usage tracking
   - Error reporting and crash analytics
   - Model performance monitoring

---

## Phase 6: Expansion Features

### Social & Collaboration
- Shared thoughts/notes with contacts
- Team workspaces
- Collaborative context (shared calendars, locations)

### Advanced Intelligence
- Long-term memory and recall
- Multi-modal input (photos, voice notes, drawings)
- Conversation-based interaction
- Predictive thought capture

### Integrations
- Third-party app integrations (Notion, Todoist, etc.)
- Email integration (create thoughts from emails)
- Siri shortcuts and automation
- Watch app for quick capture

---

## Release Strategy

### Beta Testing (Phase 4)
- TestFlight distribution to 50-100 users
- Focus on AI accuracy and context gathering
- Gather feedback on core value proposition

### v1.0 Launch (Phase 5)
- Backend infrastructure operational
- Core features polished and stable
- App Store submission
- Marketing and user acquisition

### v1.x Iterations (Phase 6)
- Feature releases based on user feedback
- Continuous model improvements
- Platform expansion (iPad, Watch, Mac)

---

## Success Metrics

### Technical
- Classification accuracy >90%
- Context gathering <300ms
- App launch time <2s
- Crash-free rate >99.5%

### Product
- Daily active users (DAU)
- Thought capture frequency
- Feature adoption rates
- User retention (Day 7, Day 30)

### Business
- User acquisition cost (CAC)
- Lifetime value (LTV)
- Conversion rate (free to paid, if applicable)
- Monthly recurring revenue (MRR)

---

## Timeline Considerations

**Note:** Timeline estimates intentionally omitted. Focus is on delivering quality features in logical sequence. Prioritization based on:
1. User value
2. Technical dependencies
3. Resource availability
4. Market conditions

---

## Next Steps

1. Review and prioritize Phase 4 features
2. Decide on backend architecture (Option C recommended)
3. Set up backend infrastructure prototype
4. Plan beta testing program
5. Establish analytics and monitoring
