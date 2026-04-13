import SwiftUI

// MARK: - Screen 1: Welcome / Onboarding

struct WelcomeView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.bottom, 28)

                // Title
                Text(L("main.title"))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text(L("main.subtitle"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "#e63946"))
                    .padding(.top, 6)

                Text(L("main.description"))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 16)

                Spacer()

                // Feature pills
                VStack(spacing: 12) {
                    FeaturePill(icon: "brain.head.profile", text: L("feature.ai.title"),      color: "#7b2ff7")
                    FeaturePill(icon: "xmark.shield.fill",  text: L("feature.domains.title"), color: "#e63946")
                    FeaturePill(icon: "bolt.shield.fill",   text: L("feature.novpn.title"),   color: "#2a9d8f")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

                // CTA
                Button {
                    viewModel.goToRegister()
                } label: {
                    Text(L("button.get_started"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "#e63946"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - Feature Pill

private struct FeaturePill: View {
    let icon: String
    let text: String
    let color: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: color))
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color).opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppViewModel())
}
