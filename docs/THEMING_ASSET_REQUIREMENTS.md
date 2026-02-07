# Theming System - Asset & Design Requirements

**Purpose**: Define all assets, colors, and design tokens needed for the theming system
**Related Issues**: #10 (Theme System), #19 (Accessibility - Contrast Fixes)
**Status**: Specification - Ready for Design/Implementation

---

## Overview

The theming system will enable:
1. **Light/Dark Mode** - Automatic or manual theme switching
2. **Color Schemes** - Multiple brand color variants
3. **Accessibility** - WCAG AA compliant contrast ratios
4. **Squirrel-sona** - Future personalization support (Issue #13)

---

## Color Palette Requirements

### Primary Brand Colors

Define these colors with both light and dark mode variants:

#### Primary (Action Color)
```swift
// Light Mode
primary: #3B82F6        // Blue - Buttons, links, active states
primaryHover: #2563EB   // Darker blue - Hover states
primaryPressed: #1D4ED8 // Even darker - Pressed states

// Dark Mode
primary: #60A5FA        // Lighter blue for dark backgrounds
primaryHover: #3B82F6
primaryPressed: #2563EB
```

**Usage**: FAB, primary buttons, active tab indicators, selected states

**Accessibility Requirement**: Must achieve 4.5:1 contrast against backgrounds

#### Secondary (Supporting Color)
```swift
// Light Mode
secondary: #8B5CF6      // Purple - Secondary actions

// Dark Mode
secondary: #A78BFA      // Lighter purple
```

**Usage**: Secondary buttons, tags, classification badges

#### Accent Colors (By Function)

**Success/Positive**:
```swift
success: #10B981        // Green
successBackground: rgba(16, 185, 129, 0.15)  // 15% opacity minimum for AA
```

**Warning/Caution**:
```swift
warning: #F59E0B        // Amber
warningBackground: rgba(245, 158, 11, 0.15)
```

**Error/Negative**:
```swift
error: #EF4444          // Red
errorBackground: rgba(239, 68, 68, 0.15)
```

**Info/Neutral**:
```swift
info: #06B6D4           // Cyan
infoBackground: rgba(6, 182, 212, 0.15)
```

### Semantic Colors

#### Text Colors
```swift
// Light Mode
textPrimary: #111827       // Near black - Body text
textSecondary: #6B7280     // Medium gray - Captions, labels
textTertiary: #9CA3AF      // Light gray - Placeholders

// Dark Mode
textPrimary: #F9FAFB       // Near white
textSecondary: #D1D5DB
textTertiary: #9CA3AF
```

**Contrast Requirements**:
- Primary text: 7:1 (AAA standard)
- Secondary text: 4.5:1 (AA standard)
- Tertiary text: 3:1 (minimum for UI components)

#### Background Colors
```swift
// Light Mode
backgroundPrimary: #FFFFFF     // Main canvas
backgroundSecondary: #F9FAFB   // Cards, elevated surfaces
backgroundTertiary: #F3F4F6    // Input backgrounds, dividers

// Dark Mode
backgroundPrimary: #111827
backgroundSecondary: #1F2937
backgroundTertiary: #374151
```

#### Surface Colors (Cards, Sheets, Overlays)
```swift
// Light Mode
surface: #FFFFFF
surfaceElevated: #FFFFFF with shadow

// Dark Mode
surface: #1F2937
surfaceElevated: #374151
```

### Thought Type Colors

Match existing classification system (from ChartDataModels.swift):

```swift
note: #3B82F6      // Blue
idea: #8B5CF6      // Purple
reminder: #F59E0B  // Amber
event: #10B981     // Green
question: #EC4899  // Pink
```

**Background variants** (for badges, pills):
```swift
noteBackground: rgba(59, 130, 246, 0.15)
ideaBackground: rgba(139, 92, 246, 0.15)
reminderBackground: rgba(245, 158, 11, 0.15)
eventBackground: rgba(16, 185, 129, 0.15)
questionBackground: rgba(236, 72, 153, 0.15)
```

**Critical**: All background opacities must be ≥0.15 (15%) for WCAG AA contrast

### Energy Level Colors

```swift
energyLow: #EF4444      // Red
energyMedium: #F59E0B   // Amber
energyHigh: #10B981     // Green
energyPeak: #06B6D4     // Cyan/Mint
```

### Sentiment Colors

```swift
sentimentVeryPositive: #10B981   // Green
sentimentPositive: #84CC16       // Lime
sentimentNeutral: #6B7280        // Gray
sentimentNegative: #F59E0B       // Amber
sentimentVeryNegative: #EF4444   // Red
```

---

## Shadow & Elevation System

Define elevation levels for depth perception:

```swift
// iOS-style shadows
elevation1: {
    color: rgba(0, 0, 0, 0.1)
    radius: 2
    offset: (0, 1)
}

elevation2: {
    color: rgba(0, 0, 0, 0.15)
    radius: 4
    offset: (0, 2)
}

elevation3: {
    color: rgba(0, 0, 0, 0.2)
    radius: 8
    offset: (0, 4)
}
```

**Usage**:
- Elevation1: Cards, list items
- Elevation2: Floating action button
- Elevation3: Modals, sheets

---

## Spacing System

Define consistent spacing tokens:

```swift
spacing_xs: 4pt
spacing_sm: 8pt
spacing_md: 16pt
spacing_lg: 24pt
spacing_xl: 32pt
spacing_2xl: 48pt
spacing_3xl: 64pt
```

**Current Usage Analysis** (for consistency):
- Padding: Most use 8pt, 12pt, 16pt → Standardize to spacing tokens
- Vertical spacing: 12pt, 16pt, 20pt → Use spacing_sm, spacing_md
- Section gaps: 20pt, 24pt → Use spacing_lg

---

## Border Radius System

```swift
radius_sm: 8pt      // Input fields, small buttons
radius_md: 10pt     // Cards, badges
radius_lg: 12pt     // Sheets, modals
radius_xl: 16pt     // Large cards
radius_full: 9999pt // Circular (FAB, avatars)
```

**Current Usage**: Most use 8pt and 10pt → Good consistency already

---

## Typography Scale

Define semantic text styles (already using Dynamic Type ✅):

```swift
largeTitle: .largeTitle      // 34pt
title1: .title               // 28pt
title2: .title2              // 22pt
title3: .title3              // 20pt
headline: .headline          // 17pt bold
body: .body                  // 17pt regular
callout: .callout            // 16pt
subheadline: .subheadline    // 15pt
footnote: .footnote          // 13pt
caption: .caption            // 12pt
caption2: .caption2          // 11pt
```

**Already Implemented**: ✅ App uses semantic font styles throughout

---

## Icon System

### System Icons (SF Symbols)

**Current Usage**: All using SF Symbols ✅

**Requirements**:
- Maintain consistent sizing: `.font(.title2)`, `.font(.caption)`, etc.
- Use semantic color names from theme
- All decorative icons: `.accessibilityHidden(true)` ✅ Already done

### Custom Icons (Future)

If adding custom icons:
- Provide as SF Symbol-compatible vectors
- Include light/dark mode variants
- Export at 1x, 2x, 3x for device scaling

---

## Asset Catalog Structure

Recommended Xcode Asset Catalog organization:

```
STASH.xcassets/
├── Colors/
│   ├── Brand/
│   │   ├── Primary.colorset
│   │   ├── Secondary.colorset
│   │   └── Accent.colorset
│   ├── Semantic/
│   │   ├── TextPrimary.colorset
│   │   ├── TextSecondary.colorset
│   │   ├── BackgroundPrimary.colorset
│   │   └── BackgroundSecondary.colorset
│   ├── ThoughtTypes/
│   │   ├── NoteColor.colorset
│   │   ├── IdeaColor.colorset
│   │   ├── ReminderColor.colorset
│   │   ├── EventColor.colorset
│   │   └── QuestionColor.colorset
│   └── Status/
│       ├── SuccessColor.colorset
│       ├── WarningColor.colorset
│       └── ErrorColor.colorset
└── Icons/
    └── (custom icons if needed)
```

### Color Set Configuration

Each `.colorset` must include:
- **Any Appearance**: Light mode color
- **Dark Appearance**: Dark mode color
- **High Contrast variants** (optional, for accessibility)

**Example: Primary.colorset/Contents.json**:
```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.231",
          "green": "0.510",
          "blue": "0.965",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.376",
          "green": "0.647",
          "blue": "0.980",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
```

---

## Files Requiring Color Updates

**From Accessibility Audit** (Issue #19):

### High Priority (Contrast Fixes)

1. **ClassificationBadge.swift:94**
   ```swift
   // Current: .background(Color.purple.opacity(0.05))
   // Fix: .background(Color("ThoughtTypeBackground"))  // ≥0.15 opacity
   ```

2. **ContextDisplayView.swift:94**
   ```swift
   // Current: .background(Color.teal.opacity(0.05))
   // Fix: .background(Color("ContextBackground"))  // ≥0.15 opacity
   ```

3. **TagInputView.swift:95**
   ```swift
   // Current: .background(Color.gray.opacity(0.1))
   // Fix: .background(Color("InputBackground"))  // Semantic token
   ```

4. **ThoughtRowView.swift** (multiple locations)
   ```swift
   // Badge backgrounds with blue text
   // Fix: Use themed badge component with proper contrast
   ```

5. **BrowseScreen.swift** (filter sheet)
   ```swift
   // Status indicators with blue backgrounds
   // Fix: Use themed selection indicator
   ```

### Medium Priority (Consistency)

6. **ErrorView.swift**
   - Error background: ✅ Already fixed to solid colors
   - Maintain red.opacity(0.05) for error cards

7. **DetailScreen.swift**
   - Feedback button backgrounds: Use themed colors
   - Energy breakdown colors: Already semantic ✅

---

## Implementation Strategy

### Phase 1: Asset Creation (Design)
1. **Define Color Palette** in Figma/Sketch
2. **Test Contrast Ratios** using [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
3. **Export Color Values** as hex codes
4. **Create Asset Catalog** in Xcode

### Phase 2: Theme System Code (Development)
1. **Create ThemeManager.swift**:
   ```swift
   @MainActor
   final class ThemeManager: ObservableObject {
       @Published var currentTheme: Theme = .system
       @Published var colorScheme: ColorScheme = .default

       enum Theme {
           case system  // Follow iOS setting
           case light
           case dark
       }

       enum ColorScheme {
           case `default`
           case highContrast
           // Future: squirrel personas
       }
   }
   ```

2. **Create Color Extensions**:
   ```swift
   extension Color {
       static let theme = ThemeColors()
   }

   struct ThemeColors {
       let primary = Color("Primary")
       let secondary = Color("Secondary")
       let textPrimary = Color("TextPrimary")
       // ... etc
   }
   ```

3. **Replace Hardcoded Colors**:
   ```swift
   // Before:
   .background(Color.blue.opacity(0.1))

   // After:
   .background(Color.theme.primaryBackground)
   ```

### Phase 3: Testing & Validation
1. **Contrast Validation**: Run accessibility audit
2. **Visual QA**: Test all screens in light/dark mode
3. **Device Testing**: Verify on actual devices

---

## Design Tool Requirements

### Figma/Sketch Setup

**Color Palette Template**:
- Create swatches for all semantic colors
- Include light/dark mode variants
- Label with exact hex codes
- Add contrast ratio annotations

**Component Library**:
- Button styles (primary, secondary, tertiary)
- Badge/pill components
- Card/surface styles
- Input field styles

**Accessibility Annotations**:
- Mark contrast ratios on all text/background pairs
- Highlight any failing combinations
- Document color purposes

---

## Contrast Validation Checklist

Test these combinations for WCAG AA (4.5:1 minimum):

### Text on Backgrounds
- [ ] Primary text on primary background
- [ ] Secondary text on primary background
- [ ] White text on primary brand color
- [ ] White text on success color
- [ ] White text on error color
- [ ] Black text on warning color

### UI Components
- [ ] Selected badge text on badge background
- [ ] Tab bar icon on background
- [ ] FAB icon on FAB background
- [ ] Input text on input background
- [ ] Button text on button background

### Interactive States
- [ ] Hover state contrast
- [ ] Pressed state contrast
- [ ] Disabled state (3:1 minimum)
- [ ] Focus indicator contrast

---

## Deliverables Needed

### From Designer/Design Tool

1. **Color Palette Specification**
   - Excel/CSV with all hex codes
   - Light and dark mode variants
   - Contrast ratios documented

2. **Asset Catalog Export**
   - Xcode .colorset files ready to import
   - Or hex values for manual entry

3. **Style Guide Document**
   - Visual examples of all components
   - Usage guidelines
   - Do's and Don'ts

### From Developer (Implementation)

1. **ThemeManager Service**
2. **Color Extension/Token System**
3. **Migration of Hardcoded Colors**
4. **Accessibility Validation Report**

---

## Quick Start Guide

### For Designer:

1. Open [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
2. Test primary brand color (#3B82F6) against white
3. Adjust until 4.5:1 achieved for both light/dark modes
4. Repeat for all accent colors
5. Export as Asset Catalog or provide hex codes

### For Developer:

1. Receive color specifications
2. Create Asset Catalog structure
3. Add .colorset files
4. Create Color extension
5. Find/replace hardcoded colors:
   ```bash
   # Search for patterns like:
   grep -r "Color.blue.opacity" Sources/
   grep -r ".background(Color\." Sources/
   grep -r ".foregroundColor(Color\." Sources/
   ```
6. Run accessibility audit to verify improvements

---

## Timeline Estimate

**Asset Creation**: 1-2 days (design)
**Implementation**: 2-3 days (development)
**Testing & Fixes**: 1 day
**Total**: 4-6 days

---

## References

- **WCAG Contrast Guidelines**: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **SF Symbols**: https://developer.apple.com/sf-symbols/
- **Xcode Asset Catalogs**: https://developer.apple.com/documentation/xcode/asset-management

---

**Status**: Ready for design asset creation
**Blocking Items**: None - can start immediately
**Next Steps**: Define color palette, test contrast, export assets
