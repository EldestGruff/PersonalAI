# Sentiment Classification Calibration

## Overview

The sentiment classifier uses Foundation Models (iOS 26) to analyze the emotional tone of thoughts. It's designed to be **conservative** and avoid over-classifying neutral content as negative.

## Design Philosophy

**Default to Neutral**: Most personal thoughts are factual, observational, or planning-oriented. The classifier errs on the side of neutral unless there's clear emotional content.

## Sentiment Scale

The AI outputs a score from **-1.0 to +1.0**, which is then mapped to 5 categories:

| Score Range | Category | Examples |
|-------------|----------|----------|
| 0.6 to 1.0 | Very Positive | "Thrilled about the promotion!", "Best day ever!" |
| 0.25 to 0.6 | Positive | "Looking forward to the weekend", "That went well" |
| -0.25 to 0.25 | **Neutral** | "Need to finish report", "Meeting at 3pm", "Great, another email" |
| -0.6 to -0.25 | Negative | "Frustrated with the delays", "This is annoying" |
| -1.0 to -0.6 | Very Negative | "Terrible day", "Everything is falling apart" |

## Key Improvements (v2)

### 1. Wider Neutral Band
- **Old**: ±0.3 threshold → too sensitive
- **New**: ±0.25 threshold → more thoughts classified as neutral

### 2. Sarcasm Handling
The AI is explicitly trained to recognize:
- Sarcasm ("Great, another meeting") → Neutral
- Irony and dry humor → Neutral
- Casual informal language → Not inherently negative

### 3. Conservative Bias
Instructions emphasize:
- "When in doubt, lean toward neutral"
- Only negative if expressing **genuine** distress
- Only positive if expressing **genuine** joy

### 4. Context Awareness
The classifier considers:
- Casual vs. emotional language
- Factual statements vs. feelings
- Task-oriented vs. expressive content

## Example Classifications

### Neutral (Should NOT be negative)
- ✅ "Need to finish the report by Friday"
- ✅ "Great, another Zoom call"
- ✅ "Reminder to buy milk"
- ✅ "Weather is cloudy today"
- ✅ "Meeting ran long again"

### Actually Negative
- ❌ "I'm really frustrated with this project"
- ❌ "This is making me anxious"
- ❌ "Feeling overwhelmed and stressed"
- ❌ "Disappointed with the results"

### Actually Positive
- ✅ "So excited for vacation!"
- ✅ "Proud of what the team accomplished"
- ✅ "Love working on this feature"
- ✅ "Feeling grateful today"

## Testing Sentiment

If you notice incorrect classifications, here's how to test:

1. **Capture test thoughts** with known sentiment
2. **Check classification** in thought detail view
3. **Look for patterns** - is it too negative? Too positive?

### Common Issues

**Problem**: Sarcasm marked as negative
- **Example**: "Great, another bug" → Negative (wrong)
- **Should be**: Neutral
- **Fix**: Already addressed in v2 instructions

**Problem**: Tasks marked as negative
- **Example**: "Need to call dentist" → Negative (wrong)
- **Should be**: Neutral
- **Fix**: Already addressed with wider neutral band

## Adjusting the Scale

If you still see issues, you can tune the thresholds in `FoundationModelsClassifier.swift`:

```swift
private func mapSentiment(_ value: Double) -> Sentiment {
    switch value {
    case 0.6...:
        return .very_positive
    case 0.25..<0.6:  // Adjust these values
        return .positive
    case -0.25...0.25:  // Widen for more neutral
        return .neutral
    case -0.6 ..< -0.25:
        return .negative
    default:
        return .very_negative
    }
}
```

## Model Instructions

The AI is given explicit examples of sarcasm and neutral content to avoid misclassification. See `FoundationModelsClassifier.swift` for the full prompt.

## Feedback

If you notice systematic issues with sentiment classification:
1. Note specific examples that were misclassified
2. Identify the pattern (e.g., "all questions marked negative")
3. We can further calibrate the instructions or thresholds
