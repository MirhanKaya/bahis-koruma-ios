import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeroSection()
                    FeaturesSection()
                    CTASection()
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Hero Section

private struct HeroSection: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Spacer().frame(height: 80)

                Image(systemName: "shield.checkered")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text(L("main.title"))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                Text(L("main.subtitle"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "#e63946"))

                Text(L("main.description"))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                Spacer().frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
    }
}

// MARK: - Features Section

private struct FeaturesSection: View {
    let features: [FeatureItem] = [
        FeatureItem(icon: "brain.head.profile", titleKey: "feature.ai.title", descKey: "feature.ai.description", color: "#7b2ff7"),
        FeatureItem(icon: "xmark.shield.fill", titleKey: "feature.domains.title", descKey: "feature.domains.description", color: "#e63946"),
        FeatureItem(icon: "bolt.shield.fill", titleKey: "feature.novpn.title", descKey: "feature.novpn.description", color: "#2a9d8f"),
    ]

    var body: some View {
        VStack(spacing: 1) {
            ForEach(features) { feature in
                FeatureRow(item: feature)
            }
        }
        .background(Color(.systemGroupedBackground))
        .padding(.top, 0)
    }
}

private struct FeatureRow: View {
    let item: FeatureItem

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: item.color).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(hex: item.color))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L(item.titleKey))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(L(item.descKey))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - CTA Section

private struct CTASection: View {
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                Text(L("button.get_started"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "#e63946"))
                    .cornerRadius(14)
            }

            Button(action: {}) {
                Text(L("button.learn_more"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#1a1a2e"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Models

private struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let descKey: String
    let color: String
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
