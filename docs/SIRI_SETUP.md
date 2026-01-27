# Siri Integration Setup Guide

This guide explains how to enable and test Siri functionality for the PersonalAI app.

## Current Status

✅ **Code Implementation Complete**
- App Intents framework integrated
- ThoughtAppEntity for Spotlight/Siri/Shortcuts
- CaptureThoughtIntent for voice capture
- SearchThoughtsIntent for advanced search
- ReviewIntent for filtered reviews
- AppShortcutsProvider registered in app

⚠️ **Manual Configuration Required**
The following steps must be completed in Xcode to enable Siri:

## Required Setup Steps

### 1. Add Siri Capability in Xcode

**In Xcode:**
1. Open `PersonalAI.xcodeproj`
2. Select the **PersonalAI** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Siri**

This adds the `com.apple.developer.siri` entitlement to your app.

### 2. Verify App Intents Metadata

App Intents requires metadata extraction during build. This should happen automatically, but verify:

**In Xcode Build Log:**
```
Extracting app intents metadata...
Generating Shortcuts metadata...
```

If you don't see these messages, the intents won't be discoverable by Siri.

### 3. Test on Physical Device

**IMPORTANT:** Siri integration does NOT work in the iOS Simulator. You must test on a real device.

**Steps:**
1. Connect your iPhone/iPad
2. Build and run the app on the device
3. Install the app completely (let it finish launching)
4. Wait 30-60 seconds for iOS to index the app intents

### 4. Enable Siri Access (First Time)

If this is the first time using Siri with the app:

1. Open **Settings** → **Siri & Search**
2. Find **PersonalAI** in the app list
3. Enable:
   - ✅ Learn from this App
   - ✅ Show App in Search
   - ✅ Show Siri Suggestions

## Testing Siri Integration

### Test 1: Voice Capture
```
"Hey Siri, capture a thought in PersonalAI"
```

Siri should respond with a prompt to speak your thought, then confirm capture.

**Variations to try:**
- "Save a note in PersonalAI"
- "Remember something in PersonalAI"

### Test 2: Search
```
"Hey Siri, search PersonalAI for work thoughts"
```

Siri should return matching thoughts from your database.

### Test 3: Review
```
"Hey Siri, review my thoughts from today"
```

Should open the app with filtered view showing today's thoughts.

## Shortcuts App Integration

After installing the app on device:

1. Open the **Shortcuts** app
2. Tap **+** to create new shortcut
3. Search for **"PersonalAI"**
4. You should see:
   - Capture Thought
   - Search Thoughts
   - Review Thoughts

You can create custom shortcuts combining these with other actions.

## Troubleshooting

### "I can't find the app in Siri"
**Solution:**
- Ensure Siri capability is added in Xcode
- Rebuild and reinstall the app
- Wait 60 seconds after installation
- Check Settings → Siri & Search → PersonalAI is enabled

### "Siri says it can't do that"
**Solution:**
- App must be running on physical device (not simulator)
- Check that metadata extraction ran during build
- Verify app is signed with valid provisioning profile

### "App Intents don't appear in Shortcuts app"
**Solution:**
- Check build log for "Extracting app intents metadata"
- Ensure AppIntents files are in the target membership
- Clean build folder (Product → Clean Build Folder)
- Rebuild and reinstall

### "Siri doesn't understand my custom phrases"
**Solution:**
- Custom phrases are defined in `ThoughtAppShortcuts`
- Siri learns from actual usage patterns
- Try the exact phrases first:
  - "Capture a thought in PersonalAI"
  - "Save a note in PersonalAI"
  - "Remember something in PersonalAI"

## Advanced: Custom Shortcuts

### Create Morning Routine Shortcut
1. Open Shortcuts app
2. Create new shortcut
3. Add **Review Thoughts** (from PersonalAI)
   - Date Range: Yesterday
   - Type Filter: Reminder
4. Add **Speak Text** (from Shortcuts)
5. Name it "Morning Review"

Now say: **"Hey Siri, Morning Review"**

### Create Quick Capture Widget
1. Create shortcut with **Capture Thought**
2. Add to Home Screen as widget
3. One tap to capture thoughts

## Debugging

### Check App Intent Registration
Run this in terminal to verify intents are registered:
```bash
xcrun devicectl device info appintents --device <device-id>
```

### View Siri Suggestions
Settings → Siri & Search → PersonalAI should show:
- Suggested shortcuts based on usage
- App capabilities that Siri can perform

## iOS 26 Specific Notes

PersonalAI uses the modern AppIntents framework (iOS 16+):
- ✅ No INIntent subclasses needed
- ✅ No Intents extension required
- ✅ Native Swift implementation
- ✅ @MainActor concurrency safety
- ✅ Sendable conformance

The app is fully compatible with iOS 26's latest App Intents features.

## Next Steps After Setup

Once Siri is working:

1. **Monitor Usage**: Check Settings → Siri & Search to see which shortcuts users invoke
2. **Add More Intents**: Extend CaptureThoughtIntent with more parameters
3. **Focus Filters**: Thoughts can integrate with iOS Focus modes
4. **Widgets**: Create Shortcuts widgets for quick access

## Files Reference

**App Intents Implementation:**
- `Sources/AppIntents/ThoughtAppEntity.swift` - Core entity
- `Sources/AppIntents/CaptureThoughtIntent.swift` - Voice capture
- `Sources/AppIntents/SearchThoughtsIntent.swift` - Search
- `Sources/AppIntents/ReviewIntent.swift` - Review with filters
- `Sources/PersonalAIApp.swift` - App shortcuts registration

**Documentation:**
- `docs/APP_INTENTS.md` - Complete API reference
- `docs/SIRI_SETUP.md` - This guide

## Support

If Siri integration still doesn't work after following these steps:
1. Check Xcode build logs for errors
2. Verify device is running iOS 16 or later
3. Ensure app has valid code signing
4. Try deleting app and reinstalling
