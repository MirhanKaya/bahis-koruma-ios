import Foundation
import SwiftUI

// MARK: - SubscriptionViewModel
//
// Owns all subscription / paywall logic.
// Persists plan & expiry in UserDefaults across app launches.
//
// RevenueCat integration checklist:
//   1. Add RevenueCat SDK:  File → Add Package → https://github.com/RevenueCat/purchases-ios
//   2. In BahisKorumaApp.init(): Purchases.configure(withAPIKey: "<RC_API_KEY>")
//   3. Replace every "TODO: REVENUECAT" stub below with real SDK calls
//   4. Map RevenueCat Offering packages to SubscriptionPlan cases
//   5. Call verifyReceiptOnForeground() from scene phase .active

@MainActor
final class SubscriptionViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedPlan: SubscriptionPlan = .trial
    @Published var status: SubscriptionStatus = .inactive

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseSucceeded = false

    // MARK: - Computed

    var isPremium: Bool { status.isActive }
    var currentPlan: SubscriptionPlan { status.plan }

    /// True when the user previously had a subscription but it has now expired.
    var isExpired: Bool {
        status.plan.isPremium && !status.isActive
    }

    // MARK: - UserDefaults Keys

    private let planKey   = "bahiskoruma.sub.plan"
    private let expiryKey = "bahiskoruma.sub.expiry"

    // MARK: - Init (restores persisted state)

    init() {
        if let raw = UserDefaults.standard.string(forKey: planKey) {
            let plan = SubscriptionPlan(rawValue: raw) ?? .none
            let expiry = UserDefaults.standard.object(forKey: expiryKey) as? Date
            status = SubscriptionStatus(plan: plan, expiresAt: expiry)
        }
    }

    // MARK: - Configure from Backend Response
    //
    // Call this after a successful register or login.
    // The backend UserResponse provides plan (e.g. "trial") and expiresAt (ISO 8601).

    func configure(plan: String, expiresAt: String) {
        let subscriptionPlan = SubscriptionPlan(serverValue: plan)
        let expiry = parseDate(expiresAt)
        status = SubscriptionStatus(plan: subscriptionPlan, expiresAt: expiry)
        persist(plan: plan, expiry: expiry)
    }

    /// Called when the API returns 403. Marks the subscription as expired.
    func markExpired() {
        status = SubscriptionStatus(plan: status.plan == .none ? .trial : status.plan,
                                    expiresAt: Date.distantPast)
        persist(plan: status.plan.rawValue, expiry: Date.distantPast)
    }

    func reset() {
        status = .inactive
        selectedPlan = .trial
        errorMessage = nil
        purchaseSucceeded = false
        UserDefaults.standard.removeObject(forKey: planKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
    }

    // MARK: - Start Free Trial
    //
    // TODO: REVENUECAT — replace stub body with:
    //
    //   do {
    //       let offerings = try await Purchases.shared.offerings()
    //       guard let package = offerings.current?.availablePackages
    //               .first(where: { $0.identifier == "$rc_annual" || ... }) else { return }
    //       let result = try await Purchases.shared.purchase(package: package)
    //       handleCustomerInfo(result.customerInfo)
    //   } catch {
    //       if (error as NSError).code != Purchases.ErrorCode.purchaseCancelledError.rawValue {
    //           errorMessage = error.localizedDescription
    //       }
    //   }

    func startFreeTrial() async {
        isLoading = true
        errorMessage = nil

        // Stub — simulates a 1 second network call
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // TODO: REVENUECAT — remove stub, use SDK above
        let expiry = Date().addingTimeInterval(7 * 86_400)
        status = SubscriptionStatus(plan: .trial, expiresAt: expiry)
        persist(plan: SubscriptionPlan.trial.rawValue, expiry: expiry)
        purchaseSucceeded = true

        isLoading = false
    }

    // MARK: - Purchase Paid Plan (pro_6 / pro_12)
    //
    // TODO: REVENUECAT — replace stub body with:
    //
    //   do {
    //       let offerings = try await Purchases.shared.offerings()
    //       let identifier = plan == .pro6 ? "<RC_6MO_PACKAGE_ID>" : "<RC_12MO_PACKAGE_ID>"
    //       guard let package = offerings.current?.availablePackages
    //               .first(where: { $0.identifier == identifier }) else { return }
    //       let result = try await Purchases.shared.purchase(package: package)
    //       handleCustomerInfo(result.customerInfo)
    //   } catch {
    //       if (error as NSError).code != Purchases.ErrorCode.purchaseCancelledError.rawValue {
    //           errorMessage = error.localizedDescription
    //       }
    //   }

    func purchase(plan: SubscriptionPlan) async {
        guard plan != .none else { return }

        isLoading = true
        errorMessage = nil

        // Stub — simulates a 1.2 second network call
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        // TODO: REVENUECAT — remove stub, use SDK above
        let duration: TimeInterval = plan == .pro6 ? 180 * 86_400 : 365 * 86_400
        let expiry = Date().addingTimeInterval(duration)
        status = SubscriptionStatus(plan: plan, expiresAt: expiry)
        persist(plan: plan.rawValue, expiry: expiry)
        purchaseSucceeded = true

        isLoading = false
    }

    // MARK: - Restore Purchases
    //
    // TODO: REVENUECAT — replace stub body with:
    //
    //   do {
    //       let info = try await Purchases.shared.restorePurchases()
    //       if handleCustomerInfo(info) {
    //           purchaseSucceeded = true
    //       } else {
    //           errorMessage = L("sub.restore.none_found")
    //       }
    //   } catch {
    //       errorMessage = error.localizedDescription
    //   }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        // Stub — simulates a 0.8 second network call
        try? await Task.sleep(nanoseconds: 800_000_000)

        // TODO: REVENUECAT — remove stub, use SDK above
        errorMessage = L("sub.restore.none_found")

        isLoading = false
    }

    // MARK: - Verify Receipt on App Foreground
    //
    // Call from BahisKorumaApp using .onChange(of: scenePhase) when phase == .active.
    //
    // TODO: REVENUECAT — replace stub body with:
    //
    //   do {
    //       let info = try await Purchases.shared.customerInfo()
    //       handleCustomerInfo(info)
    //   } catch {
    //       // Silent — do not surface foreground-check errors to user
    //   }

    func verifyReceiptOnForeground() async {
        // TODO: REVENUECAT — implement foreground refresh
    }

    // MARK: - Private Helpers

    private func parseDate(_ iso: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)
    }

    private func persist(plan: String, expiry: Date?) {
        UserDefaults.standard.set(plan, forKey: planKey)
        if let expiry {
            UserDefaults.standard.set(expiry, forKey: expiryKey)
        } else {
            UserDefaults.standard.removeObject(forKey: expiryKey)
        }
    }

    // TODO: REVENUECAT — uncomment and implement when SDK is integrated
    // @discardableResult
    // private func handleCustomerInfo(_ info: CustomerInfo) -> Bool {
    //     let entitlement = info.entitlements["premium"]
    //     guard let active = entitlement, active.isActive else {
    //         status = .inactive
    //         persist(plan: SubscriptionPlan.none.rawValue, expiry: nil)
    //         return false
    //     }
    //     let plan: SubscriptionPlan
    //     switch active.productIdentifier {
    //     case "<RC_6MO_PRODUCT_ID>":  plan = .pro6
    //     case "<RC_12MO_PRODUCT_ID>": plan = .pro12
    //     default:                     plan = .trial
    //     }
    //     let expiry = active.expirationDate
    //     status = SubscriptionStatus(plan: plan, expiresAt: expiry)
    //     persist(plan: plan.rawValue, expiry: expiry)
    //     return true
    // }
}
