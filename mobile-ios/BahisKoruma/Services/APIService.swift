import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
    case unauthorized
    case subscriptionExpired
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return L("error.network")
        case .requestFailed(let c):    return "HTTP \(c)"
        case .decodingFailed:          return L("error.generic")
        case .unauthorized:            return L("error.unauthorized")
        case .subscriptionExpired:     return L("error.subscription_expired")
        case .serverError(let msg):    return msg
        }
    }
}

// MARK: - APIService

struct APIService {

    // ⚠️ API Base URL
    // Development : http://localhost:8000
    // Replit      : replace with your Replit backend URL (port 8000)
    // Example     : https://your-repl-name.replit.dev:8000
    static let baseURL = "http://localhost:8000"

    // MARK: POST /register-api-user

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
            throw APIError.requestFailed(0)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.requestFailed(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(RegisterResponse.self, from: data)
        guard decoded.success else {
            throw APIError.serverError(decoded.error ?? L("error.generic"))
        }
        return decoded.data
    }

    // MARK: GET /domains

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
            throw APIError.requestFailed(0)
        }

        switch http.statusCode {
        case 200...299: break
        case 401: throw APIError.unauthorized
        case 403: throw APIError.subscriptionExpired
        default:  throw APIError.requestFailed(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(DomainsResponse.self, from: data)
        guard decoded.success else {
            throw APIError.serverError(decoded.error ?? L("error.generic"))
        }
        return decoded.data
    }
}
