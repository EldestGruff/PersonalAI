# Troubleshooting Guide

## Storage Error on Capture Screen

### Symptom
Red error banner appears when trying to capture a thought:
```
Storage error - please try again
Try closing and reopening the app
```

### Root Cause
This error typically occurs when:
1. **Core Data migration issue** - The data model changed (we added `stateOfMind` to Context)
2. **Simulator sandbox issue** - Old data incompatible with new schema
3. **Permission issue** - HealthKit or other framework not authorized

### Solution

**Quick Fix (Recommended):**
1. **Delete the app** from the simulator (long press app icon → Remove App)
2. **Clean build folder** in Xcode: Product → Clean Build Folder (⇧⌘K)
3. **Rebuild and run** (⌘R)

This resets the Core Data store with the new schema.

**Alternative Fix:**
1. Close Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/STASH-*
   ```
3. Reopen Xcode and rebuild

### Why This Happens

We recently added the `stateOfMind` field to the Context model for HealthKit State of Mind integration. Core Data stores Context as JSON, and old stored thoughts don't have this field, causing serialization issues.

### Prevention

For future schema changes:
- Add Core Data migration logic
- Make new fields optional with defaults
- Test on clean install before pushing

### If Problem Persists

If you still see the error after deleting the app:

1. **Check Console Logs:**
   - Open Console.app
   - Filter for "STASH"
   - Look for the actual error message

2. **Check HealthKit Authorization:**
   - Settings → Privacy & Security → Health → STASH
   - Ensure all permissions are granted

3. **Report the Issue:**
   - Note the exact steps to reproduce
   - Check Console.app for error details
   - Share the console log

## Other Common Issues

### "Apple Intelligence not available"

**Symptom:** App shows that Foundation Models is unavailable

**Solution:**
- Requires iOS 26.0+ with Apple Intelligence
- Only works on iPhone 15 Pro or newer
- Simulator needs to be iPhone 17 with iOS 26.2

### Build Failures

**Symptom:** Xcode shows compilation errors

**Solution:**
1. Clean build folder (⇧⌘K)
2. Delete derived data
3. Restart Xcode
4. Rebuild

### Siri Not Working

**Symptom:** "Hey Siri, capture a thought" doesn't work

**Reason:** Siri capability temporarily disabled until Apple Developer enrollment completes

**Fix:** See `docs/SIRI_CAPABILITY_SETUP.md`

### Charts Not Showing Data

**Symptom:** Insights screen shows empty charts

**Reason:** Need at least 1-2 thoughts captured per chart

**Fix:** Capture a few test thoughts first
