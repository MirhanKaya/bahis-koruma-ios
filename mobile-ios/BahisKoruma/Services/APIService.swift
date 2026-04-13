import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case noResponse
    case requestFailed(Int)
    case decodingFailed
    case unauthorized
    case subscriptionExpired
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L("error.network")
        case .noResponse:
            return L("error.no_response")
        case .requestFailed(let code):
            return "\(L("error.request_failed")) (\(code))"
        case .decodingFailed:
            return L("error.generic")
        case .unauthorized:
            return L("error.unauthorized")
        case .subscriptionExpired:
            return L("error.subscription_expired")
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - APIService

/// Handles all network communication with the Bahis Koruma backend.
///
/// Registration flow:
///   1. User enters email in RegisterView
///   2. registerUser(email:) → POST /register-api-user
///   3. Backend returns { success, data: { apiKey, plan, expiresAt, … } }
///   4. apiKey is saved in UserDefaults via AppViewModel
///
/// Domain loading flow:
///   1. fetchDomains(apiKey:) → GET /domains
///   2. Request includes header "x-api-key: <apiKey>"
///   3. Backend returns { success, data: [Domain] }
///
struct APIService {

    // =========================================================
    // ⚠️  API Base URL — update before running on device
    // =========================================================
    // Local development : http://localhost:8000
    // Replit backend    : https://<your-repl>.replit.dev:8000
    // =========================================================
    static let baseURL = "http://localhost:8000"

    // MARK: - POST /register-api-user

    static func registerUser(email: String) async throws -> UserResponse {
        guard let url = URL(string: "\(baseURL)/register-api-user") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email])
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.noResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.requestFailed(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)
            guard decoded.success else {
                throw APIError.serverError(decoded.error ?? L("error.generic"))
            }
            return decoded.data
        } catch is DecodingError {
            throw APIError.decodingFailed
        }
    }

    // MARK: - GET /domains

    static func fetchDomains(apiKey: String) async throws -> [Domain] {
        guard let url = URL(string: "\(baseURL)/domains") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.noResponse
        }

        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.subscriptionExpired
        default:
            throw APIError.requestFailed(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(DomainsResponse.self, from: data)
            guard decoded.success else {
                throw APIError.serverError(decoded.error ?? L("error.generic"))
            }
            return decoded.data
        } catch is DecodingError {
            throw APIError.decodingFailed
        }
    }
}
