//
//  LetterService.swift
//  VintageVoice
//
//  Manages letter creation, delivery, and purge logic with Firestore
//

import Foundation
import FirebaseFirestore
import Combine

class LetterService: ObservableObject {
    @Published var receivedLetters: [Letter] = []
    @Published var sentLetters: [Letter] = []

    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    // MARK: - Letter Creation

    func createLetter(
        senderID: String,
        recipientID: String,
        audioURL: String,
        delayPreset: DelayPreset,
        promptID: String? = nil,
        stickerID: String? = nil
    ) async throws -> Letter {
        let letter = Letter(
            senderID: senderID,
            recipientID: recipientID,
            audioURL: audioURL,
            deliverAt: delayPreset.deliveryDate(),
            promptID: promptID,
            stickerID: stickerID,
            status: .sent
        )

        let data = try Firestore.Encoder().encode(letter)
        try await db.collection("letters").document(letter.id).setData(data)

        return letter
    }

    // MARK: - Fetching Letters

    func fetchReceivedLetters(for userID: String) {
        listenerRegistration = db.collection("letters")
            .whereField("recipientID", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching letters: \(error?.localizedDescription ?? "unknown")")
                    return
                }

                self?.receivedLetters = documents.compactMap { doc in
                    try? doc.data(as: Letter.self)
                }
                .filter { letter in
                    // Only show letters that have been delivered (FR-HIDE-01)
                    letter.isVisible
                }
                .sorted { $0.deliverAt > $1.deliverAt }
            }
    }

    func fetchSentLetters(for userID: String) {
        db.collection("letters")
            .whereField("senderID", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching sent letters: \(error?.localizedDescription ?? "unknown")")
                    return
                }

                self?.sentLetters = documents.compactMap { doc in
                    try? doc.data(as: Letter.self)
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
    }

    // MARK: - Letter Delivery (called by Cloud Function - FR-ENV-02)

    func deliverLetter(letterID: String) async throws {
        try await db.collection("letters").document(letterID).updateData([
            "status": LetterStatus.delivered.rawValue
        ])
    }

    // MARK: - Letter Opening & Playback

    func markLetterAsOpened(letterID: String) async throws {
        try await db.collection("letters").document(letterID).updateData([
            "status": LetterStatus.opened.rawValue,
            "openedAt": Timestamp(date: Date())
        ])
    }

    func updatePlaybackProgress(letterID: String, progress: Double) async throws {
        try await db.collection("letters").document(letterID).updateData([
            "playbackProgress": progress
        ])
    }

    // MARK: - Auto-Purge (FR-DEL-03)

    func purgeLetter(letterID: String) async throws {
        // Mark as purged and remove audio URL
        try await db.collection("letters").document(letterID).updateData([
            "status": LetterStatus.purged.rawValue,
            "audioURL": "" // Clear audio URL to trigger storage deletion
        ])

        // Note: Actual audio file deletion happens in Cloud Function or Storage service
    }

    // MARK: - Cleanup

    func stopListening() {
        listenerRegistration?.remove()
    }

    deinit {
        stopListening()
    }
}
