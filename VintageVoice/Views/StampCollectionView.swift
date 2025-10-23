//
//  StampCollectionView.swift
//  VintageVoice
//
//  Vintage stamp collection album showing earned stamps
//

import SwiftUI

struct StampCollectionView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    // Sample stamps for demo - in production, fetch from Firestore
    @State private var stamps: [Stamp] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.vintageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats
                        statsView

                        // Stamp tiers
                        VStack(alignment: .leading, spacing: 24) {
                            stampTierSection(tier: .spark, title: "Daily Spark Stamps")
                            stampTierSection(tier: .bronze, title: "Bronze Stamps")
                            stampTierSection(tier: .silver, title: "Silver Stamps")
                            stampTierSection(tier: .gold, title: "Gold Stamps")
                            stampTierSection(tier: .platinum, title: "Platinum Stamps")
                            stampTierSection(tier: .diamond, title: "Diamond Stamps")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Stamp Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.vintageInk)
                }
            }
        }
    }

    // MARK: - Stats View

    private var statsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(stamps.count)")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.vintageInk)

                    Text("Total Stamps")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }

                VStack(spacing: 4) {
                    Text("\(authService.currentUser?.postagePoints ?? 0)")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.vintageInk)

                    Text("Postage Points")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }

                VStack(spacing: 4) {
                    Text("\(authService.currentUser?.streakCount ?? 0)")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.vintageInk)

                    Text("Day Streak")
                        .font(.vintageCaption)
                        .foregroundColor(.vintageBrown)
                }
            }
            .padding()
            .background(Color.vintageParchment)
            .cornerRadius(16)
        }
    }

    // MARK: - Stamp Tier Section

    private func stampTierSection(tier: StampTier, title: String) -> some View {
        let tierStamps = stamps.filter { $0.tier == tier }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.vintageHeadline)
                    .foregroundColor(.vintageInk)

                Spacer()

                Text("\(tierStamps.count)")
                    .font(.vintageBody)
                    .foregroundColor(.vintageBrown)
            }

            if tierStamps.isEmpty {
                emptyTierView(tier: tier)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80))
                ], spacing: 16) {
                    ForEach(tierStamps) { stamp in
                        StampView(stamp: stamp)
                    }
                }
            }

            Divider()
                .background(Color.vintageBrown.opacity(0.3))
        }
    }

    private func emptyTierView(tier: StampTier) -> some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "questionmark")
                        .foregroundColor(.gray)
                )

            Text("No \(tier.displayName.lowercased()) stamps yet")
                .font(.vintageCaption)
                .foregroundColor(.vintageBrown.opacity(0.7))
                .italic()

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Stamp View

struct StampView: View {
    let stamp: Stamp

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(stamp.tier.color)
                .frame(width: 70, height: 70)
                .overlay(
                    VStack(spacing: 4) {
                        if stamp.tier == .spark {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        } else {
                            Text(stamp.tier.displayName.prefix(1))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("+\(stamp.tier.postagePoints)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                )
                .shadow(radius: 4)

            Text(formatDate(stamp.earnedAt))
                .font(.system(size: 10))
                .foregroundColor(.vintageBrown)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    StampCollectionView()
        .environmentObject(AuthService())
}
