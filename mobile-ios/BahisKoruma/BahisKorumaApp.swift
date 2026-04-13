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
