//
//  SquirrelPersona.swift
//  PersonalAI
//
//  Squirrel-Sona personality system for customizable AI companions
//

import Foundation
import SwiftUI

// MARK: - Squirrel Persona

/// A customizable AI personality for thought exploration conversations
struct SquirrelPersona: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let name: String
    let emoji: String
    let systemPrompt: String
    let colorHex: String
    let isCustom: Bool
    let isDefault: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        systemPrompt: String,
        colorHex: String,
        isCustom: Bool = false,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.systemPrompt = systemPrompt
        self.colorHex = colorHex
        self.isCustom = isCustom
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    /// SwiftUI Color from hex
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Built-in Personas

extension SquirrelPersona {

    /// 🐿️ Supportive Listener - Empathetic and validating
    static let supportiveListener = SquirrelPersona(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Supportive Listener",
        emoji: "🐿️",
        systemPrompt: """
        Maximum 15 words total. Reply like these examples:

        "That sounds tough. What's weighing on you?"
        "I hear you. How are you feeling?"
        "That makes sense. What would help?"

        Copy that style exactly. Short validation, then short question. Nothing else.
        """,
        colorHex: "FF8C42", // Warm orange
        isCustom: false,
        isDefault: true
    )

    /// 🧠 Socratic Questioner - Challenges assumptions thoughtfully
    static let socraticQuestioner = SquirrelPersona(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Socratic Questioner",
        emoji: "🧠",
        systemPrompt: """
        Maximum 15 words. Reply like these examples:

        "Why do you think that's true?"
        "What evidence supports this?"
        "What if the opposite were true?"

        One short probing question. Nothing more.
        """,
        colorHex: "9B59B6", // Purple
        isCustom: false
    )

    /// 💡 Brainstorm Partner - Enthusiastic idea generator
    static let brainstormPartner = SquirrelPersona(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Brainstorm Partner",
        emoji: "💡",
        systemPrompt: """
        Maximum 15 words. Reply like these examples:

        "Yes! What if you combined that with X?"
        "Ooh! That reminds me of Y!"
        "Love it! Could you flip that around?"

        One short enthusiastic response. Be brief and playful.
        """,
        colorHex: "F1C40F", // Bright yellow
        isCustom: false
    )

    /// 😌 Journal Guide - Helps process emotions and experiences
    static let journalGuide = SquirrelPersona(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Journal Guide",
        emoji: "😌",
        systemPrompt: """
        Maximum 15 words. Reply like these examples:

        "Where do you feel that in your body?"
        "What happened just before?"
        "What do you need right now?"

        One gentle reflective question. Keep it simple and brief.
        """,
        colorHex: "3498DB", // Calm blue
        isCustom: false
    )

    /// 🎯 Devil's Advocate - Respectfully challenges ideas
    static let devilsAdvocate = SquirrelPersona(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Devil's Advocate",
        emoji: "🎯",
        systemPrompt: """
        Maximum 15 words. Reply like these examples:

        "But what about the cost?"
        "What could go wrong here?"
        "Have you considered the downside?"

        One short constructive challenge. Be brief and direct.
        """,
        colorHex: "E74C3C", // Red
        isCustom: false
    )

    /// All built-in personas
    static let builtIn: [SquirrelPersona] = [
        .supportiveListener,
        .socraticQuestioner,
        .brainstormPartner,
        .journalGuide,
        .devilsAdvocate
    ]

    /// Default persona (Supportive Listener)
    static let `default` = supportiveListener
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    var hexString: String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Persona Service

/// Service for managing squirrel personas
@MainActor
class PersonaService: ObservableObject {
    static let shared = PersonaService()

    @Published private(set) var customPersonas: [SquirrelPersona] = []
    @Published var defaultPersonaId: UUID = SquirrelPersona.default.id

    private let userDefaultsKey = "squirrel_personas"
    private let defaultPersonaKey = "default_persona_id"

    init() {
        loadCustomPersonas()
        loadDefaultPersonaId()
    }

    /// All personas (built-in + custom)
    var allPersonas: [SquirrelPersona] {
        SquirrelPersona.builtIn + customPersonas
    }

    /// Get persona by ID
    func getPersona(id: UUID) -> SquirrelPersona {
        allPersonas.first { $0.id == id } ?? .default
    }

    /// Get default persona
    var defaultPersona: SquirrelPersona {
        getPersona(id: defaultPersonaId)
    }

    /// Set default persona
    func setDefaultPersona(_ persona: SquirrelPersona) {
        defaultPersonaId = persona.id
        UserDefaults.standard.set(persona.id.uuidString, forKey: defaultPersonaKey)
    }

    /// Create custom persona
    func createCustomPersona(
        name: String,
        emoji: String,
        systemPrompt: String,
        colorHex: String
    ) {
        let persona = SquirrelPersona(
            name: name,
            emoji: emoji,
            systemPrompt: systemPrompt,
            colorHex: colorHex,
            isCustom: true
        )
        customPersonas.append(persona)
        saveCustomPersonas()
    }

    /// Update custom persona
    func updateCustomPersona(_ persona: SquirrelPersona) {
        guard persona.isCustom else { return }
        if let index = customPersonas.firstIndex(where: { $0.id == persona.id }) {
            customPersonas[index] = persona
            saveCustomPersonas()
        }
    }

    /// Delete custom persona
    func deleteCustomPersona(_ persona: SquirrelPersona) {
        guard persona.isCustom else { return }
        customPersonas.removeAll { $0.id == persona.id }

        // If deleted persona was default, reset to built-in default
        if persona.id == defaultPersonaId {
            setDefaultPersona(.default)
        }

        saveCustomPersonas()
    }

    // MARK: - Persistence

    private func loadCustomPersonas() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            customPersonas = try JSONDecoder().decode([SquirrelPersona].self, from: data)
        } catch {
            print("❌ Failed to load custom personas: \(error)")
        }
    }

    private func saveCustomPersonas() {
        do {
            let data = try JSONEncoder().encode(customPersonas)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Failed to save custom personas: \(error)")
        }
    }

    private func loadDefaultPersonaId() {
        if let idString = UserDefaults.standard.string(forKey: defaultPersonaKey),
           let uuid = UUID(uuidString: idString) {
            defaultPersonaId = uuid
        }
    }
}
