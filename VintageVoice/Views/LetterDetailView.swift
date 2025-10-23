//
//  LetterDetailView.swift
//  VintageVoice
//
//  Letter playback view with auto-purge logic (FR-DEL-03)
//

import SwiftUI

struct LetterDetailView: View {
    let letter: Letter

    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var storageService = StorageService()
    @StateObject private var letterService = LetterService()

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var localAudioURL: URL?
    @State private var hasMarkedAsOpened = false
    @State private var showTranscript = false

    var body: some View {
        ZStack {
            Color.vintageBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                headerView

                Spacer()

                // Envelope visualization
                envelopeView

                Spacer()

                // Playback controls
                if !isLoading && localAudioURL != nil {
                    playbackControlsView
                }

                // Transcript button
                if let transcript = letter.transcript, !showTranscript {
                    Button(action: { showTranscript = true }) {
                        Text("View Transcript")
                            .font(.vintageCaption)
                    }
                    .buttonStyle(VintageButtonStyle())
                }

                Spacer()
            }
            .padding()

            if isLoading {
                ProgressView("Loading...")
                    .tint(.vintageInk)
            }

            // Transcript overlay
            if showTranscript, let transcript = letter.transcript {
                transcriptOverlay(transcript: transcript)
            }
        }
        .task {
            await loadAudio()
        }
        .onDisappear {
            audioPlayer.cleanup()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.vintageInk)
            }

            Spacer()

            Text("Voice Letter")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "chevron.left")
                .foregroundColor(.clear)
        }
    }

    // MARK: - Envelope View

    private var envelopeView: some View {
        VStack(spacing: 16) {
            // Envelope illustration
            ZStack {
                // Envelope body
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vintageParchment)
                    .frame(width: 280, height: 180)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vintageBrown.opacity(0.4), lineWidth: 2)
                    )

                // Wax seal
                if letter.status != .purged {
                    Circle()
                        .fill(letter.status == .opened ? Color.gray : Color.waxRed)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: letter.status == .opened ? "envelope.open.fill" : "seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                        .shadow(radius: 4)
                        .offset(y: 60)
                }
            }

            // Delivery info
            VStack(spacing: 8) {
                Text("Arrived: \(formatDate(letter.deliverAt))")
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)

                if letter.status == .purged {
                    Text("Audio purged after playback")
                        .font(.vintageCaption)
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControlsView: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vintageBrown.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.waxRed)
                        .frame(width: geometry.size.width * audioPlayer.playbackProgress, height: 8)
                }
            }
            .frame(height: 8)

            // Time labels
            HStack {
                Text(formatTime(audioPlayer.currentTime))
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)

                Spacer()

                Text(formatTime(audioPlayer.duration))
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)
            }

            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.waxRed)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Transcript Overlay

    private func transcriptOverlay(transcript: String) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showTranscript = false
                }

            VStack(spacing: 16) {
                HStack {
                    Text("Transcript")
                        .font(.vintageHeadline)
                        .foregroundColor(.vintageInk)

                    Spacer()

                    Button(action: { showTranscript = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.vintageBrown)
                    }
                }

                ScrollView {
                    Text(transcript)
                        .font(.vintageBody)
                        .foregroundColor(.vintageInk)
                        .padding()
                }
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.vintageParchment)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(40)
        }
    }

    // MARK: - Actions

    private func loadAudio() async {
        guard letter.status != .purged, !letter.audioURL.isEmpty else {
            isLoading = false
            return
        }

        do {
            // Download audio from Firebase Storage
            localAudioURL = try await storageService.downloadAudio(url: letter.audioURL)

            // Load into player
            if let url = localAudioURL {
                try audioPlayer.loadAudio(url: url)
            }

            // Mark as opened on first view
            if letter.status == .delivered && !hasMarkedAsOpened {
                try await letterService.markLetterAsOpened(letterID: letter.id)
                hasMarkedAsOpened = true
            }

            // Set up auto-purge callback
            audioPlayer.onPlaybackComplete = { [weak letterService] in
                Task {
                    // Update progress to 1.0
                    try? await letterService?.updatePlaybackProgress(letterID: letter.id, progress: 1.0)

                    // Trigger auto-purge (FR-DEL-03)
                    try? await letterService?.purgeLetter(letterID: letter.id)
                }
            }

            isLoading = false
        } catch {
            print("Failed to load audio: \(error)")
            isLoading = false
        }
    }

    private func togglePlayback() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
