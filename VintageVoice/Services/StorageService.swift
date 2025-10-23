//
//  StorageService.swift
//  VintageVoice
//
//  Firebase Storage service for audio file upload/download
//

import Foundation
import FirebaseStorage

class StorageService: ObservableObject {
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false

    private let storage = Storage.storage()

    // MARK: - Upload Audio

    func uploadAudio(localURL: URL, letterID: String) async throws -> String {
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
