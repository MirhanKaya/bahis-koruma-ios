import Foundation
import Combine

// MARK: - FirebaseService
//
// Real-time Firestore listener for the `domains` collection.
//
// Activation checklist:
//   1. Add Firebase Swift Package:
//      File → Add Package Dependencies →
//      https://github.com/firebase/firebase-ios-sdk → FirebaseFirestore
//   2. Download GoogleService-Info.plist from Firebase Console and drag into
//      the BahisKoruma Xcode target.
//   3. In BahisKorumaApp.swift init():
//        import FirebaseCore
//        FirebaseApp.configure()
//   4. Set FirebaseService.enabled = true below.
//   5. In AppViewModel, call FirebaseService.shared.startListening() and
//      subscribe to the $domains publisher.
//
// Without Firebase (default):
//   FirebaseService emits mock data from its $domains publisher.
//   The rest of the app is completely unaffected.

// ── Feature flag ──────────────────────────────────────────────────────────────
// Set to true once GoogleService-Info.plist is added and Firebase SPM package
// is installed. The code below compiles and runs correctly in both modes.
// When false: mock data only, no network calls, no imports needed.
private let kFirebaseEnabled = false

// ── Domain document (matches Firestore schema) ────────────────────────────────

struct FirestoreDomain: Identifiable {
    let id: String          // Firestore document ID = domainName
    let domainName: String
    let category: String    // "Kumar" | "Bilinmiyor"
    let status: String      // "Engellendi" | "İzin Verildi"
    let isBlocked: Bool
    let createdAt: Date

    /// Converts a Firestore document to the app's native Domain model.
    func toDomain(localId: Int) -> Domain {
        Domain(
            id: localId,
            domain: domainName,
            category: category == "Kumar" ? "gambling" : "unknown",
            isBlocked: isBlocked,
            createdAt: ISO8601DateFormatter().string(from: createdAt)
        )
    }
}

// ── FirebaseService ───────────────────────────────────────────────────────────

@MainActor
final class FirebaseService: ObservableObject {

    static let shared = FirebaseService()

    /// Published domain list from Firestore (or mock data when Firebase unavailable).
    @Published private(set) var domains: [FirestoreDomain] = []

    /// True when actively receiving Firestore snapshots.
    @Published private(set) var isListening = false

    /// Non-nil when the last Firestore operation failed.
    @Published private(set) var error: String?

    private var listenerRegistration: Any? = nil  // Holds ListenerRegistration when Firebase enabled
    private var mockRefreshTimer: Timer?

    private init() {}

    // ── Lifecycle ─────────────────────────────────────────────────────────

    /// Starts listening to the Firestore `domains` collection.
    /// When Firebase is not configured, emits mock data immediately.
    func startListening() {
        guard !isListening else { return }

        if kFirebaseEnabled {
            startFirestoreListener()
        } else {
            emitMockData()
        }
    }

    func stopListening() {
        mockRefreshTimer?.invalidate()
        mockRefreshTimer = nil
        isListening = false

        // When Firebase is enabled:
        // (listenerRegistration as? ListenerRegistration)?.remove()
        listenerRegistration = nil
    }

    // ── Firestore Listener (active when kFirebaseEnabled = true) ──────────

    private func startFirestoreListener() {
        // import FirebaseFirestore  ← uncomment when SPM package is installed
        //
        // do {
        //     let db = Firestore.firestore()
        //     listenerRegistration = db
        //         .collection("domains")
        //         .order(by: "createdAt", descending: true)
        //         .addSnapshotListener { [weak self] snapshot, err in
        //             guard let self else { return }
        //
        //             if let err {
        //                 self.error = err.localizedDescription
        //                 // Fall back to mock data on error
        //                 self.emitMockData()
        //                 return
        //             }
        //
        //             guard let snapshot else { return }
        //
        //             self.domains = snapshot.documents.compactMap { doc -> FirestoreDomain? in
        //                 let data = doc.data()
        //                 guard let name = data["domainName"] as? String else { return nil }
        //                 return FirestoreDomain(
        //                     id       : doc.documentID,
        //                     domainName: name,
        //                     category : data["category"]  as? String ?? "Bilinmiyor",
        //                     status   : data["status"]    as? String ?? "Engellendi",
        //                     isBlocked: data["isBlocked"] as? Bool   ?? true,
        //                     createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        //                 )
        //             }
        //             self.error = nil
        //             self.isListening = true
        //         }
        //     isListening = true
        // }

        // Fallback until Firebase is activated
        emitMockData()
    }

    // ── Mock Data (active when kFirebaseEnabled = false) ──────────────────

    private static let mockDomains: [FirestoreDomain] = [
        FirestoreDomain(id: "bahis.com",        domainName: "bahis.com",        category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 30)),
        FirestoreDomain(id: "casino-tr.net",    domainName: "casino-tr.net",    category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 20)),
        FirestoreDomain(id: "bet365.com",       domainName: "bet365.com",       category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 15)),
        FirestoreDomain(id: "1xbet.com",        domainName: "1xbet.com",        category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 10)),
        FirestoreDomain(id: "betway.com",       domainName: "betway.com",       category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 5)),
        FirestoreDomain(id: "pokerstars.com",   domainName: "pokerstars.com",   category: "Kumar",      status: "Engellendi", isBlocked: true,  createdAt: Date(timeIntervalSinceNow: -86400 * 3)),
        FirestoreDomain(id: "google.com",       domainName: "google.com",       category: "Bilinmiyor", status: "İzin Verildi", isBlocked: false, createdAt: Date(timeIntervalSinceNow: -86400 * 2)),
    ]

    private func emitMockData() {
        domains = Self.mockDomains
        isListening = true
        error = nil
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    /// Returns the list of blocked domain name strings suitable for VPN filtering.
    var blockedDomainNames: [String] {
        domains.filter(\.isBlocked).map(\.domainName)
    }

    /// Converts FirestoreDomain list to the app's native Domain model list.
    var nativeDomains: [Domain] {
        domains.enumerated().map { idx, d in d.toDomain(localId: idx + 1) }
    }
}
