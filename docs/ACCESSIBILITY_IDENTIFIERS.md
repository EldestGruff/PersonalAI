# Accessibility Identifiers Reference

This document lists all accessibility identifiers added to enable UI testing.

## Purpose

Accessibility identifiers allow UI tests to locate and interact with specific elements in the app. They are invisible to users but critical for automated testing infrastructure.

## Naming Convention

Identifiers use camelCase with descriptive names that indicate:
1. The element type (Button, TextField, Toggle)
2. The action or purpose
3. The screen context (when not obvious)

Example: `addThoughtButton`, `searchTextField`, `autoClassificationToggle`

## Complete Identifier List

### CaptureScreen.swift

Interactive elements for capturing new thoughts.

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `captureThoughtTextField` | TextEditor | Main text input for thought content |
| `voiceInputToggleButton` | Button | Toggle between keyboard and voice input |
| `captureThoughtButton` | Button | Submit thought to be saved |

### BrowseScreen.swift

Main thought browsing and filtering interface.

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `addThoughtButton` | Button | Floating action button to create new thought |
| `filterButton` | Button | Open filter sheet to filter thoughts |

### SearchScreen.swift

Search interface for finding thoughts.

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `searchTextField` | TextField | Search query input field |
| `clearSearchButton` | Button | Clear search query |

### DetailScreen.swift

Individual thought detail view with editing and actions.

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `deleteThoughtButton` | Button | Delete the current thought |
| `editThoughtButton` | Button | Enter edit mode |
| `doneEditingButton` | Button | Save changes and exit edit mode |
| `cancelEditingButton` | Button | Cancel edit mode without saving |
| `refreshLocationButton` | Button | Refresh location context |
| `energyDebugButton` | Button | Toggle energy breakdown debug view |
| `createReminderButton` | Button | Create system reminder (conditional) |
| `addToCalendarButton` | Button | Add event to calendar (conditional) |
| `helpfulFeedbackButton` | Button | Mark classification as helpful |
| `partiallyHelpfulFeedbackButton` | Button | Mark classification as okay |
| `notHelpfulFeedbackButton` | Button | Mark classification as not helpful |

**Note**: `createReminderButton` and `addToCalendarButton` only appear when thought is classified as reminder or event type.

### TagInputView.swift

Tag management component (used in multiple screens).

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `addTagTextField` | TextField | Input field for new tag |
| `addTagButton` | Button | Add the entered tag |

**Note**: Tag removal buttons have dynamic identifiers based on tag content.

### SettingsScreen.swift

App settings and configuration.

| Identifier | Element | Purpose |
|-----------|---------|---------|
| `enableAllPermissionsButton` | Button | Request all permissions at once |
| `autoClassificationToggle` | Toggle | Enable/disable auto-classification |
| `contextEnrichmentToggle` | Toggle | Enable/disable context gathering |
| `autoTaggingToggle` | Toggle | Enable/disable auto-tagging |
| `autoCreateRemindersToggle` | Toggle | Enable/disable auto-reminder creation |
| `autoSyncToggle` | Toggle | Enable/disable auto-sync (future) |

#### PermissionRow Identifiers

Permission buttons use dynamic identifiers based on permission label:

| Permission | Enable Button | Re-request Button |
|-----------|---------------|-------------------|
| Health Data | `HealthDataEnableButton` | `HealthDataRerequestButton` |
| Location | `LocationEnableButton` | `LocationRerequestButton` |
| Calendar & Reminders | `CalendarRemindersEnableButton` | `CalendarRemindersRerequestButton` |
| Speech Recognition | `SpeechRecognitionEnableButton` | `SpeechRecognitionRerequestButton` |
| Contacts | `ContactsEnableButton` | `ContactsRerequestButton` |

**Generation Logic**: Label with spaces and ampersands removed
- "Health Data" → `HealthDataEnableButton`
- "Calendar & Reminders" → `CalendarRemindersEnableButton`

## Total Count

- **Fixed identifiers**: 24
- **Dynamic identifiers**: 10 (5 permissions × 2 states each)
- **Total**: 34 accessibility identifiers

## Usage in UI Tests

```swift
// Example: Test thought capture flow
let app = XCUIApplication()
app.launch()

// Tap FAB to open capture screen
app.buttons["addThoughtButton"].tap()

// Enter thought content
let textField = app.textViews["captureThoughtTextField"]
textField.tap()
textField.typeText("Meeting with product team at 2pm")

// Submit thought
app.buttons["captureThoughtButton"].tap()

// Verify thought appears in browse screen
XCTAssertTrue(app.staticTexts["Meeting with product team"].exists)
```

```swift
// Example: Test search functionality
let app = XCUIApplication()
app.launch()

// Navigate to search tab
app.tabBars.buttons["Search"].tap()

// Enter search query
let searchField = app.textFields["searchTextField"]
searchField.tap()
searchField.typeText("meeting")

// Verify results appear
XCTAssertTrue(app.cells.count > 0)

// Clear search
app.buttons["clearSearchButton"].tap()
XCTAssertEqual(searchField.value as? String, "")
```

```swift
// Example: Test settings toggles
let app = XCUIApplication()
app.launch()

// Navigate to settings
app.tabBars.buttons["Settings"].tap()

// Toggle auto-classification
let classificationToggle = app.switches["autoClassificationToggle"]
let initialState = classificationToggle.isOn
classificationToggle.tap()
XCTAssertNotEqual(classificationToggle.isOn, initialState)
```

## Best Practices

1. **Stability**: Identifiers should never change once established
2. **Uniqueness**: Each identifier must be unique within the app
3. **Descriptive**: Names should clearly indicate element purpose
4. **Context-Free**: Avoid embedding state or data in identifiers
5. **English Only**: Use English for consistency

## Maintenance

When adding new interactive elements:

1. Choose a descriptive, unique identifier
2. Add `.accessibilityIdentifier("identifierName")` modifier
3. Update this document with the new identifier
4. Add corresponding UI test cases

## Related Documentation

- **Accessibility Labels**: See `docs/ACCESSIBILITY_AUDIT.md` for VoiceOver labels
- **UI Testing**: See test targets for example usage
- **WCAG Guidelines**: See Issue #19 for accessibility standards

---

**Last Updated**: 2026-01-27
**Issue**: #19 - Accessibility Improvements
**Status**: Complete - All main user flows covered
