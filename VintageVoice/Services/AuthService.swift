//
//  AuthService.swift
//  VintageVoice
//
//  Handles user authentication and profile management (LOCAL ONLY)
//

import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userDefaultsKey = "VintageVoice_CurrentUser"
    private let userDefaults = UserDefaults.standard

    init() {
        loadSavedUser()
    }

    // MARK: - Local Storage

    private func loadSavedUser() {
        if let data = userDefaults.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    private func saveUser(_ user: UserProfile) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: userDefaultsKey)
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    // MARK: - Sign In / Sign Up

    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }

        // Create a new local user
        let newUser = UserProfile(id: UUID().uuidString)
        saveUser(newUser)
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate sign in (just create a user)
        let user = UserProfile(id: UUID().uuidString)
        saveUser(user)
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate sign up (just create a user)
        let user = UserProfile(id: UUID().uuidString)
        saveUser(user)
    }

    func signOut() throws {
        userDefaults.removeObject(forKey: userDefaultsKey)
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - User Profile Management

    func updateUserProfile(_ profile: UserProfile) async throws {
        saveUser(profile)
    }

    // MARK: - Partner Linking

    func linkPartner(partnerID: String) async throws {
        guard var profile = currentUser else { return }
        profile.partnerID = partnerID
        saveUser(profile)
    }

    func unlinkPartner() async throws {
        guard var profile = currentUser else { return }
        profile.partnerID = nil
        saveUser(profile)
    }
}
