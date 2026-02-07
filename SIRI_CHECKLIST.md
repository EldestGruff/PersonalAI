# Siri Integration Checklist

Quick reference for enabling Siri functionality in STASH.

## ✅ Code Complete (Already Done)

- [x] App Intents framework integrated
- [x] ThoughtAppEntity.swift implemented
- [x] CaptureThoughtIntent.swift implemented
- [x] SearchThoughtsIntent.swift implemented
- [x] ReviewIntent.swift implemented
- [x] AppShortcutsProvider registered in STASHApp.swift
- [x] Siri entitlement added to STASH.entitlements
- [x] All code implementation complete

## ⚠️ Manual Xcode Configuration Required

### Step 1: Update Provisioning Profile (Required for Siri)
**Location:** Xcode → Signing & Capabilities

The Siri entitlement has been added, but your provisioning profile needs to be regenerated:

- [ ] Open STASH.xcodeproj in Xcode
- [ ] Select STASH target
- [ ] Click "Signing & Capabilities" tab
- [ ] You'll see "Siri" capability listed (already added via entitlements)
- [ ] Under "Signing", select your Team/Apple ID
- [ ] Xcode will automatically regenerate the provisioning profile with Siri support
- [ ] If you see errors about provisioning profile, click "Try Again" or reconnect your device
- [ ] **Note:** Requires an active Apple Developer account (free or paid)

### Step 2: Verify Build Metadata
**Location:** Xcode → Build Log

- [ ] Clean build folder (⌘⇧K)
- [ ] Build for device (⌘B)
- [ ] Check build log for:
  ```
  Extracting app intents metadata...
  Generating Shortcuts metadata...
  ```
- [ ] If missing, ensure AppIntents files are in target membership

### Step 3: Device Testing
**Location:** Physical iPhone/iPad (NOT Simulator)**

- [ ] Connect real iOS device
- [ ] Build and run app on device
- [ ] Let app fully launch and initialize
- [ ] Wait 60 seconds for iOS to index intents
- [ ] Keep app installed (don't delete)

### Step 4: Enable Siri Permissions
**Location:** iOS Settings on device**

- [ ] Open Settings → Siri & Search
- [ ] Scroll to find "STASH"
- [ ] Enable "Learn from this App"
- [ ] Enable "Show App in Search"
- [ ] Enable "Show Siri Suggestions"

## 🧪 Verification Tests

### Test 1: Shortcuts App
- [ ] Open Shortcuts app on device
- [ ] Tap "+" to create new shortcut
- [ ] Search for "STASH"
- [ ] Verify these intents appear:
  - Capture Thought
  - Search Thoughts
  - Review Thoughts

### Test 2: Voice Commands
Try each of these with Siri:

- [ ] "Hey Siri, capture a thought in STASH"
- [ ] "Hey Siri, save a note in STASH"
- [ ] "Hey Siri, search STASH for work"
- [ ] "Hey Siri, review my thoughts from today"

### Test 3: Spotlight Search
- [ ] Create a thought in the app
- [ ] Wait 30 seconds
- [ ] Pull down on home screen (Spotlight)
- [ ] Type keywords from your thought
- [ ] Verify thought appears in search results

## 🐛 If Something Doesn't Work

### Siri doesn't recognize commands:
1. Double-check Siri capability is added
2. Rebuild app completely
3. Reinstall on device
4. Wait 60 seconds
5. Verify Settings → Siri & Search → STASH is ON

### Shortcuts app shows no intents:
1. Check build log for metadata extraction
2. Verify AppIntents files have target membership
3. Clean build (⌘⇧K) and rebuild
4. Delete app from device and reinstall

### App crashes when using Siri:
1. Check device console logs
2. Verify ThoughtRepository.shared is accessible
3. Test intents work when called from Shortcuts app first

## 📝 Notes

- **Simulator:** Siri integration does NOT work in iOS Simulator
- **Device Only:** Must test on physical iPhone/iPad
- **Wait Time:** iOS needs 30-60 seconds to index new intents
- **Siri Learning:** Custom phrases improve with usage over time

## 📚 Documentation

- **Setup Guide:** docs/SIRI_SETUP.md (detailed instructions)
- **API Reference:** docs/APP_INTENTS.md (intent parameters)
- **Code:** Sources/AppIntents/*.swift (implementation)

## ✅ When Complete

You'll know Siri integration is working when:
- Siri responds to "capture a thought in STASH"
- Shortcuts app shows STASH intents
- Spotlight search finds your thoughts
- Settings shows STASH under Siri & Search

---

**Issue:** #17 - App Intents for Siri and Shortcuts
**Status:** Code complete, manual configuration required
**Platform:** iOS 16+, tested on iOS 26
