//
//  PersonalizationScreen.swift
//  PersonalAI
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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView

                // Theme Selection
                themeSection

                // Communication Style
                communicationStyleSection

                // Built-in personas
                VStack(alignment: .leading, spacing: 12) {
                    Text("Built-in Personas")
                        .font(.headline)
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Squirrel-Sona")
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(spacing: 12) {
            Text("🐿️")
                .font(.system(size: 64))

            Text("Squirrel-Sona")
                .font(.title.bold())

            Text("Customize your AI companion's personality")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Theme")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ThemeType.allCases) { themeType in
                        ThemePreviewCard(
                            themeType: themeType,
                            isSelected: themeEngine.currentTheme == themeType,
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

    // MARK: - Communication Style Section

    private var communicationStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Communication Style")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(MessageStyle.allCases) { style in
                    CommunicationStyleCard(
                        style: style,
                        isSelected: personalityEngine.currentStyle == style,
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
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                Text(themeType.emoji)
                    .font(.system(size: 48))

                Text(themeType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Selected")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .frame(width: 140, height: 140)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Communication Style Card

struct CommunicationStyleCard: View {
    let style: MessageStyle
    let isSelected: Bool
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
                    .foregroundColor(.primary)

                Text(style.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Active")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
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

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                // Emoji
                Text(persona.emoji)
                    .font(.system(size: 48))
                    .padding()
                    .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                    .cornerRadius(20)

                // Name
                Text(persona.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Default indicator
                if isDefault {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("Default")
                            .font(.caption)
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onSetDefault()
            } label: {
                Label("Set as Default", systemImage: "star.fill")
            }

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Emoji
                    Text(persona.emoji)
                        .font(.system(size: 80))
                        .padding()
                        .background(Color(hex: persona.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                        .cornerRadius(30)

                    // Name
                    Text(persona.name)
                        .font(.title.bold())

                    // System prompt
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personality")
                            .font(.headline)

                        Text(persona.systemPrompt)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Type")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(persona.isCustom ? "Custom" : "Built-in")
                        }

                        if persona.isCustom {
                            HStack {
                                Text("Created")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(persona.createdAt, style: .date)
                            }
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Persona Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
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

    @State private var name = ""
    @State private var emoji = "🐿️"
    @State private var systemPrompt = ""
    @State private var selectedColor: Color = .blue

    let colorOptions: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan
    ]

    var body: some View {
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
            .navigationTitle("Create Persona")
            .navigationBarTitleDisplayMode(.inline)
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
