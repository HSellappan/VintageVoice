//
//  FirebaseManager.swift
//  VintageVoice
//
//  Central Firebase configuration and initialization
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var currentUser: User?

    let db = Firestore.firestore()
    let storage = Storage.storage()
    let auth = Auth.auth()

    private init() {
        // Firebase is configured in App delegate/AppInit
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    // MARK: - Configuration

    static func configure() {
        FirebaseApp.configure()

        // Enable offline persistence for Firestore
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }
}

// Note: Add these Firebase dependencies via Swift Package Manager:
// - FirebaseAuth
// - FirebaseFirestore
// - FirebaseStorage
// - FirebaseMessaging
//
// Package URL: https://github.com/firebase/firebase-ios-sdk
