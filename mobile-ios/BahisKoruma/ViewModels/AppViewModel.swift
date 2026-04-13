import Foundation
import SwiftUI

// MARK: - App Screen

enum AppScreen {
    case welcome
    case register
    case domains
}

// MARK: - AppViewModel

@MainActor
final class AppViewModel: ObservableObject {

    @Published var screen: AppScreen = .welcome
    @Published var apiKey: String = ""
    @Published var user: UserResponse?

    // Domain list state
    @Published var domains: [Domain] = []
    @Published var isLoadingDomains = false
    @Published var domainsError: String?

    // Register state
    @Published var isRegistering = false
    @Published var registerError: String?

    private let keychainKey = "bahiskoruma.apiKey"

    init() {
        if let saved = UserDefaults.standard.string(forKey: keychainKey), !saved.isEmpty {
            apiKey = saved
            screen = .domains
        }
    }

    // MARK: - Register

    func register(email: String) async {
        guard !email.isEmpty, email.contains("@") else {
            registerError = L("register.error.invalid_email")
            return
        }

        isRegistering = true
        registerError = nil

        do {
            let response = try await APIService.registerUser(email: email)
            user = response
            saveApiKey(response.apiKey)
        } catch {
            registerError = error.localizedDescription
        }

        isRegistering = false
    }

    // MARK: - Domains

    func loadDomains() async {
        guard !apiKey.isEmpty else { return }

        isLoadingDomains = true
        domainsError = nil

        do {
            domains = try await APIService.fetchDomains(apiKey: apiKey)
        } catch {
            domainsError = error.localizedDescription
        }

        isLoadingDomains = false
    }

    // MARK: - Navigation

    func goToRegister() {
        screen = .register
    }

    func logout() {
        apiKey = ""
        user = nil
        domains = []
        UserDefaults.standard.removeObject(forKey: keychainKey)
        screen = .welcome
    }

    // MARK: - Private

    private func saveApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: keychainKey)
        screen = .domains
    }
}
