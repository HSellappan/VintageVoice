//
//  DailySparkService.swift
//  VintageVoice
//
//  Daily Spark engine client logic (FR-ENG-04)
//

import Foundation
import FirebaseFirestore
import Combine

class DailySparkService: ObservableObject {
    @Published var todaysPrompt: Prompt?
    @Published var promptHistory: [Prompt] = []
    @Published var hasCompletedToday = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Fetch Today's Prompt

    func fetchTodaysPrompt(for userID: String) async {
        // In production, this would be triggered by push notification
        // For now, we fetch the active prompt from Firestore

        do {
            let snapshot = try await db.collection("dailyPrompts")
                .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
                .order(by: "expiresAt")
                .limit(to: 1)
                .getDocuments()

            if let doc = snapshot.documents.first,
               let prompt = try? doc.data(as: Prompt.self) {
                await MainActor.run {
                    self.todaysPrompt = prompt
                }
            } else {
                // No active prompt, create one for testing
                await createTestPrompt()
            }
        } catch {
            print("Failed to fetch today's prompt: \(error)")
        }
    }

    // MARK: - Check Completion Status

    func checkCompletionStatus(for userID: String) async {
        guard let prompt = todaysPrompt else { return }

        do {
            // Check if user has sent a letter with this prompt ID today
            let snapshot = try await db.collection("letters")
                .whereField("senderID", isEqualTo: userID)
                .whereField("promptID", isEqualTo: prompt.id)
                .whereField("createdAt", isGreaterThan: startOfToday())
                .getDocuments()

            await MainActor.run {
                self.hasCompletedToday = !snapshot.documents.isEmpty
            }
        } catch {
            print("Failed to check completion status: \(error)")
        }
    }

    // MARK: - Award Spark Stamp

    func awardSparkStamp(userID: String, promptID: String) async throws {
        // Create stamp record
        let stamp = Stamp(
            tier: .spark,
            earnedAt: Date(),
            promptID: promptID
        )

        let stampData = try Firestore.Encoder().encode(stamp)

        // Update user profile
        try await db.collection("users").document(userID).updateData([
            "collectedStamps": FieldValue.arrayUnion([stamp.id]),
            "postagePoints": FieldValue.increment(Int64(StampTier.spark.postagePoints)),
            "lastPromptAt": Timestamp(date: Date()),
            "streakCount": FieldValue.increment(Int64(1))
        ])

        // Save stamp to collection
        try await db.collection("stamps").document(stamp.id).setData(stampData)

        await MainActor.run {
            self.hasCompletedToday = true
        }
    }

    // MARK: - Prompt Management

    func loadPromptHistory(for userID: String) {
        listener = db.collection("dailyPrompts")
            .order(by: "expiresAt", descending: true)
            .limit(to: 30)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading prompt history: \(error?.localizedDescription ?? "unknown")")
                    return
                }

                self?.promptHistory = documents.compactMap { doc in
                    try? doc.data(as: Prompt.self)
                }
            }
    }

    // MARK: - Testing Helper

    private func createTestPrompt() async {
        // Create a test prompt for development
        let randomPrompt = Prompt.samples.randomElement() ?? Prompt.samples[0]

        var testPrompt = randomPrompt
        testPrompt.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date())

        do {
            let data = try Firestore.Encoder().encode(testPrompt)
            try await db.collection("dailyPrompts").document(testPrompt.id).setData(data)

            await MainActor.run {
                self.todaysPrompt = testPrompt
            }
        } catch {
            print("Failed to create test prompt: \(error)")
        }
    }

    // MARK: - Helpers

    private func startOfToday() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }

    private func endOfToday() -> Date {
        let start = startOfToday()
        return Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
    }

    // MARK: - Cleanup

    deinit {
        listener?.remove()
    }
}

// MARK: - Cloud Function Simulation (for local testing)

extension DailySparkService {
    /// In production, this would be a Cloud Function that runs hourly
    /// This is a client-side simulation for testing
    static func simulateCloudFunctionCron() async {
        let db = Firestore.firestore()

        // Get all users
        do {
            let snapshot = try await db.collection("users").getDocuments()

            for doc in snapshot.documents {
                guard let user = try? doc.data(as: UserProfile.self) else { continue }

                // Check if user needs a prompt today
                let shouldSendPrompt = shouldSendDailyPrompt(to: user)

                if shouldSendPrompt {
                    // In production, send FCM notification
                    print("Would send Daily Spark notification to user: \(user.id)")

                    // Create/fetch today's prompt
                    let prompt = Prompt.samples.randomElement()!
                    var dailyPrompt = prompt
                    dailyPrompt.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date())

                    // Save to Firestore
                    let data = try Firestore.Encoder().encode(dailyPrompt)
                    try await db.collection("dailyPrompts").document(dailyPrompt.id).setData(data)
                }
            }
        } catch {
            print("Failed to run cron simulation: \(error)")
        }
    }

    private static func shouldSendDailyPrompt(to user: UserProfile) -> Bool {
        // Check if user received prompt in last 24h
        if let lastPrompt = user.lastPromptAt {
            let hoursSinceLastPrompt = Date().timeIntervalSince(lastPrompt) / 3600
            if hoursSinceLastPrompt < 24 {
                return false
            }
        }

        // Check if current time is in user's active window
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        return hour >= user.activeWindowStart && hour <= user.activeWindowEnd
    }
}
