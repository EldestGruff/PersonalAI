# iOS 26 + Foundation Models Development Skill

Expert-level iOS 26 development skill covering modern Apple Intelligence features, built from real-world experience developing PersonalAI.

## What This Skill Covers

### 🤖 Foundation Models (iOS 26+)
- `@Generable` macro for type-safe AI responses
- `LanguageModelSession` configuration and management
- `@Guide` attributes for better model outputs
- Tool calling patterns
- Fail-soft design for model unavailability

### 🏥 HealthKit State of Mind (iOS 18+)
- Mental health tracking with `HKStateOfMind`
- Valence classification (-1.0 to +1.0 scale)
- Labels and associations mapping
- Proper iOS 18+ availability checks
- Authorization and data fetching

### 📊 Swift Charts (iOS 16+)
- BarMark, LineMark, PointMark usage
- Axis customization and formatting
- Gradient styling and modern design
- Data aggregation patterns
- Responsive chart layouts

### 💳 StoreKit 2 (iOS 15+)
- Product loading and caching
- Purchase flow with verification
- Transaction listening and updates
- Restore purchases
- Subscription entitlement management

### ⚡ Swift 6 Strict Concurrency
- Actor isolation patterns
- `@MainActor` usage
- Sendable conformance
- Task namespace conflicts (`_Concurrency.Task`)
- Static vs instance method actor access

### 🗄️ Core Data Best Practices
- Automatic lightweight migration
- Migration error recovery
- JSON encoding for complex types
- Thread safety patterns

### 🎯 Architecture Patterns
- Debouncing user input
- Fail-soft service design
- Parallel task groups
- Tag normalization
- Performance optimization

## Installation

This skill is already installed at:
```
~/.claude/skills/ios26-foundation-models/
```

## Usage

Activate the skill in Claude Code by referencing iOS 26 concepts:

```
"Create a Foundation Models classification service"
"Add HealthKit State of Mind tracking"
"Set up StoreKit 2 subscriptions"
"Fix Swift 6 concurrency error"
"Add Swift Charts analytics dashboard"
```

## Real-World Examples

This skill was built from actual code in the PersonalAI project:

- **Foundation Models Classification**: Real sentiment analysis and tag suggestion
- **HealthKit Integration**: Actual State of Mind context gathering
- **StoreKit 2**: Production subscription system (Free + Pro tiers)
- **Swift Charts**: Live analytics dashboards
- **Concurrency Solutions**: All Swift 6 strict concurrency fixes

## Code Quality Standards

- ✅ Swift 6 strict concurrency compliant
- ✅ iOS 26 API compatible
- ✅ Fail-soft error handling
- ✅ Comprehensive documentation
- ✅ Production-ready patterns
- ✅ Performance optimized

## Key Learnings Captured

### Foundation Models
- Always check `isAvailable` before initialization
- Use detailed `@Guide` descriptions for better results
- Provide examples in instructions for consistent output
- Handle sarcasm and edge cases in sentiment analysis

### HealthKit State of Mind
- Map HK enums to strings for storage/JSON
- Use recent time windows (last hour) for relevance
- Fail gracefully with optional returns
- Always check iOS 18+ availability

### StoreKit 2
- Verify all transactions with `VerificationResult`
- Listen to `Transaction.updates` for real-time changes
- Use static methods to avoid actor isolation issues
- Singleton pattern works well for app-wide access

### Swift 6 Concurrency
- `_Concurrency.Task` avoids namespace conflicts
- Static methods bypass actor isolation
- `@MainActor` for UI, regular actors for services
- `nonisolated` for non-stateful methods

### Performance
- Debounce at 1.5 seconds for typing
- Detect paste (>50 char change) for immediate classification
- Use parallel TaskGroup for independent operations
- Set timeouts on framework operations

## Contributing

This skill will evolve as we discover more patterns and best practices. Future additions:
- App Intents integration
- Live Activities
- Widgets with App Intents
- TipKit integration
- More HealthKit data types

## Credits

Built by Claude and Andy while developing PersonalAI - a context-aware thought capture app using iOS 26's newest features.

## Version History

- **1.0.0** (2026-01-31): Initial release
  - Foundation Models classification
  - HealthKit State of Mind
  - Swift Charts dashboards
  - StoreKit 2 subscriptions
  - Swift 6 concurrency patterns
  - Core Data migration
