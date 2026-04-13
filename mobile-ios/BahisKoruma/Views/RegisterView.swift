import SwiftUI

// MARK: - Screen 2: Email Registration

struct RegisterView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var email = ""
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundColor(.white)
                            Text(L("register.title"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("register.email.label"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

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
                                            : Color(.separator).opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                    }

                    // Error message
                    if let error = viewModel.registerError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                            Text(error)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color(hex: "#e63946"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Register button
                    Button {
                        emailFocused = false
                        Task { await viewModel.register(email: email) }
                    } label: {
                        ZStack {
                            if viewModel.isRegistering {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(L("register.button.continue"))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            email.isEmpty || viewModel.isRegistering
                                ? Color(hex: "#1a1a2e").opacity(0.4)
                                : Color(hex: "#1a1a2e")
                        )
                        .cornerRadius(14)
                    }
                    .disabled(email.isEmpty || viewModel.isRegistering)

                    // Info note
                    Text(L("register.note"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(24)

                Spacer()

                // Back
                Button {
                    viewModel.screen = .welcome
                } label: {
                    Text(L("button.back"))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
            }
        }
        .onSubmit { Task { await viewModel.register(email: email) } }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppViewModel())
}
