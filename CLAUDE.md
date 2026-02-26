# STASH - Development Guidelines

## Project Overview
STASH is a personal AI-powered thought capture app for iOS. Users capture fleeting thoughts, which are automatically classified, contextualized, and organized with the help of AI and a gamified "squirrelsona" companion system.

## Development Workflow

### Branch-Based Development
**ALWAYS use feature branches for ALL code changes.** NEVER commit directly to `main`.

#### ALL Code Changes Require Branches:
- ✅ New features (e.g., `feature/classification-override`)
- ✅ Bug fixes (e.g., `fix/storage-error`)
- ✅ Refactoring (e.g., `refactor/theme-system`)
- ✅ Experiments (e.g., `experiment/3d-charts`)
- ✅ Performance improvements
- ✅ UI/UX changes
- ✅ Any code modification whatsoever

#### ONLY Exception - Documentation on Main:
- ✅ CLAUDE.md updates (this file)
- ✅ README.md updates
- ✅ CHANGELOG.md updates
- ✅ Comment-only changes in code

**If it changes behavior, it goes in a branch. No exceptions.**

### Recommended Flow:

1. **Plan First**
   - Use `/plan` skill for non-trivial features
   - Write implementation plan before coding
   - Get user approval before starting

2. **Create Branch**
   - Use `/using-git-worktrees` for isolated workspace
   - Branch naming: `feature/`, `refactor/`, `fix/`, `experiment/`
   - Example: `feature/interactive-3d-charts`

3. **Develop & Iterate**
   - Build feature in isolation
   - Test thoroughly in branch
   - Keep commits focused and atomic

4. **Review & Merge**
   - Use `/finishing-a-development-branch` to guide next steps
   - Options: merge, create PR, or keep branch for later
   - Only merge when feature is useful and working

5. **Cleanup**
   - Delete branch after successful merge
   - Or keep branch if feature needs more iteration

## Code Quality Standards

### Before Committing:
- Code compiles without warnings
- Follows existing patterns (check similar files first)
- Theme-aware (uses `ThemeEngine.shared.getCurrentTheme()`)
- Accessibility considered (VoiceOver labels, dynamic type)

### Testing:
- Manual testing in both light/dark themes
- Test on different screen sizes if UI changes
- Verify existing features still work

## Project-Specific Patterns

### Theme System
All UI must use `ThemeEngine.shared.getCurrentTheme()`:
```swift
let theme = themeEngine.getCurrentTheme()
// Use: theme.textColor, theme.backgroundColor, theme.primaryColor, etc.
```

### Squirrelsona System
- Persona-voiced strings use pattern from `SquirrelReminderService.swift`
- All personas: Supportive Listener, Brainstorm Partner, Socratic Questioner, Journal Guide, Devil's Advocate

### AI Integration
- Claude API via `ClaudeService.shared`
- Structured outputs with `ResponseFormat<T>`
- Always handle errors gracefully

### Data Persistence
- SwiftData for local storage
- `ThoughtService.shared` for thought operations
- Context enrichment via `ContextService.shared`

## Technology Notes

### Swift Charts 3D (iOS 26+)
Chart3D has unique requirements learned during initial implementation:
- **symbolSize** uses viewport units (0.01-0.1), NOT pixel values
- Scale modifiers need BOTH `domain` (data range) AND `range` (viewport range)
  - Example: `.chartXScale(domain: 0...24, range: -0.5...0.5)`
- Point selection not yet available in iOS 26.0 beta
- Files preserved in `Sources/UI/Charts/*3D.swift` for future iteration

### sosumi MCP Server
Use sosumi for Apple documentation before implementing new iOS features:
```
/sosumi [query]
```
**Always check docs FIRST** when working with newer technologies.

## Lessons Learned

### 3D Charts (Feb 2025)
- Built interactive Chart3D visualizations
- Rendering worked, but not useful without point selection/interaction
- Hidden from UI but code preserved for future iteration when iOS 26 APIs mature
- **Takeaway**: Complex visualizations need interactivity to be useful

### NLTagger API (Feb 2026)
- `NLTagger.tag(at:unit:scheme:)` returns a **tuple** `(NLTag?, Range<String.Index>)`, not a bare optional
- Must destructure: `let (lemmaTag, _) = tagger.tag(at: ..., unit: .word, scheme: .lemma)`
- Optional chaining on the return value is a compile error

### Xcode Project File (Feb 2026)
- New Swift files must be manually added to `project.pbxproj` in three places:
  1. `PBXFileReference` section
  2. Group `children` array (under the correct folder group)
  3. `PBXSourcesBuildPhase` sources list
- Build will succeed in Xcode UI (auto-resolves) but CLI builds fail without this

### Accessibility Patterns (Feb 2026)
- Decorative SF Symbol icons alongside text must have `.accessibilityHidden(true)`
- Pickers with empty string labels need `.accessibilityLabel("...")` explicitly
- Buttons with explicit `.accessibilityLabel(...)` don't need Image children hidden — the label overrides children
- `ThoughtCardView` used in grid layouts benefits from `.accessibilityElement(children: .combine)`
- `ContextItem` pattern (`.accessibilityElement(children: .ignore)` + `.accessibilityLabel(...)`) is the right model for icon+label+value compound items

### Classification Feedback Loop (Feb 2026)
- `ClassificationBiasStore` is a `UserDefaults`-backed local bias layer — `@unchecked Sendable` because all mutation goes through thread-safe `UserDefaults`
- Pattern key = first 5 words lowercased; penalty threshold = 2.0 weight
- Three-state feedback (`helpful`/`partially_helpful`/`not_helpful`) must use `feedbackType: FeedbackType` not `isPositive: Bool` to avoid losing the middle state

## Future Considerations

### Onboarding (Planned)
- Squirrel-led interactive tutorial planned (see plan file)
- Real capture integration, not feature carousel
- Persona selection as first step

### Features to Revisit
- 3D charts when point selection APIs available
- Additional gamification mechanics
- Social/sharing features

---

**Main Branch**: Production-ready code only
**Feature Branches**: Experiments, new features, risky changes
**Documentation**: Keep this file updated with learnings
