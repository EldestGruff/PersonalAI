# STASH Brand Assets

Placeholder SVG assets for the STASH squirrel-sona branding system.

## Files

### `squirrel-icon.svg`
Simple geometric squirrel mascot in burnt orange (#FF6B35). Suitable for standalone icon use.

**Features:**
- Minimalist geometric shapes
- Burnt orange gradient
- 200x200 viewBox (scales to any size)
- Suitable for app icons, avatars, mascot representations

### `glowing-gem.svg`
Faceted gem with cyan glow effect (#00D9FF). Represents the "shiny" objects to stash.

**Features:**
- Faceted diamond shape
- Cyan gradient with glow filter
- Radial aura effect
- 200x200 viewBox
- Suitable for UI accents, notification icons

### `stash-logo.svg`
Combined logo with squirrel reaching for glowing gem on dark background.

**Features:**
- Squirrel positioned left, reaching right
- Glowing gem positioned where squirrel reaches
- Dark grey background (#2D2D2D)
- 400x400 viewBox
- Suitable for app launch screen, about page, branding

## Color Palette

- **Primary (Squirrel)**: #FF6B35 (Burnt Orange)
- **Secondary (Gem)**: #00D9FF (Cyan/Electric Blue)
- **Background**: #2D2D2D (Dark Grey)
- **Accents**: #FFB399 (Light Orange), #00F5FF (Bright Cyan)

## Usage in SwiftUI

```swift
// Load as Image (requires conversion to PNG/PDF)
Image("stash-logo")
    .resizable()
    .aspectRatio(contentMode: .fit)

// Or render directly if converted to SwiftUI Shapes
// (See Theme System implementation in #10)
```

## Next Steps

These are **placeholder assets** created with basic SVG code. For production:

1. **Phase 5 Refinement**: Use design tools (Sketch, Figma, Illustrator) to:
   - Add more detail and personality
   - Create multiple poses/expressions
   - Develop animation assets
   - Generate all required icon sizes

2. **Export Formats**: Convert to:
   - PNG (1x, 2x, 3x for iOS)
   - PDF (vector for Xcode)
   - SwiftUI Shape code (for theme system)

3. **Asset Catalog**: Add to `Assets.xcassets/` with proper naming:
   - `SquirrelIcon`
   - `GlowingGem`
   - `STASHLogo`

## Related Issues

- #10: Theme System Architecture
- #14: Brand Terminology & Logo Integration

---

*Generated: Phase 4 - Placeholder assets for early development*
