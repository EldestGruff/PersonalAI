//
//  PersonalizationScreen.swift
//  STASH
//
//  Squirrel-Sona persona management screen
//

import SwiftUI

struct PersonalizationScreen: View {
    @ObservedObject private var personaService = PersonaService.shared
    @State private var themeEngine = ThemeEngine.shared
    @State private var personalityEngine = PersonalityEngine.shared
    @State private var showCreatePersona = false
    @State private var showPersonaDetail: SquirrelPersona?
    @State private var showDeleteConfirmation = false
    @State private var personaToDelete: SquirrelPersona?
    @State private var headerImageName: String = "squirrel-base"

    private static let headerImagePool: [String] = [
        "squirrel-base",
        "squirrel-brainstorm",
        "squirrel-celebrating",
        "squirrel-devils-advocate",
        "squirrel-journaling",
        "squirrel-napping",
        "squirrel-socratic-questioner",
        "squirrel-sprout",
        "squirrel-supportive-listener",
        "squirrel-thriving",
        "squirrel-adventuring-chef",
        "squirrel-adventuring-painter",
        "squirrel-adventuring-pilot",
        "squirrel-adventuring-professor",
    ]

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        ZStack {
            // Theme background
            theme.backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView

                    // Live Preview
                    livePreviewSection

                    // Theme Selection
                    ThemeSectionView()

                    // Communication Style
                    CommunicationStyleSectionView()

                    // Built-in personas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Built-in Personas")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(SquirrelPersona.builtIn) { persona in
                                PersonaCard(
                                    persona: persona,
                                    isDefault: persona.id == personaService.defaultPersonaId,
                                    onTap: {
                                        showPersonaDetail = persona
                                    },
                                    onSetDefault: {
                                        personaService.setDefaultPersona(persona)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Custom personas
                    if !personaService.customPersonas.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Personas")
                                .font(.headline)
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(personaService.customPersonas) { persona in
                                    PersonaCard(
                                        persona: persona,
                                        isDefault: persona.id == personaService.defaultPersonaId,
                                        onTap: {
                                            showPersonaDetail = persona
                                        },
                                        onSetDefault: {
                                            personaService.setDefaultPersona(persona)
                                        },
                                        onDelete: {
                                            personaToDelete = persona
                                            showDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Create custom persona button
                    Button {
                        showCreatePersona = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Custom Persona")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            headerImageName = Self.headerImagePool.randomElement() ?? "squirrel-base"
        }
        .navigationTitle("Squirrel-Sona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.surfaceColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showCreatePersona) {
            CreatePersonaSheet()
        }
        .sheet(item: $showPersonaDetail) { persona in
            PersonaDetailSheet(persona: persona)
        }
        .confirmationDialog(
            "Delete this persona?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let persona = personaToDelete {
                    personaService.deleteCustomPersona(persona)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(spacing: 12) {
            Image(headerImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 100)

            Text("Squirrel-Sona")
                .font(.title.bold())
                .foregroundColor(theme.textColor)

            Text("Customize your AI companion's personality")
                .font(.subheadline)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        let theme = themeEngine.getCurrentTheme()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Live Preview")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                // Theme colors preview
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 40, height: 40)
                        Text("Primary")
                            .font(.caption2)
                    }

                    VStack(spacing: 8) {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 40, height: 40)
                        Text("Accent")
                            .font(.caption2)
                    }

                    VStack(spacing: 8) {
                        Circle()
                            .fill(theme.backgroundColor)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        Text("Background")
                            .font(.caption2)
                    }
                }
                .frame(maxWidth: .infinity)

                // Sample message in current style
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Messages:")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)

                    Text(personalityEngine.thoughtSaved())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.surfaceColor)
                        .foregroundColor(theme.textColor)
                        .cornerRadius(theme.cornerRadius)

                    Text(personalityEngine.classificationSuggestion(type: "Reminder"))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.surfaceColor)
                        .foregroundColor(theme.textColor)
                        .cornerRadius(theme.cornerRadius)
                }
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

}

// MARK: - Theme Section View

struct ThemeSectionView: View {
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let currentTheme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Theme")
                .font(.headline)
                .foregroundColor(currentTheme.textColor)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ThemeType.allCases) { themeType in
                        ThemePreviewCard(
                            themeType: themeType,
                            isSelected: themeEngine.currentTheme == themeType,
                            currentTheme: currentTheme,
                            onTap: {
                                withAnimation {
                                    themeEngine.setTheme(themeType)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Communication Style Section View

struct CommunicationStyleSectionView: View {
    @State private var personalityEngine = PersonalityEngine.shared
    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        VStack(alignment: .leading, spacing: 12) {
            Text("Communication Style")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(MessageStyle.allCases) { style in
                    CommunicationStyleCard(
                        style: style,
                        isSelected: personalityEngine.currentStyle == style,
                        theme: theme,
                        onTap: {
                            personalityEngine.setStyle(style)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let themeType: ThemeType
    let isSelected: Bool
    let currentTheme: any ThemeVariant  // The currently active theme (for selection UI)
    let onTap: () -> Void

    // The theme being previewed (from the themeType parameter)
    private var previewTheme: any ThemeVariant {
        themeType.theme
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                Text(themeType.emoji)
                    .font(.system(size: 48))

                Text(themeType.displayName)
                    .font(.headline)
                    .foregroundColor(previewTheme.textColor)

                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Selected")
                            .font(.caption)
                    }
                    .foregroundColor(currentTheme.primaryColor)
                }
            }
            .frame(width: 140, height: 140)
            .padding()
            .background(previewTheme.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? currentTheme.primaryColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Communication Style Card

struct CommunicationStyleCard: View {
    let style: MessageStyle
    let isSelected: Bool
    let theme: any ThemeVariant
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                Text(style.emoji)
                    .font(.system(size: 36))

                Text(style.displayName)
                    .font(.headline)
                    .foregroundColor(theme.textColor)

                Text(style.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Active")
                            .font(.caption)
                    }
                    .foregroundColor(theme.primaryColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Persona Card

struct PersonaCard: View {
    let persona: SquirrelPersona
    let isDefault: Bool
    let onTap: () -> Void
    let onSetDefault: () -> Void
    var onDelete: (() -> Void)?

    @State private var themeEngine = ThemeEngine.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        Button {
            onSetDefault()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    // Portrait image (emoji fallback for custom personas)
                    Image(persona.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 90)

                    // Name
                    Text(persona.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.textColor)
                        .lineLimit(2)

                    // Selected indicator
                    if isDefault {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Active")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primaryColor.opacity(0.12))
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDefault ? theme.primaryColor : Color.clear, lineWidth: 2)
                )

                // Info button — opens detail sheet without triggering selection
                Button {
                    onTap()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.secondaryTextColor)
                        .padding(10)
                }
                .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Persona Detail Sheet

struct PersonaDetailSheet: View {
    let persona: SquirrelPersona
    @Environment(\.dismiss) private var dismiss
    @State private var themeEngine = ThemeEngine.shared
    @ObservedObject private var personaService = PersonaService.shared

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            ZStack {
                // Theme background
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Portrait image (emoji fallback for custom personas)
                        Image(persona.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)

                        // Name
                        Text(persona.name)
                            .font(.title.bold())
                            .foregroundColor(theme.textColor)

                        // System prompt
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personality")
                                .font(.headline)
                                .foregroundColor(theme.textColor)

                            Text(persona.systemPrompt)
                                .font(.body)
                                .foregroundColor(theme.textColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.surfaceColor)
                                .cornerRadius(12)
                        }

                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Type")
                                    .foregroundColor(theme.secondaryTextColor)
                                Spacer()
                                Text(persona.isCustom ? "Custom" : "Built-in")
                                    .foregroundColor(theme.textColor)
                            }

                            if persona.isCustom {
                                HStack {
                                    Text("Created")
                                        .foregroundColor(theme.secondaryTextColor)
                                    Spacer()
                                    Text(persona.createdAt, style: .date)
                                        .foregroundColor(theme.textColor)
                                }
                            }
                        }
                        .font(.subheadline)
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Persona Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if personaService.defaultPersonaId != persona.id {
                        Button("Use This") {
                            personaService.setDefaultPersona(persona)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Create Persona Sheet

struct CreatePersonaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var personaService = PersonaService.shared
    @State private var themeEngine = ThemeEngine.shared

    @State private var name = ""
    @State private var emoji = "🐿️"
    @State private var systemPrompt = ""
    @State private var selectedColor: Color = .blue

    let colorOptions: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan
    ]

    var body: some View {
        let theme = themeEngine.getCurrentTheme()

        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .font(.title)
                    }
                } header: {
                    Text("Basic Info")
                }

                Section {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44))
                    ], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                        }
                    }
                } header: {
                    Text("Color")
                }

                Section {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 200)
                } header: {
                    Text("Personality Prompt")
                } footer: {
                    Text("Describe how this persona should behave and respond. Be specific about tone, approach, and conversation style.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor)
            .navigationTitle("Create Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.surfaceColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPersona()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createPersona() {
        personaService.createCustomPersona(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines),
            systemPrompt: systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: selectedColor.hexString
        )

        dismiss()
    }
}

// MARK: - Previews

#Preview("Personalization Screen") {
    NavigationStack {
        PersonalizationScreen()
    }
}

#Preview("Create Persona") {
    CreatePersonaSheet()
}
