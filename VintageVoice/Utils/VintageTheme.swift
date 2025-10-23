//
//  VintageTheme.swift
//  VintageVoice
//
//  Vintage theme colors, typography, and styling
//

import SwiftUI

// MARK: - Colors

extension Color {
    // Vintage sepia tones
    static let vintageSepia = Color(red: 0.96, green: 0.93, blue: 0.85)
    static let vintageParchment = Color(red: 0.95, green: 0.91, blue: 0.79)
    static let vintageInk = Color(red: 0.20, green: 0.16, blue: 0.12)
    static let vintageBrown = Color(red: 0.45, green: 0.35, blue: 0.25)

    // Wax seal colors
    static let waxRed = Color(red: 0.65, green: 0.12, blue: 0.15)
    static let waxGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let waxBlue = Color(red: 0.15, green: 0.25, blue: 0.45)

    // Stamp tier colors
    static let stampBronze = Color(red: 0.80, green: 0.50, blue: 0.20)
    static let stampSilver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let stampGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let stampPlatinum = Color(red: 0.90, green: 0.89, blue: 0.89)
    static let stampDiamond = Color(red: 0.70, green: 0.85, blue: 0.95)
    static let stampSpark = Color(red: 0.95, green: 0.55, blue: 0.25)

    // UI accents
    static let vintageAccent = Color(red: 0.60, green: 0.40, blue: 0.20)
    static let vintageBackground = Color(red: 0.98, green: 0.96, blue: 0.92)
}

// MARK: - Typography

extension Font {
    // Vintage font styles
    static let vintageTitle = Font.custom("Baskerville", size: 32).weight(.semibold)
    static let vintageHeadline = Font.custom("Baskerville", size: 24).weight(.medium)
    static let vintageBody = Font.custom("Georgia", size: 16)
    static let vintageCaption = Font.custom("Georgia", size: 14)
    static let vintageScript = Font.custom("Snell Roundhand", size: 20)

    // Fallback to system fonts if custom fonts unavailable
    static let vintageTitleFallback = Font.system(size: 32, weight: .semibold, design: .serif)
    static let vintageHeadlineFallback = Font.system(size: 24, weight: .medium, design: .serif)
    static let vintageBodyFallback = Font.system(size: 16, design: .serif)
}

// MARK: - Styling Helpers

struct VintageCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.vintageParchment)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.vintageBrown.opacity(0.3), lineWidth: 1)
            )
    }
}

struct VintageButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vintageBody)
            .foregroundColor(isDestructive ? .white : .vintageInk)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                isDestructive ? Color.waxRed : Color.vintageParchment
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.vintageBrown.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func vintageCard() -> some View {
        self.modifier(VintageCardStyle())
    }
}

// MARK: - Stamp Tier Colors

extension StampTier {
    var color: Color {
        switch self {
        case .bronze: return .stampBronze
        case .silver: return .stampSilver
        case .gold: return .stampGold
        case .platinum: return .stampPlatinum
        case .diamond: return .stampDiamond
        case .spark: return .stampSpark
        }
    }
}

// MARK: - Animations

struct WaxSealAnimation {
    static let duration: Double = 1.5

    static func sealAnimation() -> Animation {
        .easeInOut(duration: duration)
    }

    static func drippingWax() -> Animation {
        .spring(response: 0.6, dampingFraction: 0.7)
    }
}
