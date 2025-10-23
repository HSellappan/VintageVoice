//
//  VintageVoiceApp.swift
//  VintageVoice
//
//  Created by Harold S on 10/22/25.
//

import SwiftUI
import FirebaseCore

@main
struct VintageVoiceApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared

    init() {
        // Configure Firebase on app launch
        FirebaseManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseManager)
        }
    }
}
