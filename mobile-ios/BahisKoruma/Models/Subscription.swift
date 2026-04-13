import Foundation

// MARK: - Subscription Plan

enum SubscriptionPlan: String, CaseIterable {
    case none   = "none"
    case trial  = "trial"
    case pro6   = "pro_6"
    case pro12  = "pro_12"

    var isPremium: Bool {
        self != .none
    }

    /// Initialize from the plan string returned by the backend.
    init(serverValue: String) {
        self = SubscriptionPlan(rawValue: serverValue) ?? .trial
    }

    var localizedTitle: String { L(titleKey) }
    var localizedPrice: String { L(priceKey) }
    var localizedDuration: String { L(durationKey) }
    var localizedBadge: String? { badgeKey.map { L($0) } }

    var titleKey: String {
        switch self {
        case .none:  return ""
        case .trial: return "sub.plan.trial.title"
        case .pro6:  return "sub.plan.pro6.title"
        case .pro12: return "sub.plan.pro12.title"
        }
    }

    var priceKey: String {
        switch self {
        case .none:  return ""
        case .trial: return "sub.plan.trial.price"
        case .pro6:  return "sub.plan.pro6.price"
        case .pro12: return "sub.plan.pro12.price"
        }
    }

    var durationKey: String {
        switch self {
        case .none:  return ""
        case .trial: return "sub.plan.trial.duration"
        case .pro6:  return "sub.plan.pro6.duration"
        case .pro12: return "sub.plan.pro12.duration"
        }
    }

    var badgeKey: String? {
        switch self {
        case .pro6:  return "sub.plan.pro6.badge"
        case .pro12: return "sub.plan.pro12.badge"
        default:     return nil
        }
    }

    var icon: String {
        switch self {
        case .none:  return "shield"
        case .trial: return "gift.fill"
        case .pro6:  return "shield.lefthalf.filled"
        case .pro12: return "shield.fill"
        }
    }

    var accentHex: String {
        switch self {
        case .none:  return "#888888"
        case .trial: return "#2a9d8f"
        case .pro6:  return "#7b2ff7"
        case .pro12: return "#e63946"
        }
    }

    /// The three plans shown on the paywall, in display order.
    static var paywall: [SubscriptionPlan] { [.trial, .pro6, .pro12] }
}

// MARK: - Subscription Status

struct SubscriptionStatus {
    let plan: SubscriptionPlan
    let expiresAt: Date?

    var isActive: Bool {
        guard plan.isPremium else { return false }
        guard let expiry = expiresAt else { return true }
        return expiry > Date()
    }

    static let inactive = SubscriptionStatus(plan: .none, expiresAt: nil)
}
