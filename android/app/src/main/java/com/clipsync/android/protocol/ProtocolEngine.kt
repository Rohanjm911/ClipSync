package com.clipsync.android.protocol

import java.security.MessageDigest
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

object ProtocolEngine {

    const val PROTOCOL_VERSION = 1
    const val PAIRING_EXPIRATION_MS = 180 * 1000L // 3 minutes

    /**
     * Compute SHA-256 hash of a string
     */
    fun sha256(data: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(data.toByteArray(Charsets.UTF_8))
        return hash.joinToString("") { "%02x".format(it) }
    }

    /**
     * Sanitize filename to prevent directory traversal and OS-illegal characters
     */
    fun sanitizeFilename(filename: String?): String {
        if (filename.isNullOrBlank()) return "unnamed_file"
        val clean = filename.replace("\u0000", "").replace('\\', '/')
        val parts = clean.split('/').filter { it.isNotEmpty() }
        val base = parts.lastOrNull()?.trimStart('.') ?: "unnamed_file"

        val sanitized = StringBuilder()
        for (c in base) {
            if (c in listOf('<', '>', ':', '"', '/', '\\', '|', '?', '*')) {
                sanitized.append('_')
            } else {
                sanitized.append(c)
            }
        }
        val result = sanitized.toString().trim()
        return if (result.isEmpty() || result == "." || result == "..") {
            "unnamed_file"
        } else {
            result.take(255)
        }
    }

    /**
     * Derive 6-digit SAS code from shared secret and exchange nonces
     */
    fun deriveSASCode(sharedSecret: ByteArray, nonceA: String, nonceB: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(sharedSecret, "HmacSHA256"))
        mac.update(nonceA.toByteArray(Charsets.UTF_8))
        mac.update(nonceB.toByteArray(Charsets.UTF_8))
        val digest = mac.doFinal()

        val intValue = ((digest[0].toInt() and 0xFF) shl 24) or
                ((digest[1].toInt() and 0xFF) shl 16) or
                ((digest[2].toInt() and 0xFF) shl 8) or
                (digest[3].toInt() and 0xFF)

        val positive = intValue and 0x7FFFFFFF
        val code = positive % 1_000_000
        return "%06d".format(code)
    }

    /**
     * Create monotonic unique Event ID for loop prevention
     */
    fun createEventId(originDeviceId: String, counter: Long, contentHash: String): String {
        return sha256("$originDeviceId:$counter:$contentHash")
    }

    /**
     * Deterministic Conflict Resolution Matrix
     * Returns true if incoming remote event should supersede local event
     */
    fun shouldIncomingEventWin(
        localTimestamp: Long,
        localOriginId: String,
        incomingTimestamp: Long,
        incomingOriginId: String
    ): Boolean {
        if (incomingTimestamp > localTimestamp) return true
        if (incomingTimestamp < localTimestamp) return false
        // Tie-breaker: Lexicographical comparison of device IDs
        return incomingOriginId > localOriginId
    }

    /**
     * Detect if text contains sensitive secrets (passwords, private keys, credit cards)
     */
    fun isSensitiveContent(text: String): Boolean {
        val trimmed = text.trim()
        if (trimmed.contains("-----BEGIN") && trimmed.contains("PRIVATE KEY-----")) {
            return true
        }

        // Token heuristic
        val tokenRegex = Regex("(AKIA[0-9A-Z]{16}|ghp_[0-9a-zA-Z]{36}|sk-[a-zA-Z0-9]{32,})")
        if (tokenRegex.containsMatchIn(trimmed)) {
            return true
        }

        // Credit card heuristic with Luhn check
        val cardRegex = Regex("\\b(?:\\d[ -]*?){13,19}\\b")
        for (match in cardRegex.findAll(trimmed)) {
            val digits = match.value.filter { it.isDigit() }.map { it.digitToInt() }
            if (digits.size in 13..19 && luhnCheck(digits)) {
                return true
            }
        }

        return false
    }

    private fun luhnCheck(digits: List<Int>): Boolean {
        var sum = 0
        var alternate = false
        for (i in digits.indices.reversed()) {
            var d = digits[i]
            if (alternate) {
                d *= 2
                if (d > 9) d -= 9
            }
            sum += d
            alternate = !alternate
        }
        return sum % 10 == 0
    }
}
