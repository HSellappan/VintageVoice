//
//  DailySparkService.swift
//  VintageVoice
//
//  Daily Spark engine client logic (LOCAL ONLY)
//

import Foundation
import Combine

class DailySparkService: ObservableObject {
    @Published var todaysPrompt: Prompt?
    @Published var promptHistory: [Prompt] = []
    @Published var hasCompletedToday = false

    private let userDefaults = UserDefaults.standard
    private let promptsKey = "VintageVoice_Prompts"

    // MARK: - Fetch Today's Prompt

    func fetchTodaysPrompt(for userID: String) async {
        // Use a random sample prompt for local testing
        await createTestPrompt()
    }

    // MARK: - Check Completion Status

    func checkCompletionStatus(for userID: String) async {
        // For local mode, always allow
        await MainActor.run {
            self.hasCompletedToday = false
        }
    }

    // MARK: - Award Spark Stamp

    func awardSparkStamp(userID: String, promptID: String) async throws {
        // For local mode, just mark as completed
        await MainActor.run {
            self.hasCompletedToday = true
        }
    }

    // MARK: - Prompt Management

    func loadPromptHistory(for userID: String) {
        // Use sample prompts for local testing
        promptHistory = Prompt.samples
    }

    // MARK: - Testing Helper

    private func createTestPrompt() async {
        // Create a test prompt for development
        let randomPrompt = Prompt.samples.randomElement() ?? Prompt.samples[0]

        var testPrompt = randomPrompt
        testPrompt.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date())

        await MainActor.run {
            self.todaysPrompt = testPrompt
        }
    }
}
