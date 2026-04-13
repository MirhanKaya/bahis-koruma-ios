import SwiftUI

@main
struct BahisKorumaApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            AppFlowView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - App Flow Router

struct AppFlowView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        switch viewModel.screen {
        case .welcome:
            WelcomeView()
                .transition(.opacity)
        case .register:
            RegisterView()
                .transition(.move(edge: .trailing))
        case .domains:
            DomainListView()
                .transition(.move(edge: .trailing))
        }
    }
}
