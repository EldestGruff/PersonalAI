#!/bin/bash
# Script to add Smart Resurfacing files to Xcode project
# Run this from the project root directory

echo "📦 Adding Smart Resurfacing files to Xcode project..."

# Files to add
FILES=(
    "Sources/Services/Intelligence/SemanticSearchService.swift"
    "Sources/Services/Intelligence/SmartInsightsService.swift"
)

echo ""
echo "Files to add:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (NOT FOUND)"
    fi
done

echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo "1. Open PersonalAI.xcodeproj in Xcode"
echo "2. In Project Navigator, right-click 'Sources/Services/Intelligence/'"
echo "3. Select 'Add Files to PersonalAI'"
echo "4. Select these files:"
echo "   - SemanticSearchService.swift"
echo "   - SmartInsightsService.swift"
echo "5. Ensure 'PersonalAI' target is checked"
echo "6. Click 'Add'"
echo "7. Build (⌘B) to verify"
echo ""
echo "Alternatively, you can drag and drop the files from Finder into Xcode."
echo ""
