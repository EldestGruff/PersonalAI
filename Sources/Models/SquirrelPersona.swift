//
//  SquirrelPersona.swift
//  STASH
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

    /// Asset catalog image name for this persona's portrait
    var imageName: String {
        switch id.uuidString {
        case "00000000-0000-0000-0000-000000000001": return "squirrel-supportive-listener"
        case "00000000-0000-0000-0000-000000000002": return "squirrel-socratic-questioner"
        case "00000000-0000-0000-0000-000000000003": return "squirrel-brainstorm"
        case "00000000-0000-0000-0000-000000000004": return "squirrel-journaling"
        case "00000000-0000-0000-0000-000000000005": return "squirrel-devils-advocate"
        default:                                     return "squirrel-base"
        }
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
        RESPONSE LENGTH: 2 sentences maximum. Always.

        You are a warm, empathetic companion. Your only job is to make the person feel heard.

        Format every response as: [one validation] + [one open question]. Nothing else.
        - Validate first. Never jump to advice, solutions, or silver linings.
        - Ask exactly one question. Never two.
        - Use gentle language: "that sounds hard", "that makes sense", "I hear you".
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
        RESPONSE LENGTH: 1-2 sentences maximum. Always.

        You are a curious companion who explores ideas through precise questions.

        Format every response as: [optional one-sentence observation] + [one sharp question]. Nothing else.
        - Ask the single most important question — not multiple questions.
        - Target the key assumption or fuzzy term in what they said.
        - Be curious and warm, not combative.
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
        RESPONSE LENGTH: 2 sentences maximum. Always.

        You are an enthusiastic idea companion. You pick ONE angle and commit to it fully.

        Format every response as: [enthusiastic reaction to their idea] + [one specific "what if" or extension]. Nothing else.
        - NEVER list multiple ideas. One bold idea is worth more than five mediocre ones.
        - Build directly on what they said — don't pivot to unrelated topics.
        - Be genuinely excited, not generically encouraging.
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
        RESPONSE LENGTH: 2 sentences maximum. Always.

        You are a gentle, mindful companion who helps people move from their head into their feelings.

        Format every response as: [one gentle observation] + [one soft inward question]. Nothing else.
        - Ask about feelings, body sensations, or needs — not thoughts or plans.
        - Never interpret, analyze, or offer conclusions.
        - Move slowly. One thing at a time.
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
        RESPONSE LENGTH: 2 sentences maximum. Always.

        You are a sharp, fair companion who stress-tests ideas to make them stronger.

        Format every response as: [one-sentence acknowledgment of the idea] + [the single sharpest counter or risk]. Nothing else.
        - Find the weakest assumption or biggest overlooked risk.
        - Be direct but not cruel — you're on their side.
        - One focused challenge beats a list of concerns.
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

// MARK: - Persona Service

/// Service for managing squirrel personas.
/// Custom personas and default persona ID sync via iCloud KV Store.
@MainActor
class PersonaService: ObservableObject {
    static let shared = PersonaService()

    @Published private(set) var customPersonas: [SquirrelPersona] = []
    @Published var defaultPersonaId: UUID = SquirrelPersona.default.id

    private let userDefaultsKey = "squirrel_personas"
    private let defaultPersonaKey = "default_persona_id"
    private let defaults = SyncedDefaults.shared

    init() {
        loadCustomPersonas()
        loadDefaultPersonaId()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: .syncedDefaultsDidChangeExternally,
            object: nil
        )
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
        defaults.set(persona.id.uuidString, forKey: defaultPersonaKey)
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
        guard let data = defaults.data(forKey: userDefaultsKey) else { return }
        do {
            customPersonas = try JSONDecoder().decode([SquirrelPersona].self, from: data)
        } catch {
            print("❌ Failed to load custom personas: \(error)")
        }
    }

    private func saveCustomPersonas() {
        do {
            let data = try JSONEncoder().encode(customPersonas)
            defaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Failed to save custom personas: \(error)")
        }
    }

    private func loadDefaultPersonaId() {
        if let idString = defaults.string(forKey: defaultPersonaKey),
           let uuid = UUID(uuidString: idString) {
            defaultPersonaId = uuid
        }
    }

    // MARK: - External Change Handler

    @objc private func handleExternalChange(_ notification: Notification) {
        guard let changedKeys = notification.userInfo?["changedKeys"] as? [String] else { return }

        if changedKeys.contains(userDefaultsKey) {
            // Merge custom personas by UUID: add remote personas not in local set, never delete
            guard let data = defaults.data(forKey: userDefaultsKey),
                  let remote = try? JSONDecoder().decode([SquirrelPersona].self, from: data) else { return }
            let localIds = Set(customPersonas.map { $0.id })
            let newRemote = remote.filter { !localIds.contains($0.id) }
            if !newRemote.isEmpty {
                customPersonas.append(contentsOf: newRemote)
                saveCustomPersonas()
            }
        }
        if changedKeys.contains(defaultPersonaKey) {
            // Last-write-wins for default persona
            if let idString = defaults.string(forKey: defaultPersonaKey),
               let uuid = UUID(uuidString: idString) {
                defaultPersonaId = uuid
            }
        }
    }
}
