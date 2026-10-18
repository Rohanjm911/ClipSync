package com.clipsync.android

import com.clipsync.android.protocol.ProtocolEngine
import org.junit.Assert.*
import org.junit.Test

class ProtocolEngineTest {

    @Test
    fun testFilenameSanitization() {
        assertEquals("evil.apk", ProtocolEngine.sanitizeFilename("../../evil.apk"))
        assertEquals("calc.exe", ProtocolEngine.sanitizeFilename("..\\..\\windows\\calc.exe"))
        assertEquals("my_cool__photo_.png", ProtocolEngine.sanitizeFilename("my<cool>:photo?.png"))
        assertEquals("unnamed_file", ProtocolEngine.sanitizeFilename(""))
        assertEquals("unnamed_file", ProtocolEngine.sanitizeFilename(null))
    }

    @Test
    fun testConflictResolutionMatrix() {
        // Newer timestamp wins
        assertTrue(ProtocolEngine.shouldIncomingEventWin(1000L, "devA", 1050L, "devB"))
        assertFalse(ProtocolEngine.shouldIncomingEventWin(1050L, "devA", 1000L, "devB"))

        // Equal timestamp -> tie-breaker by device ID
        assertTrue(ProtocolEngine.shouldIncomingEventWin(2000L, "devA", 2000L, "devB"))
        assertFalse(ProtocolEngine.shouldIncomingEventWin(2000L, "devB", 2000L, "devA"))
    }

    @Test
    fun testSASCodeDerivation() {
        val secret = ByteArray(32) { 0x42 }
        val nonceA = "a".repeat(64)
        val nonceB = "b".repeat(64)

        val code1 = ProtocolEngine.deriveSASCode(secret, nonceA, nonceB)
        val code2 = ProtocolEngine.deriveSASCode(secret, nonceA, nonceB)

        assertEquals(6, code1.length)
        assertTrue(code1.matches(Regex("^\\d{6}$")))
        assertEquals(code1, code2)
    }

    @Test
    fun testLoopPreventionEventId() {
        val id1 = ProtocolEngine.createEventId("dev1", 1L, "hash_abc")
        val id2 = ProtocolEngine.createEventId("dev1", 1L, "hash_abc")
        val id3 = ProtocolEngine.createEventId("dev1", 2L, "hash_abc")

        assertEquals(id1, id2)
        assertNotEquals(id1, id3)
        assertEquals(64, id1.length)
    }

    @Test
    fun testSensitiveContentDetection() {
        val privateKey = "-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----"
        assertTrue(ProtocolEngine.isSensitiveContent(privateKey))

        val creditCard = "Pay with 4532 0150 0000 0004 please"
        assertTrue(ProtocolEngine.isSensitiveContent(creditCard))

        val normalText = "Just regular meeting notes at 2:30pm"
        assertFalse(ProtocolEngine.isSensitiveContent(normalText))
    }
}
