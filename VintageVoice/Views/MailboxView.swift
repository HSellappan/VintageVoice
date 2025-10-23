//
//  MailboxView.swift
//  VintageVoice
//
//  Main mailbox screen showing delivered letters (FR-HIDE-01)
//

import SwiftUI

struct MailboxView: View {
    @StateObject private var letterService = LetterService()
    @EnvironmentObject var authService: AuthService
    @State private var showComposeSheet = false
    @State private var selectedLetter: Letter?

    var body: some View {
        NavigationView {
            ZStack {
                Color.vintageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    if letterService.receivedLetters.isEmpty {
                        emptyStateView
                    } else {
                        // Letter list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(letterService.receivedLetters) { letter in
                                    EnvelopeCard(letter: letter)
                                        .onTapGesture {
                                            selectedLetter = letter
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showComposeSheet) {
                ComposeLetterView()
            }
            .sheet(item: $selectedLetter) { letter in
                LetterDetailView(letter: letter)
            }
            .onAppear {
                if let userID = authService.currentUser?.id {
                    letterService.fetchReceivedLetters(for: userID)
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Mailbox")
                    .font(.vintageTitle)
                    .foregroundColor(.vintageInk)

                Spacer()

                // Compose button
                Button(action: { showComposeSheet = true }) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.waxRed)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)

            // Streak counter
            if let streak = authService.currentUser?.streakCount, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) day streak")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.vintageParchment)
                .cornerRadius(12)
            }

            Divider()
                .background(Color.vintageBrown.opacity(0.3))
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .background(Color.vintageSepia)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.open")
                .font(.system(size: 80))
                .foregroundColor(.vintageBrown.opacity(0.3))

            Text("Your mailbox is empty")
                .font(.vintageHeadline)
                .foregroundColor(.vintageInk)

            Text("Letters appear here when they arrive")
                .font(.vintageBody)
                .foregroundColor(.vintageBrown)
                .multilineTextAlignment(.center)

            Button(action: { showComposeSheet = true }) {
                Text("Send a letter")
            }
            .buttonStyle(VintageButtonStyle())
            .padding(.top, 16)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Envelope Card

struct EnvelopeCard: View {
    let letter: Letter

    @State private var isNewlyDelivered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Wax seal indicator
                Circle()
                    .fill(letter.status == .opened ? Color.gray : Color.waxRed)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice Letter")
                        .font(.vintageHeadline)
                        .foregroundColor(.vintageInk)

                    Text(formatDate(letter.deliverAt))
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }

                Spacer()

                if isNewlyDelivered {
                    Text("NEW")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.waxRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.waxRed.opacity(0.1))
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.vintageBrown)
            }

            // Status indicator
            if letter.status == .purged {
                Text("Listened (auto-purged)")
                    .font(.vintageCaption)
                    .foregroundColor(.gray)
                    .italic()
            } else if letter.status == .opened {
                Text("Opened")
                    .font(.vintageCaption)
                    .foregroundColor(.vintageBrown)
            }
        }
        .padding()
        .vintageCard()
        .onAppear {
            // Show "NEW" badge if delivered in last 5 minutes
            let timeSinceDelivery = Date().timeIntervalSince(letter.deliverAt)
            isNewlyDelivered = timeSinceDelivery < 300 && letter.status == .delivered
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MailboxView()
        .environmentObject(AuthService())
}
