import Foundation

struct Domain: Codable, Identifiable {
    let id: Int
    let domain: String
    let category: String
    let isBlocked: Bool
    let createdAt: String
}

struct DomainsResponse: Codable {
    let success: Bool
    let count: Int?
    let data: [Domain]
    let error: String?
}
