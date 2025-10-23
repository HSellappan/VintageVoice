//
//  UserProfile.swift
//  VintageVoice
//
//  User profile data model matching FR requirements
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    var timezone: String
    var streakCount: Int
    var collectedStamps: [String]
    var lastPromptAt: Date?
    var postagePoints: Int
    var partnerID: String?
    var activeWindowStart: Int // Hour (0-23)
    var activeWindowEnd: Int   // Hour (0-23)

    init(
        id: String = UUID().uuidString,
        timezone: String = TimeZone.current.identifier,
        streakCount: Int = 0,
        collectedStamps: [String] = [],
        lastPromptAt: Date? = nil,
        postagePoints: Int = 0,
        partnerID: String? = nil,
        activeWindowStart: Int = 19,  // Default 7 PM
        activeWindowEnd: Int = 21     // Default 9 PM
    ) {
        self.id = id
        self.timezone = timezone
        self.streakCount = streakCount
        self.collectedStamps = collectedStamps
        self.lastPromptAt = lastPromptAt
        self.postagePoints = postagePoints
        self.partnerID = partnerID
        self.activeWindowStart = activeWindowStart
        self.activeWindowEnd = activeWindowEnd
    }
}
