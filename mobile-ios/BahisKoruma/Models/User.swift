import Foundation

struct UserResponse: Codable {
    let id: String
    let email: String
    let apiKey: String
    let plan: String
    let expiresAt: String
    let createdAt: String
}

struct RegisterResponse: Codable {
    let success: Bool
    let isNew: Bool?
    let data: UserResponse
    let error: String?
}
