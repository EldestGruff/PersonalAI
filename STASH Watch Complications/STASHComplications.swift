//
//  STASHComplications.swift
//  STASH Watch Complications
//
//  Issue #58: Apple Watch complications
//
//  Four WidgetKit complication families:
//    - .accessoryCircular  — circular slot (most watch faces)
//    - .accessoryRectangular — wide banner slot (Modular, Infograph Modular)
//    - .accessoryInline    — one-line slot above the time
//    - .accessoryCorner    — curved corner slot (Infograph)
//
//  Tapping any complication opens the Watch app directly.
//  StaticConfiguration used — no per-user widget configuration.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct STASHComplicationEntry: TimelineEntry {
    let date: Date
}

// MARK: - Provider

struct STASHComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> STASHComplicationEntry {
        STASHComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (STASHComplicationEntry) -> Void) {
        // If STASHComplicationEntry ever carries real data, check context.isPreview
        // and return generic placeholder data when true (used in the complication picker).
        completion(STASHComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<STASHComplicationEntry>) -> Void) {
        // Refresh every hour — the complication is static (tap-to-open only)
        let entry = STASHComplicationEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Complication Views

struct STASHCircularView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

struct STASHRectangularView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .semibold))
            Text("Capture thought")
                .font(.system(size: 14, weight: .medium))
        }
    }
}

struct STASHInlineView: View {
    var body: some View {
        Label("Capture", systemImage: "brain.head.profile")
    }
}

struct STASHCornerView: View {
    var body: some View {
        Image(systemName: "brain.head.profile")
            .widgetLabel("STASH")
    }
}

// MARK: - Widget

struct STASHComplicationWidget: Widget {
    let kind = "STASHComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: STASHComplicationProvider()) { _ in
            // Add .widgetURL(URL(string: "stash://capture")!) on the entry view
            // if the Watch app ever gains multiple navigation destinations.
            STASHComplicationEntryView()
        }
        .configurationDisplayName("STASH")
        .description("Tap to capture a thought.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

// MARK: - Entry View (dispatches to family-specific views)

struct STASHComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            STASHCircularView()
        case .accessoryRectangular:
            STASHRectangularView()
        case .accessoryInline:
            STASHInlineView()
        case .accessoryCorner:
            STASHCornerView()
        default:
            STASHCircularView()
        }
    }
}
