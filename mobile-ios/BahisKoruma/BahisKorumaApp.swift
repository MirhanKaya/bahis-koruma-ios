import SwiftUI

@main
struct BahisKorumaApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var subscriptionVM = SubscriptionViewModel()

    var body: some Scene {
        WindowGroup {
            AppFlowView()
                .environmentObject(viewModel)
                .environmentObject(subscriptionVM)
                // Sync subscription state when registration succeeds
                .onChange(of: viewModel.user?.apiKey) { apiKey in
                    guard apiKey != nil,
                          let plan = viewModel.user?.plan,
                          let expiresAt = viewModel.user?.expiresAt else { return }
                    subscriptionVM.configure(plan: plan, expiresAt: expiresAt)
                }
                // Clear subscription state on logout
                .onChange(of: viewModel.screen) { screen in
                    if screen == .welcome {
                        subscriptionVM.reset()
                    }
                }
                // Reload domains after successful purchase
                .onChange(of: subscriptionVM.purchaseSucceeded) { succeeded in
                    if succeeded {
                        viewModel.showSubscription = false
                        subscriptionVM.purchaseSucceeded = false
                        Task { await viewModel.loadDomains() }
                    }
                }
        }
    }
}

// MARK: - App Flow Router

struct AppFlowView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            switch viewModel.screen {
            case .welcome:
                WelcomeView()
            case .register:
                RegisterView()
            case .domains:
                DomainListView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.screen)
    }
}
