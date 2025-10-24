//
//  LetterService.swift
//  VintageVoice
//
//  Manages letter creation, delivery, and purge logic (LOCAL ONLY)
//

import Foundation
import Combine

class LetterService: ObservableObject {
    @Published var receivedLetters: [Letter] = []
    @Published var sentLetters: [Letter] = []

    private let userDefaults = UserDefaults.standard
    private let lettersKey = "VintageVoice_Letters"
    private var updateTimer: Timer?

    // MARK: - Local Storage

    private func loadLetters() -> [Letter] {
        guard let data = userDefaults.data(forKey: lettersKey),
              let letters = try? JSONDecoder().decode([Letter].self, from: data) else {
            return []
        }
        return letters
    }

    private func saveLetters(_ letters: [Letter]) {
        if let data = try? JSONEncoder().encode(letters) {
            userDefaults.set(data, forKey: lettersKey)
        }
    }

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

        var letters = loadLetters()
        letters.append(letter)
        saveLetters(letters)

        return letter
    }

    // MARK: - Fetching Letters

    func fetchReceivedLetters(for userID: String) {
        // Start timer to check for delivered letters
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateReceivedLetters(for: userID)
        }
        // Initial fetch
        updateReceivedLetters(for: userID)
    }

    private func updateReceivedLetters(for userID: String) {
        let letters = loadLetters()
        receivedLetters = letters
            .filter { $0.recipientID == userID && $0.isVisible }
            .sorted { $0.deliverAt > $1.deliverAt }
    }

    func fetchSentLetters(for userID: String) {
        let letters = loadLetters()
        sentLetters = letters
            .filter { $0.senderID == userID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Letter Delivery

    func deliverLetter(letterID: String) async throws {
        var letters = loadLetters()
        if let index = letters.firstIndex(where: { $0.id == letterID }) {
            letters[index].status = .delivered
            saveLetters(letters)
        }
    }

    // MARK: - Letter Opening & Playback

    func markLetterAsOpened(letterID: String) async throws {
        var letters = loadLetters()
        if let index = letters.firstIndex(where: { $0.id == letterID }) {
            letters[index].status = .opened
            letters[index].openedAt = Date()
            saveLetters(letters)
        }
    }

    func updatePlaybackProgress(letterID: String, progress: Double) async throws {
        var letters = loadLetters()
        if let index = letters.firstIndex(where: { $0.id == letterID }) {
            letters[index].playbackProgress = progress
            saveLetters(letters)
        }
    }

    // MARK: - Auto-Purge (FR-DEL-03)

    func purgeLetter(letterID: String) async throws {
        var letters = loadLetters()
        if let index = letters.firstIndex(where: { $0.id == letterID }) {
            letters[index].status = .purged
            letters[index].audioURL = "" // Clear audio URL
            saveLetters(letters)
        }
    }

    // MARK: - Cleanup

    func stopListening() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    deinit {
        stopListening()
    }
}
