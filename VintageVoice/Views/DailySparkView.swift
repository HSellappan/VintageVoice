//
//  DailySparkView.swift
//  VintageVoice
//
//  Daily Spark prompt sheet for engagement (FR-ENG-04)
//

import SwiftUI

struct DailySparkView: View {
    let prompt: Prompt

    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var letterService = LetterService()
    @StateObject private var storageService = StorageService()
    @EnvironmentObject var authService: AuthService

    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var hasRecorded = false
    @State private var recordedAudioURL: URL?
    @State private var isSending = false
    @State private var hasSent = false
    @State private var errorMessage: String?
    @State private var permissionGranted = false

    var body: some View {
        ZStack {
            Color.vintageBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                headerView

                if !hasSent {
                    // Spark icon & prompt
                    promptView

                    Spacer()

                    // Recording UI
                    if isRecording {
                        recordingView
                    } else if hasRecorded {
                        recordedView
                    } else {
                        initialView
                    }

                    Spacer()

                    // Action buttons
                    actionButtons
                } else {
                    sentView
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.vintageCaption)
                        .foregroundColor(.waxRed)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .task {
            permissionGranted = await audioRecorder.requestPermission()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.vintageBrown)
                    .font(.system(size: 24))
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.stampSpark)
                Text("Daily Spark")
                    .font(.vintageHeadline)
                    .foregroundColor(.vintageInk)
            }

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.clear)
                .font(.system(size: 24))
        }
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: 16) {
            // Spark stamp preview
            ZStack {
                Circle()
                    .fill(Color.stampSpark)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 8)

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }

            Text(prompt.text)
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.vintageParchment)
                .cornerRadius(12)

            // Expiry timer
            if let expiresAt = prompt.expiresAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("Expires in \(timeUntilExpiry(expiresAt))")
                }
                .font(.vintageCaption)
                .foregroundColor(.vintageBrown)
            }
        }
    }

    // MARK: - Recording States

    private var initialView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 80))
                .foregroundColor(.vintageBrown.opacity(0.5))

            Text("Tap to record your response")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)

            Text("Default: 24 hour delay")
                .font(.vintageCaption)
                .foregroundColor(.vintageBrown.opacity(0.7))
        }
    }

    private var recordingView: some View {
        VStack(spacing: 16) {
            // Animated microphone
            ZStack {
                Circle()
                    .fill(Color.stampSpark.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .scaleEffect(1 + CGFloat(audioRecorder.audioLevel) * 0.3)
                    .animation(.easeInOut(duration: 0.1), value: audioRecorder.audioLevel)

                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.stampSpark)
            }

            Text(formatTime(audioRecorder.recordingTime))
                .font(.system(size: 36, design: .monospaced))
                .foregroundColor(.vintageInk)
        }
    }

    private var recordedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Recording complete!")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Text("Duration: \(formatTime(audioRecorder.recordingTime))")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)
        }
    }

    private var sentView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Spark Sent!")
                .font(.vintageTitle)
                .foregroundColor(.vintageInk)

            // Stamp earned
            VStack(spacing: 12) {
                Text("You earned today's Spark stamp")
                    .font(.vintageBody)
                    .foregroundColor(.vintageBrown)

                Circle()
                    .fill(Color.stampSpark)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 8)

                Text("+\(StampTier.spark.postagePoints) postage points")
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)
            }
            .padding()
            .background(Color.vintageParchment)
            .cornerRadius(16)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(VintageButtonStyle())
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            if !isRecording && !hasRecorded {
                VStack(spacing: 12) {
                    Button(action: startRecording) {
                        HStack {
                            Image(systemName: "mic.circle.fill")
                            Text("Record Response")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(VintageButtonStyle())
                    .disabled(!permissionGranted)

                    Button(action: { dismiss() }) {
                        Text("Skip")
                            .foregroundColor(.vintageBrown)
                    }
                }
            } else if isRecording {
                Button(action: stopRecording) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(VintageButtonStyle(isDestructive: true))
            } else if hasRecorded && !isSending {
                VStack(spacing: 12) {
                    Button(action: sendSpark) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Spark")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(VintageButtonStyle())

                    Button(action: retakeRecording) {
                        Text("Re-record")
                            .foregroundColor(.vintageBrown)
                    }
                }
            } else if isSending {
                ProgressView("Sending...")
                    .tint(.vintageInk)
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        do {
            try audioRecorder.startRecording()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording"
        }
    }

    private func stopRecording() {
        recordedAudioURL = audioRecorder.stopRecording()
        isRecording = false
        hasRecorded = true
    }

    private func retakeRecording() {
        audioRecorder.cancelRecording()
        recordedAudioURL = nil
        hasRecorded = false
    }

    private func sendSpark() {
        guard let audioURL = recordedAudioURL,
              let senderID = authService.currentUser?.id,
              let partnerID = authService.currentUser?.partnerID else {
            errorMessage = "Missing required information"
            return
        }

        isSending = true

        Task {
            do {
                // Upload audio
                let downloadURL = try await storageService.uploadAudio(
                    localURL: audioURL,
                    letterID: UUID().uuidString
                )

                // Create letter with Spark prompt ID (24h default delay)
                _ = try await letterService.createLetter(
                    senderID: senderID,
                    recipientID: partnerID,
                    audioURL: downloadURL,
                    delayPreset: .oneDay,
                    promptID: prompt.id
                )

                // Award stamp (would call Cloud Function in production)
                hasSent = true
                isSending = false
            } catch {
                errorMessage = "Failed to send: \(error.localizedDescription)"
                isSending = false
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func timeUntilExpiry(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    DailySparkView(prompt: Prompt.samples[0])
        .environmentObject(AuthService())
}
