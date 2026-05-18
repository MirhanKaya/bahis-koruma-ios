import Foundation
import SwiftUI

// MARK: - App Screen

enum AppScreen: Equatable {
    case welcome
    case register
    case domains
}

// MARK: - AppViewModel

@MainActor
final class AppViewModel: ObservableObject {

    // MARK: Navigation
    @Published var screen: AppScreen = .welcome

    // MARK: Auth
    @Published var apiKey: String = ""
    @Published var user: UserResponse?

    // MARK: Subscription Sheet
    /// Set to true to present SubscriptionView as a sheet.
    /// Triggered automatically when the API returns 403 (subscription expired).
    @Published var showSubscription = false

    // MARK: Register State
    @Published var isRegistering = false
    @Published var registerError: String?

    // MARK: Domain State
    @Published var domains: [Domain] = []
    @Published var isLoadingDomains = false
    @Published var domainsError: String?

    // MARK: Local Storage
    private let apiKeyStorageKey = "bahiskoruma.apiKey"

    // MARK: Init

    init() {
        if let saved = UserDefaults.standard.string(forKey: apiKeyStorageKey),
           !saved.isEmpty {
            apiKey = saved
            screen = .domains
        }
    }

    // MARK: - Registration
    // Calls POST /register-api-user, persists apiKey, sets user (plan + expiresAt).
    // BahisKorumaApp observes user?.apiKey change → calls subscriptionVM.configure().

    func register(email: String) async {
        guard isValidEmail(email) else {
            registerError = L("register.error.invalid_email")
            return
        }

        isRegistering = true
        registerError = nil

        do {
            let response = try await APIService.registerUser(email: email)
            user = response
            persistApiKey(response.apiKey)
        } catch {
            registerError = error.localizedDescription
        }

        isRegistering = false
    }

    func clearRegisterError() {
        registerError = nil
    }

    // MARK: - Domain Loading
    // Calls GET /domains with x-api-key header.
    // 401 → auth error displayed in UI.
    // 403 → subscription expired → showSubscription = true (triggers paywall sheet).

    func loadDomains() async {
        guard !apiKey.isEmpty else { return }

        isLoadingDomains = true
        domainsError = nil

        do {
            domains = try await APIService.fetchDomains(apiKey: apiKey)
        } catch APIError.subscriptionExpired {
            // Do not show a generic error — show the paywall instead
            showSubscription = true
        } catch {
            domainsError = error.localizedDescription
        }

        isLoadingDomains = false
    }

    // MARK: - Navigation

    func goToRegister() {
        registerError = nil
        screen = .register
    }

    func logout() {
        apiKey = ""
        user = nil
        domains = []
        showSubscription = false
        UserDefaults.standard.removeObject(forKey: apiKeyStorageKey)
        screen = .welcome
    }

    // MARK: - Private

    private func persistApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: apiKeyStorageKey)
        screen = .domains
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }
}
