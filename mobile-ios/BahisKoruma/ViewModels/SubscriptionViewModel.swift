import Foundation
import SwiftUI

// MARK: - SubscriptionViewModel
//
// This view model owns all subscription / paywall logic.
// RevenueCat integration points are marked with TODO: REVENUECAT.
//
// Integration checklist:
//   1. Add RevenueCat SDK via Swift Package Manager
//   2. Replace TODO: REVENUECAT blocks with actual SDK calls
//   3. Call configure(apiKey:) in BahisKorumaApp.init()
//   4. Map RevenueCat Offering → SubscriptionPlan
//   5. Call verifyReceipt() on app foreground to refresh status

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

    // MARK: - Configure from Backend Response
    //
    // Called after a successful registration or login.
    // The backend returns plan + expiresAt — use these to set local status.

    func configure(plan: String, expiresAt: String) {
        let subscriptionPlan = SubscriptionPlan(serverValue: plan)
        let expiry = ISO8601DateFormatter().date(from: expiresAt)
        status = SubscriptionStatus(plan: subscriptionPlan, expiresAt: expiry)
    }

    func reset() {
        status = .inactive
        selectedPlan = .trial
        errorMessage = nil
        purchaseSucceeded = false
    }

    // MARK: - Start Free Trial
    //
    // TODO: REVENUECAT
    // Replace this stub with:
    //   let offerings = try await Purchases.shared.offerings()
    //   let package = offerings.current?.availablePackages.first { $0.identifier == "trial" }
    //   let result = try await Purchases.shared.purchase(package: package!)
    //   handle result.customerInfo

    func startFreeTrial() async {
        isLoading = true
        errorMessage = nil

        // --- Stub: simulate network delay ---
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // ------------------------------------

        // TODO: REVENUECAT — replace stub with real purchase
        // On success:
        //   status = SubscriptionStatus(plan: .trial, expiresAt: Date().addingTimeInterval(7 * 86400))
        //   purchaseSucceeded = true
        // On failure:
        //   errorMessage = error.localizedDescription

        // Stub success:
        status = SubscriptionStatus(plan: .trial, expiresAt: Date().addingTimeInterval(7 * 86400))
        purchaseSucceeded = true

        isLoading = false
    }

    // MARK: - Purchase Plan
    //
    // TODO: REVENUECAT
    // Replace this stub with:
    //   let offerings = try await Purchases.shared.offerings()
    //   let package = offerings.current?.availablePackages.first { mapToRevenueCat($0) == plan }
    //   let result = try await Purchases.shared.purchase(package: package!)
    //   handleCustomerInfo(result.customerInfo)

    func purchase(plan: SubscriptionPlan) async {
        guard plan != .none else { return }

        isLoading = true
        errorMessage = nil

        // --- Stub: simulate network delay ---
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        // ------------------------------------

        // TODO: REVENUECAT — replace stub with real purchase
        let duration: TimeInterval = plan == .pro6
            ? 180 * 86400
            : 365 * 86400

        // Stub success:
        status = SubscriptionStatus(plan: plan, expiresAt: Date().addingTimeInterval(duration))
        purchaseSucceeded = true

        isLoading = false
    }

    // MARK: - Restore Purchases
    //
    // TODO: REVENUECAT
    // Replace this stub with:
    //   let customerInfo = try await Purchases.shared.restorePurchases()
    //   handleCustomerInfo(customerInfo)

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        // --- Stub: simulate network delay ---
        try? await Task.sleep(nanoseconds: 800_000_000)
        // ------------------------------------

        // TODO: REVENUECAT — replace stub with real restore
        // On success: update status from customerInfo
        // On failure: set errorMessage

        // Stub: no purchases to restore
        errorMessage = L("sub.restore.none_found")

        isLoading = false
    }

    // MARK: - Verify Receipt on Foreground
    //
    // TODO: REVENUECAT
    // Call this from .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
    //   let info = try await Purchases.shared.customerInfo()
    //   handleCustomerInfo(info)

    func verifyReceiptOnForeground() async {
        // TODO: REVENUECAT — implement foreground refresh
    }

    // MARK: - Private Helpers
    //
    // TODO: REVENUECAT — implement when SDK is integrated
    // private func handleCustomerInfo(_ info: CustomerInfo) {
    //     if let expiry = info.expirationDate(forEntitlement: "premium") {
    //         let plan = planFromEntitlement(info)
    //         status = SubscriptionStatus(plan: plan, expiresAt: expiry)
    //     } else {
    //         status = .inactive
    //     }
    // }
}
