//
//  AuthService.swift
//  VintageVoice
//
//  Handles user authentication and profile management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    init() {
        setupAuthListener()
    }

    // MARK: - Auth State Listener

    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserProfile(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }

    // MARK: - Sign In / Sign Up

    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.signInAnonymously()
            try await createUserProfile(uid: result.user.uid)
        } catch {
            errorMessage = "Failed to sign in: \(error.localizedDescription)"
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch {
            errorMessage = "Failed to sign in: \(error.localizedDescription)"
            throw error
        }
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            try await createUserProfile(uid: result.user.uid)
        } catch {
            errorMessage = "Failed to sign up: \(error.localizedDescription)"
            throw error
        }
    }

    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - User Profile Management

    private func createUserProfile(uid: String) async throws {
        let profile = UserProfile(id: uid)
        let data = try Firestore.Encoder().encode(profile)

        try await db.collection("users").document(uid).setData(data)
        self.currentUser = profile
        self.isAuthenticated = true
    }

    func loadUserProfile(uid: String) {
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let profile = try? Firestore.Decoder().decode(UserProfile.self, from: data) else {
                return
            }

            self?.currentUser = profile
            self?.isAuthenticated = true
        }
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        let data = try Firestore.Encoder().encode(profile)
        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    // MARK: - Partner Linking

    func linkPartner(partnerID: String) async throws {
        guard var profile = currentUser else { return }

        profile.partnerID = partnerID
        try await updateUserProfile(profile)
    }

    func unlinkPartner() async throws {
        guard var profile = currentUser else { return }

        profile.partnerID = nil
        try await updateUserProfile(profile)
    }
}
