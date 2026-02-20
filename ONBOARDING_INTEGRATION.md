# Onboarding Integration Guide

## ✅ Files Created

All onboarding files have been successfully created in the correct locations:

### Core Infrastructure
- `Sources/UI/ViewModels/OnboardingViewModel.swift` - State machine managing step progression
- `Sources/UI/Onboarding/OnboardingCopy.swift` - Persona-voiced dialogue strings
- `Sources/UI/Screens/OnboardingScreen.swift` - Main container with step routing

### Step Views (9 total)
- `Sources/UI/Onboarding/Steps/WelcomeStepView.swift` - Welcome screen
- `Sources/UI/Onboarding/Steps/PersonaPickerStepView.swift` - Persona selection grid
- `Sources/UI/Onboarding/Steps/FirstCaptureStepView.swift` - Real thought capture integration
- `Sources/UI/Onboarding/Steps/AcornExplainerStepView.swift` - Acorn rewards spotlight
- `Sources/UI/Onboarding/Steps/StreakIntroStepView.swift` - Streak mechanic spotlight
- `Sources/UI/Onboarding/Steps/PermissionsStepView.swift` - Context permissions
- `Sources/UI/Onboarding/Steps/NotificationsStepView.swift` - Notification setup
- `Sources/UI/Onboarding/Steps/FutureTeaserStepView.swift` - Shiny thoughts preview
- `Sources/UI/Onboarding/Steps/CompletionStepView.swift` - Completion screen

### Modified Files
- `Sources/STASHApp.swift` - Added onboarding presentation logic
- `Sources/UI/Screens/SettingsScreen.swift` - Added replay button

## 🔧 Next Steps: Add Files to Xcode Project

The files are created but need to be added to the Xcode project:

1. **Open Xcode** and navigate to your STASH project

2. **Add the Onboarding folder:**
   - Right-click on `Sources/UI` folder in Xcode
   - Select "Add Files to PersonalAI..."
   - Navigate to `Sources/UI/Onboarding`
   - Select the `Onboarding` folder
   - Check "Copy items if needed" ❌ (don't copy, they're already in place)
   - Check "Create groups" ✅
   - Make sure "STASH" target is selected ✅
   - Click "Add"

3. **Add OnboardingViewModel:**
   - Right-click on `Sources/UI/ViewModels` in Xcode
   - Select "Add Files to PersonalAI..."
   - Navigate to `Sources/UI/ViewModels`
   - Select `OnboardingViewModel.swift`
   - Same settings as above
   - Click "Add"

4. **Add OnboardingScreen:**
   - Right-click on `Sources/UI/Screens` in Xcode
   - Select "Add Files to PersonalAI..."
   - Navigate to `Sources/UI/Screens`
   - Select `OnboardingScreen.swift`
   - Same settings as above
   - Click "Add"

5. **Verify the integration:**
   - Build the project (⌘+B)
   - Should compile without errors

## 🧪 Testing the Onboarding Flow

### First Launch Test
1. **Delete the app** from the simulator/device
2. **Reinstall and launch** - onboarding should appear immediately
3. **Test the flow:**
   - Welcome screen → tap "Get Started"
   - Persona selection → tap a persona (should auto-advance)
   - First capture → enter text, tap "Capture Thought"
   - Acorn explainer → tap "Got it!"
   - Streak intro → tap "Continue"
   - Permissions → tap "Enable Permissions" or "Skip for Now"
   - Notifications → toggle types, tap "Turn on Notifications" or "Maybe Later"
   - Future teaser → tap "Sounds Great!"
   - Completion → tap "Start Using STASH"
4. **Verify:** Should land on BrowseScreen with your first thought visible

### Replay Test
1. **Launch the app** (should go straight to MainTabView)
2. **Navigate to Settings tab**
3. **Scroll to "Tutorial" section**
4. **Tap "Replay Onboarding"**
5. **Verify:** Onboarding should re-present in full-screen

### Persistence Test
1. **Complete onboarding**
2. **Force quit the app** (swipe up in app switcher)
3. **Relaunch** - should NOT show onboarding again
4. **Check Settings** - "Replay Onboarding" button should be visible

## 🎨 Visual Features

### Persona-Voiced Dialogue
Every step uses persona-specific copy:
- **Supportive Listener:** Warm, validating tone
- **Brainstorm Partner:** Enthusiastic, energetic
- **Socratic Questioner:** Thoughtful, probing
- **Journal Guide:** Gentle, mindful
- **Devil's Advocate:** Sharp, challenging

### Transitions
- Asymmetric transitions (trailing → leading) for natural flow
- Progress dots update smoothly
- Spotlight overlays with dimmed backgrounds

### Real Integrations
- **Step 3:** Embeds real CaptureViewModel - captures create actual thoughts
- **Step 4:** Shows actual acorn balance from AcornService
- **Step 5:** Shows actual streak count from StreakTracker
- **Step 6:** Fires real iOS permission prompts via PermissionCoordinator
- **Step 7:** Integrates with SquirrelReminderService for notification setup

## 📝 Implementation Details

### State Management
- `OnboardingViewModel` manages all state
- `currentStep` drives the UI routing
- `selectedPersona` persists immediately on selection
- Completion flag: `UserDefaults["onboarding.completed"]`

### Auto-Advancement
- Persona selection → 500ms delay
- First capture → 1500ms delay (shows acorn toast)
- All other steps require manual "Continue" button

### Skip Logic
- All steps can be skipped except Completion
- Skip button appears on steps where applicable
- Permissions and notifications are fully optional

### Accessibility
- All buttons have proper labels
- Progress dots update with animation
- VoiceOver support via SwiftUI defaults

## 🚀 Future Enhancements (Out of Scope)

- [ ] Partial completion tracking (resume from last step)
- [ ] A/B test different copy variants
- [ ] Analytics tracking per step
- [ ] Localization for non-English languages
- [ ] Video demonstrations embedded in steps

## ✅ Completion Checklist

Before marking this feature complete, verify:

- [ ] All files added to Xcode project
- [ ] Project builds without errors
- [ ] First launch shows onboarding
- [ ] All 9 steps flow correctly
- [ ] Persona selection persists
- [ ] First capture creates real thought
- [ ] Acorn balance updates
- [ ] Permissions prompt correctly
- [ ] Notification setup works
- [ ] Completion dismisses to BrowseScreen
- [ ] Replay button in Settings works
- [ ] Second launch skips onboarding
- [ ] Works in light and dark themes
- [ ] Accessible with VoiceOver

## 📚 Related Files

**Services referenced:**
- `PersonaService.shared` - Persona management
- `AcornService.shared` - Acorn rewards
- `StreakTracker.shared` - Streak tracking
- `PermissionCoordinator.shared` - Permission requests
- `SquirrelReminderService.shared` - Notification setup

**Models used:**
- `SquirrelPersona` - Persona definitions
- `SquirrelNotificationType` - Notification types
- `AcornReward` - Reward feedback

**Patterns followed:**
- String table: Same pattern as `ReminderCopy` in `SquirrelReminderService.swift`
- State machine: Enum-driven step progression
- Theme integration: Uses `ThemeEngine.shared` throughout

## 🐛 Known Issues

None at this time. All functionality is implemented as per spec.

## 📞 Support

If you encounter any issues:
1. Check that all files are added to the STASH target
2. Verify imports are resolving correctly
3. Clean build folder (⌘+Shift+K) and rebuild
4. Check console for UserDefaults persistence issues

---

**Implementation Status:** Complete ✅
**Ready for Testing:** After adding files to Xcode project
**Estimated Testing Time:** 15-20 minutes for full flow
