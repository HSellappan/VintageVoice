//
//  AudioPlayer.swift
//  VintageVoice
//
//  Audio playback service with progress tracking for auto-purge
//

import Foundation
import AVFoundation
import Combine

class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0  // 0.0 to 1.0

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    var onPlaybackComplete: (() -> Void)?

    // MARK: - Playback Control

    func loadAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()

        duration = audioPlayer?.duration ?? 0
        currentTime = 0
        playbackProgress = 0
    }

    func play() {
        guard let player = audioPlayer else { return }

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        player.play()
        isPlaying = true
        startProgressMonitoring()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressMonitoring()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        stopProgressMonitoring()
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateProgress()
    }

    // MARK: - Progress Monitoring

    private func startProgressMonitoring() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }

    private func stopProgressMonitoring() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }

        currentTime = player.currentTime
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stop()
        audioPlayer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopProgressMonitoring()

        if flag {
            playbackProgress = 1.0
            currentTime = duration
            onPlaybackComplete?()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Playback error: \(error?.localizedDescription ?? "unknown")")
        isPlaying = false
        stopProgressMonitoring()
    }
}
