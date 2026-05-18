import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── FirebaseService
//
// Manages real-time synchronization with the Firestore `domains` collection.
//
// Two modes:
//
//   MODE A — REST polling (default, no Firebase packages needed):
//     Polls the Firestore REST API every [pollInterval] seconds.
//     Requires a Firebase project + API key set in [_firebaseConfig].
//     Falls back to mock data when config is empty or request fails.
//
//   MODE B — Native Firestore SDK (recommended for production):
//     Uncomment firebase_core + cloud_firestore in pubspec.yaml.
//     Add google-services.json to android/app/.
//     Set _kUseNativeSdk = true below.
//     Replace _pollFirestore() with _listenNative().
//
// Activation checklist:
//   1. Create a Firebase project → add an Android app (package: com.bahiskoruma.app)
//   2. Download google-services.json → place in mobile-android/android/app/
//   3. Fill in [_firebaseConfig] values below
//   4. For native SDK: uncomment packages in pubspec.yaml and set _kUseNativeSdk = true

// ── Feature flags ─────────────────────────────────────────────────────────────

/// Set to true when google-services.json is added and firebase packages are
/// uncommented in pubspec.yaml. Switches from REST polling to native SDK.
const bool _kUseNativeSdk = false;

/// Firebase project config for REST polling.
/// Fill in after creating a Firebase project.
const _FirebaseConfig _firebaseConfig = _FirebaseConfig(
  projectId: '',       // e.g. 'bahis-koruma-app'
  apiKey: '',          // Web API key from Firebase Console → Project Settings
);

// ── Domain model ──────────────────────────────────────────────────────────────

class FirestoreDomain {
  final String id;
  final String domainName;
  final String category;
  final String status;
  final bool isBlocked;
  final DateTime createdAt;

  const FirestoreDomain({
    required this.id,
    required this.domainName,
    required this.category,
    required this.status,
    required this.isBlocked,
    required this.createdAt,
  });

  factory FirestoreDomain.fromRestJson(Map<String, dynamic> fields, String docId) {
    String _str(String key, String fallback) =>
        (fields[key]?['stringValue'] as String?) ?? fallback;
    bool _bool(String key, bool fallback) =>
        (fields[key]?['booleanValue'] as bool?) ?? fallback;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
          (fields['createdAt']?['timestampValue'] as String?) ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    return FirestoreDomain(
      id: docId,
      domainName: _str('domainName', docId),
      category: _str('category', 'Bilinmiyor'),
      status: _str('status', 'Engellendi'),
      isBlocked: _bool('isBlocked', true),
      createdAt: createdAt,
    );
  }

  List<String> get blockedDomainList => isBlocked ? [domainName] : [];
}

// ── FirebaseService ───────────────────────────────────────────────────────────

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  // Internal broadcast stream
  final StreamController<List<FirestoreDomain>> _controller =
      StreamController<List<FirestoreDomain>>.broadcast();

  Stream<List<FirestoreDomain>> get domainsStream => _controller.stream;

  bool _started = false;
  Timer? _pollTimer;

  static const Duration pollInterval = Duration(seconds: 30);

  // ── Lifecycle ──────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (_kUseNativeSdk) {
      await _initNativeSdk();
    } else {
      await _pollFirestore(); // Immediate first poll
      _pollTimer = Timer.periodic(pollInterval, (_) => _pollFirestore());
    }
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _started = false;
    // When native SDK is active: _firestoreSubscription?.cancel();
  }

  void dispose() {
    stop();
    _controller.close();
  }

  // ── REST Polling ───────────────────────────────────────────────────────

  Future<void> _pollFirestore() async {
    if (!_firebaseConfig.isConfigured) {
      _emitMockData();
      return;
    }

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${_firebaseConfig.projectId}'
      '/databases/(default)/documents/domains'
      '?key=${_firebaseConfig.apiKey}&orderBy=createdAt+desc&pageSize=200',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[FirebaseService] REST error ${response.statusCode}');
        _emitMockData();
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final documents = (body['documents'] as List<dynamic>?) ?? [];

      final domains = documents.map((doc) {
        final name = (doc['name'] as String).split('/').last;
        final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
        return FirestoreDomain.fromRestJson(fields, name);
      }).toList();

      _controller.add(List.unmodifiable(domains));
    } catch (e) {
      debugPrint('[FirebaseService] Poll error: $e');
      _emitMockData();
    }
  }

  // ── Native SDK (active when _kUseNativeSdk = true) ─────────────────────
  //
  // To enable:
  //   1. Add to pubspec.yaml:
  //        firebase_core: ^2.24.0
  //        cloud_firestore: ^4.14.0
  //   2. Run: flutter pub get
  //   3. Add google-services.json to android/app/
  //   4. Set _kUseNativeSdk = true above
  //   5. Uncomment the import and code below

  Future<void> _initNativeSdk() async {
    // import 'package:firebase_core/firebase_core.dart';
    // import 'package:cloud_firestore/cloud_firestore.dart';
    //
    // try {
    //   await Firebase.initializeApp();
    //
    //   FirebaseFirestore.instance
    //     .collection('domains')
    //     .orderBy('createdAt', descending: true)
    //     .snapshots()
    //     .listen(
    //       (snapshot) {
    //         final domains = snapshot.docs.map((doc) {
    //           final d = doc.data();
    //           return FirestoreDomain(
    //             id:         doc.id,
    //             domainName: d['domainName'] as String? ?? doc.id,
    //             category:   d['category']  as String? ?? 'Bilinmiyor',
    //             status:     d['status']    as String? ?? 'Engellendi',
    //             isBlocked:  d['isBlocked'] as bool?   ?? true,
    //             createdAt:  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    //           );
    //         }).toList();
    //         _controller.add(List.unmodifiable(domains));
    //       },
    //       onError: (e) {
    //         debugPrint('[FirebaseService] Native SDK error: $e');
    //         _emitMockData();
    //       },
    //     );
    // } catch (e) {
    //   debugPrint('[FirebaseService] Firebase.initializeApp failed: $e');
    //   _emitMockData();
    // }

    // Fallback until native SDK is activated
    _emitMockData();
  }

  // ── Mock Data ──────────────────────────────────────────────────────────

  static final List<FirestoreDomain> _mockDomains = [
    FirestoreDomain(id: 'bahis.com',      domainName: 'bahis.com',      category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 1)),
    FirestoreDomain(id: 'casino-tr.net',  domainName: 'casino-tr.net',  category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 2)),
    FirestoreDomain(id: 'bet365.com',     domainName: 'bet365.com',     category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 3)),
    FirestoreDomain(id: '1xbet.com',      domainName: '1xbet.com',      category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 4)),
    FirestoreDomain(id: 'betway.com',     domainName: 'betway.com',     category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 5)),
    FirestoreDomain(id: 'pokerstars.com', domainName: 'pokerstars.com', category: 'Kumar',      status: 'Engellendi',   isBlocked: true,  createdAt: DateTime(2026, 1, 6)),
    FirestoreDomain(id: 'google.com',     domainName: 'google.com',     category: 'Bilinmiyor', status: 'İzin Verildi', isBlocked: false, createdAt: DateTime(2026, 1, 7)),
  ];

  void _emitMockData() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_mockDomains));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Returns all blocked domain names — pass directly to VpnBridge.startVPN()
  static List<String> extractBlocked(List<FirestoreDomain> domains) =>
      domains.where((d) => d.isBlocked).map((d) => d.domainName).toList();

  bool get isConfigured => _firebaseConfig.isConfigured || _kUseNativeSdk;
}

// ── Config helper ─────────────────────────────────────────────────────────────

class _FirebaseConfig {
  final String projectId;
  final String apiKey;

  const _FirebaseConfig({required this.projectId, required this.apiKey});

  bool get isConfigured => projectId.isNotEmpty && apiKey.isNotEmpty;
}
