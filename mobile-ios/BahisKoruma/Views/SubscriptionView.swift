import SwiftUI

// MARK: - Subscription / Paywall Screen

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel

    /// True when presented as a sheet over DomainListView (shows a close button).
    var isDismissable: Bool = false
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    planCardsSection
                    ctaSection
                    footerSection
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isDismissable {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .alert(L("sub.error.title"), isPresented: errorBinding) {
            Button(L("button.done"), role: .cancel) {
                subscriptionVM.errorMessage = nil
            }
        } message: {
            Text(subscriptionVM.errorMessage ?? "")
        }
    }

    // MARK: - Error Alert Binding

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { subscriptionVM.errorMessage != nil },
            set: { if !$0 { subscriptionVM.errorMessage = nil } }
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                Spacer().frame(height: 24)

                Image(systemName: "shield.fill")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.white)

                Text(L("sub.header.title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text(L("sub.header.subtitle"))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 28)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.paywall, id: \.rawValue) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: subscriptionVM.selectedPlan == plan,
                    onTap: { subscriptionVM.selectedPlan = plan }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    let plan = subscriptionVM.selectedPlan
                    if plan == .trial {
                        await subscriptionVM.startFreeTrial()
                    } else {
                        await subscriptionVM.purchase(plan: plan)
                    }
                }
            } label: {
                ZStack {
                    if subscriptionVM.isLoading {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(L("sub.cta.loading"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(ctaLabel)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(ctaBackground)
                .cornerRadius(16)
            }
            .disabled(subscriptionVM.isLoading)
            .animation(.easeInOut(duration: 0.2), value: subscriptionVM.isLoading)

            Button {
                Task { await subscriptionVM.restorePurchases() }
            } label: {
                Text(L("sub.restore.button"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .disabled(subscriptionVM.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var ctaLabel: String {
        switch subscriptionVM.selectedPlan {
        case .trial:  return L("sub.cta.trial")
        case .pro6:   return L("sub.cta.subscribe")
        case .pro12:  return L("sub.cta.subscribe")
        case .none:   return L("sub.cta.subscribe")
        }
    }

    private var ctaBackground: Color {
        let hex = subscriptionVM.selectedPlan.accentHex
        return subscriptionVM.isLoading
            ? Color(hex: hex).opacity(0.5)
            : Color(hex: hex)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text(L("sub.footer.cancel"))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(L("sub.footer.terms")) {}
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Button(L("sub.footer.privacy")) {}
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            // TODO: REVENUECAT — link actual Terms and Privacy URLs
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void

    var accent: Color { Color(hex: plan.accentHex) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: plan.icon)
                        .font(.system(size: 20))
                        .foregroundColor(accent)
                }

                // Labels
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.localizedTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        if let badge = plan.localizedBadge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accent)
                                .cornerRadius(5)
                        }
                    }

                    Text(plan.localizedDuration)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Price + selection
                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.localizedPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(accent)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? accent : Color(.separator))
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? accent.opacity(0.18) : Color.black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                x: 0, y: 2
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    SubscriptionView(isDismissable: true)
        .environmentObject(SubscriptionViewModel())
}
