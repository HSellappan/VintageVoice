//
//  ContentView.swift
//  VintageVoice
//
//  Main app coordinator - handles auth and navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var sparkService = DailySparkService()
    @StateObject private var pushService = PushNotificationService.shared

    @State private var showDailySpark = false
    @State private var showStampCollection = false

    var body: some View {
        Group {
            if authService.isAuthenticated {
                mainAppView
            } else {
                WelcomeView()
                    .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showDailySpark) {
            if let prompt = sparkService.todaysPrompt {
                DailySparkView(prompt: prompt)
                    .environmentObject(authService)
            }
        }
        .sheet(isPresented: $showStampCollection) {
            StampCollectionView()
                .environmentObject(authService)
        }
        .task {
            // Request notification permission
            _ = await pushService.requestPermission()

            // Set notification delegate
            UNUserNotificationCenter.current().delegate = pushService

            // Listen for Daily Spark notifications
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DailySpark"),
                object: nil,
                queue: .main
            ) { notification in
                if let userID = authService.currentUser?.id {
                    Task {
                        await sparkService.fetchTodaysPrompt(for: userID)
                        showDailySpark = true
                    }
                }
            }
        }
    }

    private var mainAppView: some View {
        TabView {
            MailboxView()
                .environmentObject(authService)
                .tabItem {
                    Label("Mailbox", systemImage: "envelope.fill")
                }

            ProfileView()
                .environmentObject(authService)
                .environmentObject(sparkService)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.vintageAccent)
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.vintageBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App icon/logo
                ZStack {
                    Circle()
                        .fill(Color.waxRed)
                        .frame(width: 120, height: 120)

                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                VStack(spacing: 12) {
                    Text("VintageVoice")
                        .font(.vintageTitle)
                        .foregroundColor(.vintageInk)

                    Text("Voice letters for long-distance love")
                        .font(.vintageBody)
                        .foregroundColor(.vintageBrown)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(.vintageInk)
                } else {
                    Button(action: signIn) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(VintageButtonStyle())
                }

                Text("Anonymous sign-in for demo")
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown.opacity(0.7))
            }
            .padding(40)
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            try? await authService.signInAnonymously()
            isLoading = false
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var sparkService: DailySparkService
    @State private var showStampCollection = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.vintageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.vintageParchment)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.vintageBrown)
                                )

                            if let user = authService.currentUser {
                                VStack(spacing: 4) {
                                    Text("User ID")
                                        .font(.vintageCaption)
                                        .foregroundColor(.vintageBrown)

                                    Text(String(user.id.prefix(8)))
                                        .font(.vintageBody)
                                        .foregroundColor(.vintageInk)
                                }
                            }
                        }
                        .padding()

                        // Stats
                        HStack(spacing: 20) {
                            statCard(
                                value: "\(authService.currentUser?.postagePoints ?? 0)",
                                label: "Points"
                            )

                            statCard(
                                value: "\(authService.currentUser?.streakCount ?? 0)",
                                label: "Streak"
                            )

                            statCard(
                                value: "\(authService.currentUser?.collectedStamps.count ?? 0)",
                                label: "Stamps"
                            )
                        }
                        .padding(.horizontal)

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: { showStampCollection = true }) {
                                HStack {
                                    Image(systemName: "rectangle.grid.3x2.fill")
                                    Text("Stamp Collection")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .vintageCard()
                            }
                            .foregroundColor(.vintageInk)

                            Button(action: signOut) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                    Spacer()
                                }
                                .padding()
                                .vintageCard()
                            }
                            .foregroundColor(.waxRed)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showStampCollection) {
            StampCollectionView()
                .environmentObject(authService)
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.vintageInk)

            Text(label)
                .font(.vintageCaption)
                .foregroundColor(.vintageBrown)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.vintageParchment)
        .cornerRadius(12)
    }

    private func signOut() {
        try? authService.signOut()
    }
}

#Preview {
    ContentView()
}
