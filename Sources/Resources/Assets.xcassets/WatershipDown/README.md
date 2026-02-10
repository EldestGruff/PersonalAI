# Watership Down Theme Assets

This folder contains placeholder asset configurations for the Watership Down theme.

## Assets Needed

Replace these placeholder configurations with actual assets:

### Required Assets:
1. **squirrel_mascot.imageset/** - Squirrel holding teal gem (brand mascot)
2. **gem_icon.imageset/** - Teal gemstone icon for buttons/tabs
3. **gem_button.imageset/** - Illustrated gem button (or use programmatic)
4. **tab_squirrel.imageset/** - Squirrel icon for home tab

### Recommended Assets:
5. **parchment_texture.imageset/** - Subtle paper grain overlay (512-1024px, tileable PNG)
6. **watercolor_wash.imageset/** - Organic paint splatter for category accents

### Optional Polish:
7. **empty_state_*.imageset/** - Squirrel illustrations for empty states
8. **gem_sparkle_animation/** - Lottie JSON for button tap animation

## Asset Specifications

### Image Assets:
- **Format**: PDF (vector) or PNG @1x, @2x, @3x
- **Color Space**: sRGB
- **Transparency**: Yes (where appropriate)

### Vector Assets (Preferred):
- **Format**: PDF with "Preserve Vector Data" enabled
- **Rendering**: Template (for tintable icons) or Original

### Textures:
- **Format**: PNG with alpha channel
- **Size**: 512x512 or 1024x1024 (tileable)
- **Opacity**: Design at 100%, will be applied at 10-20% in code

## Integration

Assets are referenced in code as:
```swift
Image("WatershipDown/squirrel_mascot")
Image("WatershipDown/gem_icon")
    .renderingMode(.template)
    .foregroundColor(theme.primaryColor)
```

## Status

🚧 **PLACEHOLDER** - All assets currently using programmatic fallbacks
✅ Theme colors and styling are functional without assets
📦 Add assets incrementally as they become available
