package com.bahiskoruma.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean

/**
 * LocalVpnService
 *
 * Creates a local TUN interface that captures all IPv4 traffic on the device.
 * DNS queries (UDP port 53) are intercepted:
 *   - Blocked domains  → NXDOMAIN response written back to the TUN.
 *   - Allowed domains  → forwarded to 8.8.8.8 via a VpnService.protect()‑ed socket.
 * All non-DNS traffic is written back to the TUN unchanged (pass-through).
 *
 * MethodChannel bridge: MainActivity calls startTunnel() / stopTunnel() and
 * setBlockedDomains() via the static [instance] reference.
 */
class LocalVpnService : VpnService() {

    // ── State ────────────────────────────────────────────────────────────────

    private var vpnInterface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var tunnelThread: Thread? = null

    /**
     * The live set of blocked domains (lower-case, no trailing dot).
     * Seeded with a default gambling/betting list; updated at runtime via
     * [setBlockedDomains] when MainActivity pushes new data from the backend.
     */
    private val blockedDomains: MutableSet<String> = mutableSetOf(
        "bet365.com", "betboo.com", "bwin.com", "pokerstars.com",
        "casino.com", "williamhill.com", "1xbet.com", "betway.com",
        "bahigo.com", "casinomaxi.com", "bets10.com", "betsson.com",
        "unibet.com", "ladbrokes.com", "coral.co.uk", "888casino.com"
    )

    // ── Companion (static interface for MainActivity) ─────────────────────

    companion object {
        const val ACTION_START = "com.bahiskoruma.START_VPN"
        const val ACTION_STOP  = "com.bahiskoruma.STOP_VPN"

        private const val TAG               = "LocalVpnService"
        private const val MTU               = 32_767
        private const val NOTIFICATION_ID   = 1001
        private const val CHANNEL_ID        = "bahiskoruma_vpn"

        /** Holds the running instance so MainActivity can call setBlockedDomains(). */
        @Volatile var instance: LocalVpnService? = null
            private set

        fun isRunning(): Boolean = instance?.running?.get() ?: false
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        stopTunnel()
        instance = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_STOP -> {
                stopTunnel()
                START_NOT_STICKY
            }
            else -> {
                if (!running.get()) {
                    val domains = intent?.getStringArrayListExtra("blockedDomains")
                    if (!domains.isNullOrEmpty()) {
                        blockedDomains.clear()
                        blockedDomains.addAll(domains.map { it.lowercase() })
                    }
                    startForegroundNotification()
                    startTunnel()
                }
                START_STICKY
            }
        }
    }

    // ── Foreground Notification ───────────────────────────────────────────

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bahis Koruma VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Kumar engelleme servisi aktif" }

            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }

        val openIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
            .setContentTitle("Bahis Koruma Aktif")
            .setContentText("Kumar siteleri engelleniyor")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    // ── Tunnel Lifecycle ──────────────────────────────────────────────────

    private fun startTunnel() {
        val iface = Builder()
            .setMtu(MTU)
            .addAddress("10.0.0.2", 32)        // Virtual address for this device
            .addDnsServer("8.8.8.8")            // Route DNS through the tunnel
            .addRoute("0.0.0.0", 0)             // Capture all IPv4 traffic
            .setSession("BahisKoruma VPN")
            .setBlocking(true)
            .establish()

        if (iface == null) {
            Log.e(TAG, "VPN Builder.establish() returned null — permission missing?")
            stopSelf()
            return
        }

        vpnInterface = iface
        running.set(true)

        tunnelThread = Thread(::runTunnelLoop, "bk-vpn-tunnel").also { it.start() }
        Log.i(TAG, "Tunnel started — blocking ${blockedDomains.size} domains")
    }

    private fun stopTunnel() {
        if (!running.compareAndSet(true, false)) return

        tunnelThread?.interrupt()
        tunnelThread = null

        try { vpnInterface?.close() } catch (e: IOException) {
            Log.e(TAG, "Error closing VPN interface: ${e.message}")
        }
        vpnInterface = null

        stopForeground(true)
        stopSelf()
        Log.i(TAG, "Tunnel stopped")
    }

    // ── Packet Loop ───────────────────────────────────────────────────────

    private fun runTunnelLoop() {
        val fd  = vpnInterface!!.fileDescriptor
        val inp = FileInputStream(fd)
        val out = FileOutputStream(fd)
        val buf = ByteArray(MTU)

        try {
            while (running.get() && !Thread.currentThread().isInterrupted) {
                val len = inp.read(buf)
                if (len > 0) {
                    processPacket(buf.copyOf(len), out)
                }
            }
        } catch (e: IOException) {
            if (running.get()) Log.e(TAG, "Tunnel I/O error: ${e.message}")
        }
    }

    // ── Packet Processing ─────────────────────────────────────────────────

    private fun processPacket(pkt: ByteArray, out: FileOutputStream) {
        if (pkt.size < 20) return                          // Minimum IPv4 header size

        val version = (pkt[0].toInt() and 0xFF) ushr 4
        if (version != 4) return                           // Skip IPv6 (not handled here)

        val protocol = pkt[9].toInt() and 0xFF             // Transport protocol

        // UDP (17) + destination port 53 → DNS query
        if (protocol == 17 && pkt.size >= 28) {
            val ipHeaderLen = (pkt[0].toInt() and 0x0F) * 4
            val dstPort = ((pkt[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or
                          (pkt[ipHeaderLen + 3].toInt() and 0xFF)
            if (dstPort == 53) {
                handleDnsPacket(pkt, ipHeaderLen, out)
                return
            }
        }

        // Pass all other traffic through unchanged
        try { out.write(pkt) } catch (e: IOException) {
            Log.w(TAG, "Write error (non-DNS): ${e.message}")
        }
    }

    // ── DNS Handling ──────────────────────────────────────────────────────

    private fun handleDnsPacket(ipPkt: ByteArray, ipHeaderLen: Int, out: FileOutputStream) {
        val dnsOffset  = ipHeaderLen + 8           // IP header + UDP header (8 bytes)
        if (ipPkt.size <= dnsOffset + 12) return   // Need at least a DNS header

        val dnsPayload = ipPkt.copyOfRange(dnsOffset, ipPkt.size)
        val domain     = parseDnsQueryDomain(dnsPayload)

        if (domain != null && isDomainBlocked(domain)) {
            Log.d(TAG, "Blocked: $domain")
            val nxResp   = buildNxDomainResponse(dnsPayload)
            val response = buildUdpIpPacket(ipPkt, ipHeaderLen, nxResp)
            try { out.write(response) } catch (e: IOException) {
                Log.w(TAG, "Write NXDOMAIN error: ${e.message}")
            }
        } else {
            forwardDnsQuery(ipPkt, ipHeaderLen, dnsPayload, out)
        }
    }

    private fun isDomainBlocked(domain: String): Boolean {
        val lower = domain.lowercase().trimEnd('.')
        return blockedDomains.any { blocked -> lower == blocked || lower.endsWith(".$blocked") }
    }

    // ── DNS Parsing ───────────────────────────────────────────────────────

    /**
     * Extracts the queried domain from the Questions section of a raw DNS payload.
     * Returns null if the payload is malformed.
     */
    private fun parseDnsQueryDomain(dns: ByteArray): String? {
        if (dns.size < 12) return null    // DNS header is 12 bytes

        val sb = StringBuilder()
        var i  = 12                       // Questions section starts at offset 12

        while (i < dns.size) {
            val labelLen = dns[i].toInt() and 0xFF
            if (labelLen == 0) break
            if (labelLen and 0xC0 == 0xC0) break  // Compression pointer — stop
            val end = i + 1 + labelLen
            if (end > dns.size) break
            if (sb.isNotEmpty()) sb.append('.')
            sb.append(String(dns, i + 1, labelLen, Charsets.US_ASCII))
            i = end
        }

        return if (sb.isNotEmpty()) sb.toString() else null
    }

    // ── DNS Response Building ─────────────────────────────────────────────

    /**
     * Builds an NXDOMAIN response by copying the query, flipping QR=1,
     * setting AA=1, and setting RCODE=3 (NXDOMAIN).
     */
    private fun buildNxDomainResponse(query: ByteArray): ByteArray {
        val resp = query.copyOf()
        resp[2] = 0x85.toByte()   // QR=1 Opcode=0 AA=1 TC=0 RD=1
        resp[3] = 0x83.toByte()   // RA=1 Z=0 RCODE=3 (NXDOMAIN)
        resp[6] = 0               // ANCOUNT high
        resp[7] = 0               // ANCOUNT low  — zero answers
        return resp
    }

    /**
     * Wraps [dnsPayload] in a UDP/IP packet, swapping source and destination
     * so the response appears to come from the DNS server (port 53) to the app.
     */
    private fun buildUdpIpPacket(
        originalIp: ByteArray,
        ipHeaderLen: Int,
        dnsPayload: ByteArray
    ): ByteArray {
        val udpLen   = 8 + dnsPayload.size
        val totalLen = ipHeaderLen + udpLen
        val pkt      = ByteArray(totalLen)

        // ── IPv4 header ─────────────────────────────────────────────────
        System.arraycopy(originalIp, 0, pkt, 0, ipHeaderLen)

        // Total length
        pkt[2] = (totalLen ushr 8).toByte()
        pkt[3] = (totalLen and 0xFF).toByte()

        // Swap src ↔ dst IP
        System.arraycopy(originalIp, 16, pkt, 12, 4)   // original dst → new src
        System.arraycopy(originalIp, 12, pkt, 16, 4)   // original src → new dst

        // Recompute IPv4 header checksum
        computeIpv4Checksum(pkt, ipHeaderLen)

        // ── UDP header ──────────────────────────────────────────────────
        val origSrcPort = ((originalIp[ipHeaderLen].toInt() and 0xFF) shl 8) or
                          (originalIp[ipHeaderLen + 1].toInt() and 0xFF)

        pkt[ipHeaderLen]     = (53 ushr 8).toByte()          // src port = 53
        pkt[ipHeaderLen + 1] = (53 and 0xFF).toByte()
        pkt[ipHeaderLen + 2] = (origSrcPort ushr 8).toByte() // dst port = original src
        pkt[ipHeaderLen + 3] = (origSrcPort and 0xFF).toByte()
        pkt[ipHeaderLen + 4] = (udpLen ushr 8).toByte()
        pkt[ipHeaderLen + 5] = (udpLen and 0xFF).toByte()
        pkt[ipHeaderLen + 6] = 0                              // checksum (optional for IPv4)
        pkt[ipHeaderLen + 7] = 0

        // ── DNS payload ─────────────────────────────────────────────────
        System.arraycopy(dnsPayload, 0, pkt, ipHeaderLen + 8, dnsPayload.size)

        return pkt
    }

    /** One's-complement checksum for an IPv4 header. */
    private fun computeIpv4Checksum(pkt: ByteArray, headerLen: Int) {
        pkt[10] = 0; pkt[11] = 0    // Zero out existing checksum field
        var sum = 0
        var i = 0
        while (i < headerLen) {
            sum += ((pkt[i].toInt() and 0xFF) shl 8) or (pkt[i + 1].toInt() and 0xFF)
            i += 2
        }
        while (sum ushr 16 != 0) { sum = (sum and 0xFFFF) + (sum ushr 16) }
        val cs = sum.inv() and 0xFFFF
        pkt[10] = (cs ushr 8).toByte()
        pkt[11] = (cs and 0xFF).toByte()
    }

    // ── DNS Forwarding ────────────────────────────────────────────────────

    /**
     * Sends [dnsPayload] to Google DNS (8.8.8.8:53) using a protect()‑ed socket
     * that bypasses the VPN tunnel (prevents routing loops).
     * The response is wrapped back into an IP/UDP packet and written to [out].
     */
    private fun forwardDnsQuery(
        originalIp: ByteArray,
        ipHeaderLen: Int,
        dnsPayload: ByteArray,
        out: FileOutputStream
    ) {
        val upstream = InetAddress.getByName("8.8.8.8")
        val socket   = DatagramSocket()
        protect(socket)    // ← Critical: exempts this socket from the VPN tunnel

        try {
            socket.soTimeout = 3_000
            socket.send(DatagramPacket(dnsPayload, dnsPayload.size, upstream, 53))

            val recvBuf = ByteArray(512)
            val recv    = DatagramPacket(recvBuf, recvBuf.size)
            socket.receive(recv)

            val responseIpPkt = buildUdpIpPacket(
                originalIp, ipHeaderLen, recvBuf.copyOf(recv.length)
            )
            out.write(responseIpPkt)
        } catch (e: IOException) {
            Log.w(TAG, "DNS forward error: ${e.message}")
        } finally {
            socket.close()
        }
    }

    // ── Public API ────────────────────────────────────────────────────────

    /**
     * Called from MainActivity (via static [instance]) when Flutter pushes an
     * updated domain list from the backend API.
     */
    fun setBlockedDomains(domains: List<String>) {
        blockedDomains.clear()
        blockedDomains.addAll(domains.map { it.lowercase().trimEnd('.') })
        Log.i(TAG, "Blocked domain list updated: ${blockedDomains.size} entries")
    }
}
