package com.bahiskoruma.app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 *
 * Flutter entry point. Registers a MethodChannel named "com.bahiskoruma/vpn"
 * that the Dart layer uses to control [LocalVpnService].
 *
 * ┌──────────────────────────────────────────────────────────┐
 * │  Flutter (Dart)          MethodChannel          Kotlin   │
 * │  VpnBridge.startVPN()  ──────────────────►  handleStart  │
 * │  VpnBridge.stopVPN()   ──────────────────►  handleStop   │
 * │  VpnBridge.isVPNRunning──────────────────►  isRunning()  │
 * │  VpnBridge.updateDomains─────────────────►  setDomains() │
 * └──────────────────────────────────────────────────────────┘
 *
 * Supported method names:
 *   "startVPN"            → args: { "blockedDomains": List<String> }
 *   "stopVPN"             → no args
 *   "isVPNRunning"        → no args
 *   "updateBlockedDomains"→ args: { "domains": List<String> }
 */
class MainActivity : FlutterActivity() {

    private lateinit var channel: MethodChannel

    companion object {
        /** Must match the channel name used in lib/main.dart VpnBridge. */
        private const val CHANNEL          = "com.bahiskoruma/vpn"
        private const val VPN_REQUEST_CODE = 0xBEEF

        /** Held across onActivityResult to deliver the pending result. */
        @Volatile private var pendingResult: MethodChannel.Result? = null
        @Volatile private var pendingDomains: List<String>         = emptyList()
    }

    // ── Flutter Engine ────────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(::onMethodCall)
    }

    // ── MethodChannel Handler ─────────────────────────────────────────────

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "startVPN" -> {
                val domains = call.argument<List<String>>("blockedDomains") ?: emptyList()
                handleStartVpn(domains, result)
            }

            "stopVPN" -> {
                stopVpnService()
                result.success(true)
            }

            "isVPNRunning" -> {
                result.success(LocalVpnService.isRunning())
            }

            "updateBlockedDomains" -> {
                val domains = call.argument<List<String>>("domains") ?: emptyList()
                LocalVpnService.instance?.setBlockedDomains(domains)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    // ── VPN Permission Flow ───────────────────────────────────────────────

    /**
     * If the user hasn't granted VPN permission yet, launches the system
     * dialog via [VpnService.prepare]. The result is delivered in
     * [onActivityResult]. If permission is already granted, starts the
     * service immediately.
     */
    private fun handleStartVpn(blockedDomains: List<String>, result: MethodChannel.Result) {
        val vpnIntent = VpnService.prepare(this)
        if (vpnIntent != null) {
            pendingResult  = result
            pendingDomains = blockedDomains
            startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
        } else {
            startVpnService(blockedDomains)
            result.success(true)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != VPN_REQUEST_CODE) return

        if (resultCode == Activity.RESULT_OK) {
            startVpnService(pendingDomains)
            pendingResult?.success(true)
        } else {
            pendingResult?.error(
                "VPN_PERMISSION_DENIED",
                "The user denied VPN permission.",
                null
            )
        }

        pendingResult  = null
        pendingDomains = emptyList()
    }

    // ── Service Control ───────────────────────────────────────────────────

    private fun startVpnService(blockedDomains: List<String>) {
        val intent = Intent(this, LocalVpnService::class.java).apply {
            action = LocalVpnService.ACTION_START
            putStringArrayListExtra("blockedDomains", ArrayList(blockedDomains))
        }
        startService(intent)
    }

    private fun stopVpnService() {
        val intent = Intent(this, LocalVpnService::class.java).apply {
            action = LocalVpnService.ACTION_STOP
        }
        startService(intent)
    }
}
