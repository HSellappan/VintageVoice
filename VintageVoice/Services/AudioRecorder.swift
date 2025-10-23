//
//  AudioRecorder.swift
//  VintageVoice
//
//  Audio recording service using AVFoundation
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0  // For waveform visualization

    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = .sharedInstance()
    private var recordingURL: URL?
    private var levelTimer: Timer?

    // MARK: - Configuration

    private let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    // MARK: - Permission

    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        // Configure audio session
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        // Create unique recording URL
        let filename = "recording_\(UUID().uuidString).m4a"
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(filename)

        guard let url = recordingURL else {
            throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recording URL"])
        }

        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true

        // Start monitoring audio levels
        startLevelMonitoring()
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        stopLevelMonitoring()

        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }

        return recordingURL
    }

    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopLevelMonitoring()

        // Delete the recording file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }

    // MARK: - Audio Level Monitoring

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }

            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)

            // Normalize level from -160...0 to 0...1
            let normalizedLevel = max(0, (level + 160) / 160)
            self.audioLevel = normalizedLevel
            self.recordingTime = recorder.currentTime
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
        recordingTime = 0
    }

    // MARK: - Cleanup

    func cleanup() {
        cancelRecording()
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        stopLevelMonitoring()

        if !flag {
            print("Recording failed")
            recordingURL = nil
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recording error: \(error?.localizedDescription ?? "unknown")")
        isRecording = false
        stopLevelMonitoring()
    }
}
