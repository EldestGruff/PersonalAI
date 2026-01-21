# Backend Infrastructure Strategy

**Last Updated:** 2026-01-20

## Overview

This document outlines the backend infrastructure strategy for PersonalAI, focusing on sustainability, scalability, and developer experience.

---

## Requirements

### Must-Have
1. **User Authentication & Management**
   - Secure sign-in (Apple ID, email/password)
   - User profile storage
   - Device management

2. **Data Synchronization**
   - Real-time sync across user devices
   - Offline-first architecture
   - Conflict resolution

3. **AI/ML Services**
   - Classification API endpoint
   - Model hosting and versioning
   - Fine-tuning pipeline for user feedback

4. **Storage**
   - Thought data persistence
   - Context snapshots
   - User preferences

5. **API Security**
   - Rate limiting
   - Request authentication
   - Data encryption (in-transit and at-rest)

### Nice-to-Have
1. **Analytics Pipeline**
   - Usage metrics
   - Performance monitoring
   - Model performance tracking

2. **Third-Party Integrations**
   - Weather API
   - Location enrichment services
   - Calendar/email connectors

3. **Admin Dashboard**
   - User management
   - System health monitoring
   - Feature flags

---

## Recommended Architecture: Hybrid Approach

### Stack Components

#### 1. Supabase (Primary Backend)
**Purpose:** Authentication, database, storage, real-time sync

**Services Used:**
- **Supabase Auth:** Apple Sign-In, email/password
- **Supabase Database (PostgreSQL):** User data, thoughts, tags, feedback
- **Supabase Storage:** File attachments (future: voice notes, images)
- **Supabase Realtime:** Cross-device synchronization
- **Row Level Security (RLS):** User data isolation

**Why Supabase:**
- Open source (less vendor lock-in than Firebase)
- PostgreSQL (powerful queries, full-text search)
- Self-hostable if needed
- Generous free tier
- Great iOS SDK

#### 2. Custom AI Service (Python/FastAPI)
**Purpose:** AI classification, model serving, fine-tuning

**Components:**
- **Classification API:** RESTful endpoint for thought classification
- **Model Registry:** Versioned models with A/B testing support
- **Fine-tuning Pipeline:** Process user feedback, retrain models
- **Model Serving:** Load-balanced inference with caching

**Tech Stack:**
- FastAPI for API framework
- PyTorch/HuggingFace Transformers for models
- Redis for caching
- S3/R2 for model storage
- Docker for containerization

**Why Custom:**
- Full control over model architecture
- Custom fine-tuning from user feedback
- Ability to upgrade models independently
- Optimized for specific classification task

#### 3. CloudKit (Optional iOS Integration)
**Purpose:** Apple ecosystem features, privacy-first sync

**Use Cases:**
- iCloud sync for users preferring Apple ecosystem
- Handoff between devices
- Keychain integration for sensitive data
- Siri integration data

**Why CloudKit:**
- Deep iOS integration
- User privacy (data stays in iCloud)
- Free with Apple ID
- No backend costs

---

## Data Architecture

### Database Schema (Supabase PostgreSQL)

```sql
-- Users table (managed by Supabase Auth)
-- Extended with custom profile data

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  preferences JSONB,
  onboarding_completed BOOLEAN DEFAULT FALSE
);

-- Thoughts table
CREATE TABLE thoughts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Core data
  content TEXT NOT NULL,
  classification_type TEXT NOT NULL, -- task, note, idea, reminder, event
  sentiment JSONB, -- {dominant: "happy", scores: {...}}

  -- Context snapshot
  context JSONB, -- location, time, energy, calendar_free, etc.

  -- Metadata
  tags TEXT[],
  is_archived BOOLEAN DEFAULT FALSE,

  -- Search
  search_vector TSVECTOR GENERATED ALWAYS AS (to_tsvector('english', content)) STORED
);

CREATE INDEX thoughts_user_id_idx ON thoughts(user_id);
CREATE INDEX thoughts_search_idx ON thoughts USING GIN(search_vector);
CREATE INDEX thoughts_created_at_idx ON thoughts(created_at DESC);

-- User feedback for fine-tuning
CREATE TABLE classification_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  thought_id UUID NOT NULL REFERENCES thoughts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  original_classification TEXT NOT NULL,
  corrected_classification TEXT NOT NULL,
  model_version TEXT NOT NULL
);

-- Tags
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, name)
);

-- Device sync tracking
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  device_name TEXT,
  last_sync_at TIMESTAMPTZ,
  push_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE classification_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own data
CREATE POLICY "Users can CRUD their own thoughts"
  ON thoughts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own feedback"
  ON classification_feedback
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can CRUD their own tags"
  ON tags
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## AI Service Architecture

### Classification API Endpoint

```
POST /api/v1/classify
Authorization: Bearer <jwt_token>

Request:
{
  "content": "Remind me to call mom tomorrow",
  "context": {
    "timestamp": "2026-01-20T14:30:00Z",
    "location": {...},
    "energy_level": 0.75,
    "calendar_free": true
  }
}

Response:
{
  "classification": {
    "type": "reminder",
    "confidence": 0.95
  },
  "sentiment": {
    "dominant": "neutral",
    "scores": {"happy": 0.3, "sad": 0.1, ...}
  },
  "extracted_entities": {
    "people": ["mom"],
    "datetime": "2026-01-21T12:00:00Z"
  },
  "model_version": "v1.2.3"
}
```

### Fine-Tuning Pipeline

1. **Feedback Collection**
   - Store user corrections in `classification_feedback` table
   - Track model version for each correction

2. **Batch Processing**
   - Nightly/weekly job to process new feedback
   - Generate training examples from corrections
   - Augment with context data

3. **Model Training**
   - Fine-tune classification model on user data
   - Maintain user privacy (federated learning optional)
   - Version models (v1.0.0, v1.1.0, etc.)

4. **Deployment**
   - A/B testing: route 10% of traffic to new model
   - Monitor performance metrics
   - Gradual rollout if successful

5. **Rollback**
   - Keep previous model versions available
   - Quick rollback if new model underperforms

---

## Deployment Strategy

### Environment Setup

1. **Development**
   - Local Supabase instance (Docker)
   - Local AI service (Docker Compose)
   - Mock data for testing

2. **Staging**
   - Supabase staging project
   - AI service on staging cluster
   - Realistic test data
   - Beta tester access

3. **Production**
   - Supabase production project
   - AI service on production cluster (auto-scaling)
   - Monitoring and alerts
   - Backup and disaster recovery

### Infrastructure

#### Supabase
- Hosted on Supabase Cloud (recommended for MVP)
- Or self-hosted on AWS/GCP/Railway for full control

#### AI Service Hosting Options

**Option A: Railway.app**
- Easy deployment from Git
- Auto-scaling
- Good for MVP
- ~$20-50/month

**Option B: AWS ECS/Fargate**
- More control
- Better scaling
- Lower cost at scale
- Requires more DevOps

**Option C: Modal.com**
- Serverless GPU inference
- Pay per request
- Great for ML workloads
- Easy deployment

**Recommendation for MVP:** Railway.app (simplicity) or Modal.com (if GPU needed)

---

## Cost Estimates (MVP Scale)

### Supabase (up to 10K users)
- Free tier: 500MB database, 1GB storage, 2GB bandwidth
- Pro tier: $25/month (8GB database, 100GB storage, 250GB bandwidth)

### AI Service (Railway.app)
- Starter: $5/month per service
- Pro: $20/month per service (auto-scaling)

### Third-Party APIs
- Weather API (OpenWeatherMap): Free tier (60 calls/min)
- Geocoding (MapBox): Free tier (100K requests/month)

### Total Monthly Cost (MVP)
- **Minimal:** $0-30/month (free tiers + basic hosting)
- **Growth:** $50-100/month (10K active users)
- **Scale:** $200-500/month (100K active users)

---

## Security Considerations

### Authentication
- Use Supabase Auth with Apple Sign-In (primary)
- Email/password as fallback
- JWT tokens with short expiration (1 hour)
- Refresh token rotation

### Data Privacy
- Row Level Security (RLS) on all tables
- Encrypt sensitive data at rest
- HTTPS/TLS for all API calls
- Minimal data collection (privacy-first)

### API Security
- Rate limiting (per user, per IP)
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- CORS configuration

### Compliance
- GDPR: Data export, deletion, consent
- CCPA: Data access and deletion
- App Store Privacy Labels: Declare data usage

---

## Monitoring & Observability

### Application Monitoring
- Sentry for error tracking
- Supabase built-in analytics
- Custom metrics (Prometheus/Grafana optional)

### Model Monitoring
- Classification accuracy over time
- Confidence distribution
- Feedback rate (% of thoughts corrected)
- Model latency

### Infrastructure
- Uptime monitoring (UptimeRobot, Better Uptime)
- API response times
- Database query performance
- Storage usage

---

## Next Steps

### Phase 1: Supabase Setup (Week 1)
- [ ] Create Supabase project
- [ ] Design and implement database schema
- [ ] Set up Row Level Security policies
- [ ] Configure Apple Sign-In
- [ ] Test authentication flow from iOS app

### Phase 2: API Integration (Week 2)
- [ ] Add Supabase Swift SDK to iOS app
- [ ] Implement authentication in app
- [ ] Sync thoughts to Supabase
- [ ] Test offline-first sync
- [ ] Handle conflict resolution

### Phase 3: AI Service (Week 3-4)
- [ ] Set up FastAPI project
- [ ] Deploy classification model
- [ ] Create classification endpoint
- [ ] Integrate with iOS app
- [ ] Test end-to-end flow

### Phase 4: Fine-Tuning Pipeline (Week 5-6)
- [ ] Design feedback processing pipeline
- [ ] Implement model versioning
- [ ] Set up A/B testing framework
- [ ] Deploy first fine-tuned model
- [ ] Monitor performance

---

## Open Questions

1. **Privacy Model:** How much data should leave the device? On-device ML vs. server-side?
2. **Pricing Strategy:** Free tier limits? Subscription model?
3. **Multi-Tenancy:** Single shared DB vs. DB per user for large customers?
4. **Backup Strategy:** How often? Retention policy?
5. **International:** Multi-region deployment needed?

---

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase-community/supabase-swift)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Railway.app](https://railway.app/)
- [Modal.com](https://modal.com/)
