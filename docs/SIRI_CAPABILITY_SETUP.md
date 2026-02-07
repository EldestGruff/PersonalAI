# Siri Capability Setup

## Current Status

The Siri capability is **temporarily disabled** in `STASH.entitlements` to allow development builds while waiting for Apple Developer Program enrollment to complete.

## Why is Siri Disabled?

Personal development teams (free Apple ID) **cannot** use the Siri capability. You need a paid Apple Developer Program membership ($99/year) to enable Siri App Intents.

**Error message without enrollment:**
```
Cannot create a iOS App Development provisioning profile for "com.personalai.STASH".
Personal development teams do not support the Siri capability.
```

## What Still Works Without Siri

All core functionality works fine:
- ✅ Foundation Models on-device AI classification
- ✅ HealthKit State of Mind integration
- ✅ Swift Charts insights visualization
- ✅ Context gathering (location, calendar, activity)
- ✅ Core Data persistence
- ✅ All UI screens and navigation

## What's Missing Without Siri

The App Intents functionality won't work:
- ❌ "Hey Siri, capture a thought" voice commands
- ❌ Shortcuts app integration
- ❌ Spotlight suggestions

The code is fully implemented (`Sources/AppIntents/`), just not enabled in the build.

## How to Re-Enable Siri (After Enrollment)

Once your Apple Developer enrollment is approved:

1. **Uncomment the Siri entitlement:**

   Edit `STASH.entitlements`:
   ```xml
   <key>com.apple.developer.siri</key>
   <true/>
   ```

2. **Update Bundle Identifier (if needed):**

   In Xcode:
   - Select the STASH target
   - Go to Signing & Capabilities
   - Ensure your Team is selected
   - Bundle ID: `com.personalai.STASH`

3. **Verify Siri capability:**

   In Xcode → Signing & Capabilities tab:
   - Click "+ Capability"
   - Add "Siri" if not already present
   - Xcode will create the provisioning profile automatically

4. **Test App Intents:**
   ```bash
   # After building with Siri enabled
   # On device or simulator, try:
   "Hey Siri, capture a thought"
   "Hey Siri, capture thought about meeting notes"
   ```

## App Intents Implementation

The App Intents are already fully implemented:

- **CaptureThoughtIntent** (`Sources/AppIntents/CaptureThoughtIntent.swift`)
  - Phrase: "Capture thought [content]"
  - Creates thought with AI classification
  - Includes context gathering

- **ReviewIntent** (`Sources/AppIntents/ReviewIntent.swift`)
  - Phrase: "Review my thoughts"
  - Opens app to browse screen

- **ThoughtAppShortcuts** (`Sources/AppIntents/ThoughtAppShortcuts.swift`)
  - Registers shortcuts with Siri
  - Updates parameters dynamically

## Timeline

1. **Now (Enrollment Pending):** Siri disabled, all other features work
2. **After Enrollment Approved:** Re-enable Siri in 5 minutes
3. **First Build After:** Xcode creates provisioning profile automatically
4. **Launch:** Full Siri integration ready

## Questions?

If you have issues after re-enabling Siri:
1. Clean build folder (⇧⌘K)
2. Delete derived data
3. Restart Xcode
4. Check Signing & Capabilities has your team selected
