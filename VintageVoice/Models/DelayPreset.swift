//
//  DelayPreset.swift
//  VintageVoice
//
//  Delay presets for letter delivery with vintage stamp tiering
//

import Foundation

enum DelayPreset: String, CaseIterable, Identifiable, Codable {
    case oneHour = "1h"
    case sixHours = "6h"
    case oneDay = "1d"
    case threeDays = "3d"
    case oneWeek = "1w"
    case twoWeeks = "2w"
    case oneMonth = "1mo"
    case threeMonths = "3mo"
    case sixMonths = "6mo"
    case oneYear = "1y"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .sixHours: return "6 Hours"
        case .oneDay: return "1 Day"
        case .threeDays: return "3 Days"
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .oneHour: return 3600
        case .sixHours: return 3600 * 6
        case .oneDay: return 3600 * 24
        case .threeDays: return 3600 * 24 * 3
        case .oneWeek: return 3600 * 24 * 7
        case .twoWeeks: return 3600 * 24 * 14
        case .oneMonth: return 3600 * 24 * 30
        case .threeMonths: return 3600 * 24 * 90
        case .sixMonths: return 3600 * 24 * 180
        case .oneYear: return 3600 * 24 * 365
        }
    }

    /// Phonogram stamp tier based on delay length (per PRD)
    var stampTier: StampTier {
        switch self {
        case .oneHour, .sixHours:
            return .bronze
        case .oneDay, .threeDays:
            return .silver
        case .oneWeek, .twoWeeks:
            return .gold
        case .oneMonth, .threeMonths:
            return .platinum
        case .sixMonths, .oneYear:
            return .diamond
        }
    }

    func deliveryDate(from date: Date = Date()) -> Date {
        return date.addingTimeInterval(timeInterval)
    }
}

enum StampTier: String, Codable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case spark  // Special tier for Daily Spark stamps

    var displayName: String {
        rawValue.capitalized
    }

    var postagePoints: Int {
        switch self {
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 5
        case .platinum: return 10
        case .diamond: return 20
        case .spark: return 3
        }
    }
}

struct Stamp: Codable, Identifiable {
    let id: String
    let tier: StampTier
    let earnedAt: Date
    let promptID: String?  // Set if from Daily Spark
    let delayPreset: DelayPreset?

    init(
        id: String = UUID().uuidString,
        tier: StampTier,
        earnedAt: Date = Date(),
        promptID: String? = nil,
        delayPreset: DelayPreset? = nil
    ) {
        self.id = id
        self.tier = tier
        self.earnedAt = earnedAt
        self.promptID = promptID
        self.delayPreset = delayPreset
    }
}
