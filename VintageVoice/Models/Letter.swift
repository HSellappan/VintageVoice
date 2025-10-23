//
//  Letter.swift
//  VintageVoice
//
//  Voice letter data model with delivery and purge logic
//

import Foundation

enum LetterStatus: String, Codable {
    case sent       // Letter is in transit (not visible to recipient)
    case delivered  // Letter has arrived in recipient's mailbox
    case opened     // Recipient has started playback
    case purged     // Audio has been auto-deleted after full playback
}

struct Letter: Codable, Identifiable {
    let id: String
    let senderID: String
    let recipientID: String
    var audioURL: String
    var transcript: String?
    let createdAt: Date
    let deliverAt: Date
    var promptID: String?        // Set if letter was created from Daily Spark
    var stickerID: String?       // Optional parchment sticker decoration
    var ambienceID: String?      // Optional intro ambience clip
    var status: LetterStatus
    var openedAt: Date?          // Timestamp of first playback
    var playbackProgress: Double // 0.0 to 1.0, for purge logic

    init(
        id: String = UUID().uuidString,
        senderID: String,
        recipientID: String,
        audioURL: String = "",
        transcript: String? = nil,
        createdAt: Date = Date(),
        deliverAt: Date,
        promptID: String? = nil,
        stickerID: String? = nil,
        ambienceID: String? = nil,
        status: LetterStatus = .sent,
        openedAt: Date? = nil,
        playbackProgress: Double = 0.0
    ) {
        self.id = id
        self.senderID = senderID
        self.recipientID = recipientID
        self.audioURL = audioURL
        self.transcript = transcript
        self.createdAt = createdAt
        self.deliverAt = deliverAt
        self.promptID = promptID
        self.stickerID = stickerID
        self.ambienceID = ambienceID
        self.status = status
        self.openedAt = openedAt
        self.playbackProgress = playbackProgress
    }

    /// Returns true if letter should be visible to recipient
    var isVisible: Bool {
        return Date() >= deliverAt && status != .sent
    }

    /// Returns true if letter can be purged (full playback completed)
    var canPurge: Bool {
        return status == .opened && playbackProgress >= 0.99
    }
}
