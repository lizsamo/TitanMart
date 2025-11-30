//
//  Theme.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

// MARK: - CSUF Color Theme
extension Color {
    // CSUF Brand Colors
    static let titanBlue = Color(red: 0/255, green: 47/255, blue: 108/255) // #002F6C
    static let titanOrange = Color(red: 255/255, green: 105/255, blue: 0/255) // #FF6900

    // App Colors
    static let primaryAccent = titanBlue
    static let secondaryAccent = titanOrange
    static let cardBackground = Color(.systemBackground)
    static let cardBorder = Color(.systemGray5)

    // Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = titanBlue
}

// MARK: - Typography
extension Font {
    static let appTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let cardTitle = Font.system(size: 16, weight: .semibold, design: .default)
    static let bodyText = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let priceText = Font.system(size: 20, weight: .bold, design: .rounded)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

// MARK: - Shadow
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    func lightShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.titanBlue, Color.titanBlue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(CornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.titanBlue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.titanBlue.opacity(0.1))
            .cornerRadius(CornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.medium)
            .cardShadow()
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
