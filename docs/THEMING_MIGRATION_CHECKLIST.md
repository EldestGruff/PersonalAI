# Theming Migration Checklist

Quick reference for replacing hardcoded colors with theme tokens.

## Files to Update (Priority Order)

### 🔴 Critical - Accessibility Contrast Failures

#### 1. ClassificationBadge.swift (Line 94)
```swift
// BEFORE:
.background(Color.purple.opacity(0.05))

// AFTER:
.background(Color.theme.classificationBackground)
```
**Asset Needed**: `ClassificationBackground.colorset` (purple at 15% opacity)

---

#### 2. ContextDisplayView.swift (Line 94)
```swift
// BEFORE:
.background(Color.teal.opacity(0.05))

// AFTER:
.background(Color.theme.contextBackground)
```
**Asset Needed**: `ContextBackground.colorset` (teal at 15% opacity)

---

#### 3. TagInputView.swift (Line 95)
```swift
// BEFORE:
.background(Color.gray.opacity(0.1))

// AFTER:
.background(Color.theme.inputBackground)
```
**Asset Needed**: `InputBackground.colorset` (gray at 15% opacity)

---

#### 4. ThoughtRowView.swift (Multiple lines)
**Badge backgrounds**:
```swift
// BEFORE:
.background(Color.blue.opacity(0.1))

// AFTER:
.background(Color.theme.badgeBackground)
```
**Asset Needed**: `BadgeBackground.colorset`

---

#### 5. BrowseScreen.swift (Filter sheet)
**Selection indicators**:
```swift
// BEFORE:
.background(viewModel.isSelected ? Color.blue.opacity(0.1) : Color.clear)

// AFTER:
.background(viewModel.isSelected ? Color.theme.selectionBackground : Color.clear)
```
**Asset Needed**: `SelectionBackground.colorset`

---

### 🟡 Medium Priority - Consistency Improvements

#### 6. DetailScreen.swift
**Feedback button backgrounds** (Line 426):
```swift
// BEFORE:
.background(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))

// AFTER:
.background(isSelected ? Color.theme.selectedFeedback : Color.theme.unselectedFeedback)
```
**Assets Needed**:
- `SelectedFeedback.colorset`
- `UnselectedFeedback.colorset`

---

#### 7. CaptureScreen.swift
**Text editor background** (Line 128):
```swift
// BEFORE:
.background(Color.gray.opacity(0.1))

// AFTER:
.background(Color.theme.inputBackground)
```
**Asset**: Same as TagInputView

---

#### 8. SearchScreen.swift
**Search bar background** (Line 89):
```swift
// BEFORE:
.background(Color.gray.opacity(0.1))

// AFTER:
.background(Color.theme.inputBackground)
```
**Asset**: Same as TagInputView

---

### 🟢 Low Priority - Already Acceptable

#### 9. ErrorView.swift ✅
Already using solid colors - no changes needed:
```swift
.background(Color.red.opacity(0.05))  // Error cards - OK for AA
```

---

## Asset Catalog Requirements

### Required Color Sets (Minimum)

Create these `.colorset` files in `PersonalAI.xcassets/Colors/`:

1. **ClassificationBackground.colorset**
   - Light: `rgba(139, 92, 246, 0.15)` (purple)
   - Dark: `rgba(139, 92, 246, 0.20)` (slightly higher for visibility)

2. **ContextBackground.colorset**
   - Light: `rgba(20, 184, 166, 0.15)` (teal)
   - Dark: `rgba(20, 184, 166, 0.20)`

3. **InputBackground.colorset**
   - Light: `rgba(107, 114, 128, 0.15)` (gray)
   - Dark: `rgba(156, 163, 175, 0.15)` (lighter gray for dark mode)

4. **BadgeBackground.colorset**
   - Light: `rgba(59, 130, 246, 0.15)` (blue)
   - Dark: `rgba(96, 165, 250, 0.15)` (lighter blue)

5. **SelectionBackground.colorset**
   - Light: `rgba(59, 130, 246, 0.15)` (blue)
   - Dark: `rgba(96, 165, 250, 0.15)`

6. **SelectedFeedback.colorset**
   - Light: Dynamic based on button color at 0.15 opacity
   - Dark: Same

7. **UnselectedFeedback.colorset**
   - Light: `rgba(107, 114, 128, 0.10)` (gray)
   - Dark: `rgba(75, 85, 99, 0.15)`

---

## Color Extension Setup

**File**: `Sources/UI/Theme/ThemeColors.swift` (new file)

```swift
import SwiftUI

extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Backgrounds
    let classificationBackground = Color("ClassificationBackground")
    let contextBackground = Color("ContextBackground")
    let inputBackground = Color("InputBackground")
    let badgeBackground = Color("BadgeBackground")
    let selectionBackground = Color("SelectionBackground")

    // Feedback
    let selectedFeedback = Color("SelectedFeedback")
    let unselectedFeedback = Color("UnselectedFeedback")

    // Text (semantic)
    let textPrimary = Color.primary
    let textSecondary = Color.secondary

    // Add more as needed...
}
```

---

## Find & Replace Patterns

Use these grep commands to find hardcoded colors:

```bash
# Find opacity-based backgrounds
grep -rn "\.opacity(0\." Sources/UI/ | grep background

# Find direct color references
grep -rn "Color\.(blue|purple|teal|gray)\.opacity" Sources/UI/

# Find all .background calls
grep -rn "\.background(Color\." Sources/UI/
```

---

## Testing Checklist

After implementing theme colors:

### Light Mode
- [ ] Classification badges readable
- [ ] Context cards readable
- [ ] Tag input background visible
- [ ] Thought row badges readable
- [ ] Filter selections visible
- [ ] Feedback buttons clear

### Dark Mode
- [ ] All above items readable in dark mode
- [ ] No jarring color shifts
- [ ] Consistent visual hierarchy

### Contrast Validation
- [ ] Run WebAIM checker on all new backgrounds
- [ ] Verify 4.5:1 minimum ratio
- [ ] Test with VoiceOver color announcements

---

## Implementation Order

1. **Create Asset Catalog** (30 minutes)
   - Add 7 color sets with light/dark variants

2. **Create ThemeColors.swift** (15 minutes)
   - Extension providing semantic names

3. **Update Critical Files** (1-2 hours)
   - Fix all 5 critical accessibility failures
   - Test each file after changes

4. **Update Medium Priority** (1 hour)
   - Improve consistency in DetailScreen, CaptureScreen, SearchScreen

5. **Test & Validate** (30 minutes)
   - Light/dark mode testing
   - Contrast validation
   - Build verification

**Total Time**: 3-4 hours

---

## Quick Reference - Opacity Guidelines

| Purpose | Minimum Opacity | Recommended |
|---------|----------------|-------------|
| Badge backgrounds | 0.15 | 0.15-0.20 |
| Input backgrounds | 0.15 | 0.15 |
| Selection indicators | 0.15 | 0.15 |
| Hover states | 0.10 | 0.10-0.15 |
| Disabled states | 0.05 | 0.05-0.10 |

**Rule of Thumb**: If text sits on it, use ≥0.15 opacity

---

## Before/After Examples

### Classification Badge
```swift
// ❌ BEFORE (Fails WCAG AA)
VStack {
    Text("Classification")
}
.background(Color.purple.opacity(0.05))  // Only 5%!

// ✅ AFTER (Passes WCAG AA)
VStack {
    Text("Classification")
}
.background(Color.theme.classificationBackground)  // 15% opacity
```

### Tag Input
```swift
// ❌ BEFORE
TextField("Add tag...", text: $tag)
    .background(Color.gray.opacity(0.1))  // 10% - borderline

// ✅ AFTER
TextField("Add tag...", text: $tag)
    .background(Color.theme.inputBackground)  // 15% guaranteed
```

---

**Created**: 2026-01-27
**Related**: THEMING_ASSET_REQUIREMENTS.md, Issue #19, Issue #10
**Status**: Ready for implementation
