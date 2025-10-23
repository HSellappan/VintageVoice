//
//  StorageService.swift
//  VintageVoice
//
//  Firebase Storage service for audio file upload/download
//  Supports LOCAL_ONLY mode for testing without Firebase Storage
//

import Foundation
import FirebaseStorage

class StorageService: ObservableObject {
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false

    private let storage = Storage.storage()

    // MARK: - Configuration

    // ⚠️ TOGGLE THIS FLAG TO TEST WITHOUT FIREBASE STORAGE
    // Set to true to use local file storage only (no Firebase Storage needed)
    // Set to false to use Firebase Storage (requires setup)
    private let useLocalStorageOnly = true

    private var localStorageDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("VintageVoiceAudio", isDirectory: true)
    }

    init() {
        // Create local storage directory if using local mode
        if useLocalStorageOnly {
            try? FileManager.default.createDirectory(at: localStorageDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Upload Audio

    func uploadAudio(localURL: URL, letterID: String) async throws -> String {
        if useLocalStorageOnly {
            return try await uploadAudioLocally(localURL: localURL, letterID: letterID)
        } else {
            return try await uploadAudioToFirebase(localURL: localURL, letterID: letterID)
        }
    }

    private func uploadAudioLocally(localURL: URL, letterID: String) async throws -> String {
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

    private func uploadAudioToFirebase(localURL: URL, letterID: String) async throws -> String {
        let filename = "\(letterID).m4a"
        let storageRef = storage.reference().child("audio/\(filename)")

        isUploading = true
        defer { isUploading = false }

        // Upload file with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        let data = try Data(contentsOf: localURL)

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                    }
                }
            }

            // Monitor upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
    }

    // MARK: - Download Audio

    func downloadAudio(url: String) async throws -> URL {
        if useLocalStorageOnly {
            return try await downloadAudioLocally(url: url)
        } else {
            return try await downloadAudioFromFirebase(url: url)
        }
    }

    private func downloadAudioLocally(url: String) async throws -> URL {
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

    private func downloadAudioFromFirebase(url: String) async throws -> URL {
        guard let storageURL = URL(string: url) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // Create reference from URL
        let storageRef = storage.reference(forURL: url)

        // Download to temporary directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.write(toFile: tempURL) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to download file"]))
                }
            }
        }
    }

    // MARK: - Delete Audio

    func deleteAudio(url: String) async throws {
        if useLocalStorageOnly {
            try await deleteAudioLocally(url: url)
        } else {
            try await deleteAudioFromFirebase(url: url)
        }
    }

    private func deleteAudioLocally(url: String) async throws {
        guard let localURL = URL(string: url) else { return }
        try? FileManager.default.removeItem(at: localURL)
    }

    private func deleteAudioFromFirebase(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
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
