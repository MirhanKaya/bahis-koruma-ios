import SwiftUI

// MARK: - Screen 2: Email Registration

struct RegisterView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var email = ""
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            // Dismiss keyboard on background tap
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { emailFocused = false }

            VStack(spacing: 0) {

                // ── Header Banner ──────────────────────────────
                headerBanner

                // ── Form ──────────────────────────────────────
                VStack(spacing: 20) {
                    emailField
                    errorBanner
                    continueButton
                    noteText
                }
                .padding(24)

                Spacer()

                backButton
            }
        }
        .onSubmit { submitForm() }
    }

    // MARK: - Sub-views

    private var headerBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.white)
                Text(L("register.title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(L("register.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("register.email.label"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField(L("register.email.placeholder"), text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($emailFocused)
                .font(.system(size: 16))
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.registerError != nil
                                ? Color(hex: "#e63946")
                                : Color(.separator).opacity(0.4),
                            lineWidth: 1
                        )
                )
                .onChange(of: email) { _ in
                    viewModel.clearRegisterError()
                }
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.registerError {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                Text(error)
                    .font(.system(size: 14))
            }
            .foregroundColor(Color(hex: "#e63946"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#e63946").opacity(0.08))
            .cornerRadius(10)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }

    private var continueButton: some View {
        Button { submitForm() } label: {
            ZStack {
                if viewModel.isRegistering {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text(L("register.loading"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    Text(L("register.button.continue"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(buttonBackground)
            .cornerRadius(14)
        }
        .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isRegistering)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRegistering)
    }

    private var buttonBackground: Color {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isRegistering {
            return Color(hex: "#1a1a2e").opacity(0.35)
        }
        return Color(hex: "#1a1a2e")
    }

    private var noteText: some View {
        Text(L("register.note"))
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var backButton: some View {
        Button {
            emailFocused = false
            viewModel.screen = .welcome
        } label: {
            Text(L("button.back"))
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Actions

    private func submitForm() {
        emailFocused = false
        Task { await viewModel.register(email: email) }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppViewModel())
}
