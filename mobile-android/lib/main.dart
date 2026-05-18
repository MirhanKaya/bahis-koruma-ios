import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start Firestore listener early so domains are ready before the VPN screen mounts.
  await FirebaseService.instance.start();
  runApp(const BahisKorumaApp());
}

// ── App Root ─────────────────────────────────────────────────────────────────

class BahisKorumaApp extends StatelessWidget {
  const BahisKorumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bahis Koruma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a2e),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const VpnControlScreen(),
    );
  }
}

// ── MethodChannel Bridge ─────────────────────────────────────────────────────

/// Dart-side bridge to the native [LocalVpnService] via MethodChannel.
/// Channel: "com.bahiskoruma/vpn" — must match MainActivity.CHANNEL in Kotlin.
class VpnBridge {
  static const MethodChannel _channel = MethodChannel('com.bahiskoruma/vpn');

  static Future<bool> startVPN({List<String> blockedDomains = const []}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startVPN',
        {'blockedDomains': blockedDomains},
      );
      return result ?? false;
    } on PlatformException {
      rethrow;
    }
  }

  static Future<bool> stopVPN() async {
    final result = await _channel.invokeMethod<bool>('stopVPN');
    return result ?? false;
  }

  static Future<bool> isVPNRunning() async {
    final result = await _channel.invokeMethod<bool>('isVPNRunning');
    return result ?? false;
  }

  static Future<bool> updateBlockedDomains(List<String> domains) async {
    final result = await _channel.invokeMethod<bool>(
      'updateBlockedDomains',
      {'domains': domains},
    );
    return result ?? false;
  }
}

// ── VPN Control Screen ────────────────────────────────────────────────────────

class VpnControlScreen extends StatefulWidget {
  const VpnControlScreen({super.key});

  @override
  State<VpnControlScreen> createState() => _VpnControlScreenState();
}

class _VpnControlScreenState extends State<VpnControlScreen> {
  bool _isRunning = false;
  bool _isLoading = false;
  String _statusText = 'Durum kontrol ediliyor...';
  String? _errorText;

  /// Current blocked domain list — sourced from Firestore (or mock fallback).
  List<String> _blockedDomains = [];

  @override
  void initState() {
    super.initState();
    _checkVpnStatus();

    // Subscribe to Firestore domain stream.
    // Whenever admin panel adds/removes a domain, this stream emits the new list.
    // If VPN is running, the new list is pushed immediately to LocalVpnService.
    FirebaseService.instance.domainsStream.listen(_onDomainsUpdated);
  }

  // ── Firestore domain stream callback ──────────────────────────────────

  void _onDomainsUpdated(List<FirestoreDomain> domains) {
    final blocked = FirebaseService.extractBlocked(domains);
    setState(() => _blockedDomains = blocked);

    // Push updated list to the running VPN service
    if (_isRunning && blocked.isNotEmpty) {
      VpnBridge.updateBlockedDomains(blocked).catchError((_) {});
    }
  }

  // ── VPN Status ────────────────────────────────────────────────────────

  Future<void> _checkVpnStatus() async {
    try {
      final running = await VpnBridge.isVPNRunning();
      _setRunning(running);
    } on PlatformException catch (e) {
      setState(() => _errorText = 'Durum alınamadı: ${e.message}');
    }
  }

  void _setRunning(bool running) {
    setState(() {
      _isRunning  = running;
      _statusText = running
          ? 'VPN Aktif — ${_blockedDomains.length} domain engelleniyor'
          : 'VPN Kapalı — Koruma devre dışı';
      _errorText  = null;
    });
  }

  // ── Toggle VPN ────────────────────────────────────────────────────────

  Future<void> _toggleVpn() async {
    setState(() { _isLoading = true; _errorText = null; });

    try {
      if (_isRunning) {
        final ok = await VpnBridge.stopVPN();
        _setRunning(!ok);
      } else {
        // Start VPN with Firestore-sourced blocked domains.
        // Falls back to default list if Firestore hasn't loaded yet.
        final domains = _blockedDomains.isNotEmpty
            ? _blockedDomains
            : _defaultDomains;
        final ok = await VpnBridge.startVPN(blockedDomains: domains);
        _setRunning(ok);
      }
    } on PlatformException catch (e) {
      setState(() => _errorText = _friendlyError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _friendlyError(PlatformException e) {
    if (e.code == 'VPN_PERMISSION_DENIED') {
      return 'VPN izni reddedildi. Lütfen izin verin ve tekrar deneyin.';
    }
    return 'Hata: ${e.message}';
  }

  // ── Default domain list (used before Firestore responds) ───────────────

  static const List<String> _defaultDomains = [
    'bet365.com', 'betboo.com', 'bwin.com', 'pokerstars.com',
    'casino.com', 'williamhill.com', '1xbet.com', 'betway.com',
    'bahigo.com', 'casinomaxi.com', 'bets10.com', 'betsson.com',
  ];

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _shieldIcon,
              const SizedBox(height: 24),
              _title,
              const SizedBox(height: 10),
              _statusLabel,
              _domainCountLabel,
              if (_errorText != null) ...[const SizedBox(height: 12), _errorBanner],
              const SizedBox(height: 52),
              _toggleButton,
              const SizedBox(height: 20),
              _refreshButton,
              const SizedBox(height: 10),
              _firestoreStatus,
            ],
          ),
        ),
      ),
    );
  }

  Widget get _shieldIcon => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Icon(
          _isRunning ? Icons.security : Icons.security_outlined,
          key: ValueKey(_isRunning),
          size: 100,
          color: _isRunning ? const Color(0xFF2a9d8f) : Colors.white38,
        ),
      );

  Widget get _title => const Text(
        'Bahis Koruma',
        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
      );

  Widget get _statusLabel => Text(
        _statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _isRunning ? const Color(0xFF2a9d8f) : Colors.white38,
          fontSize: 15,
        ),
      );

  Widget get _domainCountLabel => StreamBuilder<List<FirestoreDomain>>(
        stream: FirebaseService.instance.domainsStream,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final count = snap.data!.where((d) => d.isBlocked).length;
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$count domain engel listesinde',
              style: const TextStyle(color: Colors.white24, fontSize: 13),
            ),
          );
        },
      );

  Widget get _errorBanner => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFe63946).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFe63946).withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFFe63946), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorText!,
              style: const TextStyle(color: Color(0xFFe63946), fontSize: 13))),
        ]),
      );

  Widget get _toggleButton => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _toggleVpn,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? const Color(0xFFe63946) : const Color(0xFF2a9d8f),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  _isRunning ? "VPN'yi Durdur" : "VPN'yi Başlat",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
        ),
      );

  Widget get _refreshButton => TextButton(
        onPressed: _isLoading ? null : _checkVpnStatus,
        child: const Text('Durumu Yenile',
            style: TextStyle(color: Colors.white38, fontSize: 14)),
      );

  Widget get _firestoreStatus => StreamBuilder<List<FirestoreDomain>>(
        stream: FirebaseService.instance.domainsStream,
        builder: (context, snap) {
          final isLive = FirebaseService.instance.isConfigured;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLive ? const Color(0xFF4caf50) : Colors.white24,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isLive ? 'Firestore — Gerçek zamanlı' : 'Firestore — Mock veri',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          );
        },
      );
}
