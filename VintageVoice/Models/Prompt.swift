//
//  Prompt.swift
//  VintageVoice
//
//  Daily Spark prompt model for engagement loop
//

import Foundation

enum PromptCategory: String, Codable {
    case memory
    case gratitude
    case observation
    case dream
    case humor
    case love
}

struct Prompt: Codable, Identifiable {
    var id: String
    var text: String
    var defaultDelayHours: Int
    var category: PromptCategory
    var seasonTag: String?       // e.g., "winter", "summer", "holiday"
    var expiresAt: Date?         // Expires 24h after creation

    init(
        id: String = UUID().uuidString,
        text: String,
        defaultDelayHours: Int = 24,
        category: PromptCategory,
        seasonTag: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.defaultDelayHours = defaultDelayHours
        self.category = category
        self.seasonTag = seasonTag
        self.expiresAt = expiresAt
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// Sample prompts for testing
extension Prompt {
    static let samples: [Prompt] = [
        Prompt(
            text: "Tell them about the best smell you smelled today",
            defaultDelayHours: 24,
            category: .observation
        ),
        Prompt(
            text: "Share a memory that made you smile this week",
            defaultDelayHours: 48,
            category: .memory
        ),
        Prompt(
            text: "Describe something small you're grateful for",
            defaultDelayHours: 24,
            category: .gratitude
        ),
        Prompt(
            text: "What's a dream you had recently?",
            defaultDelayHours: 72,
            category: .dream
        ),
        Prompt(
            text: "Tell them something funny that happened today",
            defaultDelayHours: 24,
            category: .humor
        )
    ]
}
