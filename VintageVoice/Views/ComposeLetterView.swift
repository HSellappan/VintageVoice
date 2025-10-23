//
//  ComposeLetterView.swift
//  VintageVoice
//
//  Letter composition with voice recording and wax seal animation
//

import SwiftUI

enum ComposeState {
    case initial
    case recording
    case recorded
    case sealing
    case sending
    case sent
}

struct ComposeLetterView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var letterService = LetterService()
    @StateObject private var storageService = StorageService()
    @EnvironmentObject var authService: AuthService

    @Environment(\.dismiss) private var dismiss

    @State private var composeState: ComposeState = .initial
    @State private var selectedDelay: DelayPreset = .oneDay
    @State private var recordedAudioURL: URL?
    @State private var showDelayPicker = false
    @State private var permissionGranted = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.vintageBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                headerView

                Spacer()

                // Main content based on state
                switch composeState {
                case .initial:
                    initialView
                case .recording:
                    recordingView
                case .recorded:
                    recordedView
                case .sealing, .sending:
                    sealingView
                case .sent:
                    sentView
                }

                Spacer()

                // Action button
                actionButton

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.vintageCaption)
                        .foregroundColor(.waxRed)
                        .multilineTextAlignment(.center)
                        .padding()
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

            Text("New Letter")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.clear)
                .font(.system(size: 24))
        }
    }

    // MARK: - State Views

    private var initialView: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle")
                .font(.system(size: 100))
                .foregroundColor(.vintageBrown.opacity(0.5))

            Text("Ready to record")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Text("Tap the microphone to start recording your voice letter")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Delay selector
            delaySelector
        }
    }

    private var recordingView: some View {
        VStack(spacing: 24) {
            // Animated microphone
            ZStack {
                // Pulsing circle
                Circle()
                    .fill(Color.waxRed.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(1 + CGFloat(audioRecorder.audioLevel) * 0.5)
                    .animation(.easeInOut(duration: 0.1), value: audioRecorder.audioLevel)

                Image(systemName: "mic.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.waxRed)
            }

            Text("Recording...")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            // Recording time
            Text(formatRecordingTime(audioRecorder.recordingTime))
                .font(.system(size: 48, design: .monospaced))
                .foregroundColor(.vintageBrown)

            // Audio level bars
            audioLevelBars
        }
    }

    private var recordedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Recording complete!")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Text("Duration: \(formatRecordingTime(audioRecorder.recordingTime))")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)

            // Delay selector
            delaySelector

            Text("Your letter will arrive on \(formatDeliveryDate())")
                .font(.vintageCaption)
                .foregroundColor(.vintageBrown)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    private var sealingView: some View {
        VStack(spacing: 24) {
            // Wax seal animation
            ZStack {
                // Dripping wax
                Circle()
                    .fill(Color.waxRed)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "seal.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(composeState == .sealing ? 1.0 : 0.1)
                    .animation(WaxSealAnimation.drippingWax(), value: composeState)
            }

            if composeState == .sealing {
                Text("Sealing with wax...")
                    .font(.vintageHeadline)
                    .foregroundColor(.vintageInk)
            } else {
                Text("Sending letter...")
                    .font(.vintageHeadline)
                    .foregroundColor(.vintageInk)

                ProgressView()
                    .tint(.vintageInk)
            }
        }
    }

    private var sentView: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Letter sent!")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Text("It will arrive \(formatDeliveryDate())")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)
                .multilineTextAlignment(.center)

            // Stamp earned
            VStack(spacing: 8) {
                Text("Stamp Earned")
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)

                Circle()
                    .fill(selectedDelay.stampTier.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(selectedDelay.stampTier.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .padding()
            .background(Color.vintageParchment)
            .cornerRadius(12)
        }
    }

    // MARK: - Components

    private var delaySelector: some View {
        Button(action: { showDelayPicker.toggle() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arrival Time")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)

                    Text(selectedDelay.displayName)
                        .font(.vintageBody)
                        .foregroundColor(.vintageInk)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.vintageBrown)
            }
            .padding()
            .vintageCard()
        }
        .sheet(isPresented: $showDelayPicker) {
            DelayPickerView(selectedDelay: $selectedDelay)
        }
    }

    private var audioLevelBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.waxRed)
                    .frame(width: 8, height: CGFloat(index) * 4 + 10)
                    .opacity(audioRecorder.audioLevel > Float(index) / 20 ? 1.0 : 0.3)
            }
        }
    }

    private var actionButton: some View {
        Group {
            switch composeState {
            case .initial:
                Button(action: startRecording) {
                    HStack {
                        Image(systemName: "mic.circle.fill")
                        Text("Start Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(VintageButtonStyle())
                .disabled(!permissionGranted)

            case .recording:
                Button(action: stopRecording) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(VintageButtonStyle(isDestructive: true))

            case .recorded:
                VStack(spacing: 12) {
                    Button(action: sealAndSend) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                            Text("Seal & Send")
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

            case .sent:
                Button(action: { dismiss() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(VintageButtonStyle())

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        do {
            try audioRecorder.startRecording()
            composeState = .recording
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        recordedAudioURL = audioRecorder.stopRecording()
        composeState = .recorded
    }

    private func retakeRecording() {
        audioRecorder.cancelRecording()
        recordedAudioURL = nil
        composeState = .initial
    }

    private func sealAndSend() {
        guard let audioURL = recordedAudioURL,
              let senderID = authService.currentUser?.id,
              let partnerID = authService.currentUser?.partnerID else {
            errorMessage = "Missing required information"
            return
        }

        composeState = .sealing

        Task {
            do {
                // Wait for seal animation
                try await Task.sleep(nanoseconds: UInt64(WaxSealAnimation.duration * 1_000_000_000))

                composeState = .sending

                // Upload audio to Firebase Storage
                let downloadURL = try await storageService.uploadAudio(
                    localURL: audioURL,
                    letterID: UUID().uuidString
                )

                // Create letter in Firestore
                _ = try await letterService.createLetter(
                    senderID: senderID,
                    recipientID: partnerID,
                    audioURL: downloadURL,
                    delayPreset: selectedDelay
                )

                composeState = .sent
            } catch {
                errorMessage = "Failed to send letter: \(error.localizedDescription)"
                composeState = .recorded
            }
        }
    }

    // MARK: - Helpers

    private func formatRecordingTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatDeliveryDate() -> String {
        let deliveryDate = selectedDelay.deliveryDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deliveryDate)
    }
}

#Preview {
    ComposeLetterView()
        .environmentObject(AuthService())
}
