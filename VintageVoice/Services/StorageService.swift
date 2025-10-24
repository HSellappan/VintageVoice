//
//  StorageService.swift
//  VintageVoice
//
//  Local-only audio file storage service
//

import Foundation
import Combine

class StorageService: ObservableObject {
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false

    private var localStorageDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("VintageVoiceAudio", isDirectory: true)
    }

    init() {
        // Create local storage directory
        try? FileManager.default.createDirectory(at: localStorageDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Upload Audio

    func uploadAudio(localURL: URL, letterID: String) async throws -> String {
        isUploading = true
        defer { isUploading = false }

        let filename = "\(letterID).m4a"
        let destinationURL = localStorageDirectory.appendingPathComponent(filename)

        // Copy file to local storage
        try FileManager.default.copyItem(at: localURL, to: destinationURL)

        // Simulate upload progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            await MainActor.run {
                self.uploadProgress = Double(i) / 10.0
            }
        }

        // Return local file path as "download URL"
        return destinationURL.absoluteString
    }

    // MARK: - Download Audio

    func downloadAudio(url: String) async throws -> URL {
        // In local mode, the "url" is actually the local file path
        guard let localURL = URL(string: url) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid local URL"])
        }

        // Verify file exists
        guard FileManager.default.fileExists(atPath: localURL.path) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Local audio file not found"])
        }

        return localURL
    }

    // MARK: - Delete Audio

    func deleteAudio(url: String) async throws {
        guard let localURL = URL(string: url) else { return }
        try? FileManager.default.removeItem(at: localURL)
    }

    // MARK: - Cache Management

    func clearCache() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            )

            for file in files where file.pathExtension == "m4a" {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}
