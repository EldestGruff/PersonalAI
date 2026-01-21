# Planning Documentation Quick Reference

**Quick navigation guide for common planning tasks**

---

## 🎯 Common Tasks

### I want to... plan a new feature
1. **Check if it's already planned:** [ROADMAP.md](./ROADMAP.md) or [FEATURES.md](../../FEATURES.md)
2. **Log the request:** Add to [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
3. **Write detailed spec:** Update [FEATURES.md](../../FEATURES.md)
4. **Plan implementation:** Review relevant sections in [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) if backend work needed

### I want to... report a bug
1. **Add to tracking:** Use bug template in [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
2. **Log technical details:** If architecture/code issue, add to [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md)
3. **Update status:** Keep status current as bug is investigated and fixed

### I want to... set up the backend
1. **Read architecture decision:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - Hybrid approach section
2. **Follow implementation steps:** "Next Steps" section in BACKEND_STRATEGY.md
3. **Track progress:** Update [ROADMAP.md](./ROADMAP.md) Phase 5 status

### I want to... plan a release
1. **Review roadmap:** [ROADMAP.md](./ROADMAP.md) for phase goals
2. **Check quality gates:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Release Quality Gates
3. **Verify all critical bugs fixed:** [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
4. **Run testing checklist:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Testing Checklist

### I want to... start beta testing
1. **Review beta program design:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Beta Testing Program
2. **Prepare feedback collection:** Set up forms/channels per TESTING_STRATEGY.md
3. **Recruit testers:** Follow recruitment strategy in TESTING_STRATEGY.md

### I want to... prioritize technical debt
1. **Review debt items:** [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md)
2. **Consider user impact:** Check related items in [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
3. **Plan cleanup sprint:** Schedule 1-2 high-priority items per month

### I want to... make an architectural decision
1. **Review principles:** [/docs/development/ARCHITECTURE_AS_PROTOCOL.md](../development/ARCHITECTURE_AS_PROTOCOL.md)
2. **Consider backend impact:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md)
3. **Document decision:** Add to [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md) - Implementation Notes

---

## 📂 Document Overview

| Document | Primary Use | Update Frequency |
|----------|-------------|------------------|
| **ROADMAP.md** | Strategic planning, phase goals | Monthly or on strategy change |
| **BACKEND_STRATEGY.md** | Technical architecture, implementation | When architecture decisions made |
| **CUSTOMER_REQUESTS.md** | Feature requests, bugs, feedback | Weekly (triage) |
| **TESTING_STRATEGY.md** | QA approach, test planning | Per phase or test approach change |
| **TECHNICAL_DEBT.md** | Code quality, refactoring | Weekly (add items), monthly (prioritize) |

---

## 🔄 Typical Workflows

### New Feature Development Workflow
```
1. User request → CUSTOMER_REQUESTS.md (feature request)
2. Evaluate & prioritize → ROADMAP.md (add to phase)
3. Write specification → FEATURES.md (detailed spec)
4. Plan testing → TESTING_STRATEGY.md (add test scenarios)
5. Develop feature → (code in /Sources)
6. Track debt → TECHNICAL_DEBT.md (if shortcuts taken)
7. Test & ship → TESTING_STRATEGY.md (quality gates)
8. Update status → Mark complete in all docs
```

### Bug Fix Workflow
```
1. Bug reported → CUSTOMER_REQUESTS.md (bug report template)
2. Investigate → TECHNICAL_DEBT.md (if root cause is debt)
3. Fix & test → TESTING_STRATEGY.md (regression tests)
4. Close bug → Update status in CUSTOMER_REQUESTS.md
```

### Backend Implementation Workflow
```
1. Decide on architecture → BACKEND_STRATEGY.md (choose approach)
2. Set up infrastructure → Follow "Next Steps" in BACKEND_STRATEGY.md
3. Track progress → ROADMAP.md (Phase 5 status)
4. Test integration → TESTING_STRATEGY.md (integration tests)
5. Monitor & iterate → CUSTOMER_REQUESTS.md (collect feedback)
```

### Release Planning Workflow
```
1. Review phase goals → ROADMAP.md
2. Check open bugs → CUSTOMER_REQUESTS.md (critical/high priority)
3. Verify features complete → FEATURES.md (check status)
4. Plan testing → TESTING_STRATEGY.md (beta program)
5. Address tech debt → TECHNICAL_DEBT.md (high priority items)
6. Run quality checks → TESTING_STRATEGY.md (quality gates)
7. Ship release → Update all docs with completion status
```

---

## 🎨 Template Quick Links

### Adding a Feature Request
Location: [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
```markdown
#### FR-XXX: [Brief Title]
- **Requested By:** [Name/source]
- **Date:** [YYYY-MM-DD]
- **Description:** [What they want]
- **Use Case:** [Why they want it]
- **Status:** New
- **Priority:** [Critical/High/Medium/Low]
```

### Adding a Bug Report
Location: [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md)
```markdown
#### BUG-XXX: [Brief Title]
- **Reported By:** [Name/source]
- **Date:** [YYYY-MM-DD]
- **Description:** [What's broken]
- **Steps to Reproduce:** [How to trigger]
- **Expected Behavior:** [What should happen]
- **Actual Behavior:** [What actually happens]
- **Status:** Investigating
- **Priority:** [Critical/High/Medium/Low]
- **Related Code:** [File paths]
```

### Adding Technical Debt
Location: [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md)
```markdown
#### TD-XXX: [Brief Title]
- **Category:** [Bug/Architecture/Code Quality/Testing/Performance]
- **Description:** [What needs fixing]
- **Impact:** [How it affects users/dev]
- **Location:** [File paths]
- **Proposed Fix:** [How to fix it]
- **Fix Estimate:** [Hours/days]
- **Priority:** [High/Medium/Low]
```

---

## 🔍 Key Sections by Topic

### Backend Planning
- **Architecture:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - Recommended Architecture
- **Database:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - Data Architecture
- **AI Service:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - AI Service Architecture
- **Deployment:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - Deployment Strategy
- **Costs:** [BACKEND_STRATEGY.md](./BACKEND_STRATEGY.md) - Cost Estimates

### Feature Planning
- **Phases:** [ROADMAP.md](./ROADMAP.md) - Phase 4, 5, 6
- **Priorities:** [FEATURES.md](../../FEATURES.md) - High/Medium/Low sections
- **Requests:** [CUSTOMER_REQUESTS.md](./CUSTOMER_REQUESTS.md) - Feature Requests

### Quality & Testing
- **Test Types:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Testing Pyramid
- **Beta Program:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Beta Testing Program
- **Quality Gates:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Release Quality Gates
- **Performance:** [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - Performance Testing

### Code Quality
- **Current Debt:** [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md) - Technical Debt Items
- **Refactoring:** [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md) - Code Smells
- **Decisions:** [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md) - Implementation Notes
- **Optimization:** [TECHNICAL_DEBT.md](./TECHNICAL_DEBT.md) - Performance Opportunities

---

## 💡 Tips

- **Keep docs in sync:** When updating one doc, check if related docs need updates
- **Use cross-references:** Link between related items across documents
- **Update dates:** Change "Last Updated" when making changes
- **Be specific:** Use concrete examples and file paths, not vague descriptions
- **Track status:** Keep status fields current so you know what's in flight
- **Review regularly:** Set calendar reminders for document reviews

---

**Last Updated:** 2026-01-20
