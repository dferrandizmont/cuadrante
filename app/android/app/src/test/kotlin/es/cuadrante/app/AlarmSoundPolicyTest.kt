package es.cuadrante.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AlarmSoundPolicyTest {
    private val defaultUri = "content://settings/system/notification_sound"

    @Test
    fun onlyContentUrisThatFitAreAcceptable() {
        assertTrue(AlarmSoundPolicy.isAcceptable("content://media/internal/audio/media/42"))
        assertFalse(AlarmSoundPolicy.isAcceptable(null))
        assertFalse(AlarmSoundPolicy.isAcceptable(""))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://"))
        assertTrue(AlarmSoundPolicy.isAcceptable("content://settings/system/notification_sound"))
        assertTrue(AlarmSoundPolicy.isAcceptable("content://media/external/audio/media/7"))
        // A file URI could point at the app's own private files.
        assertFalse(AlarmSoundPolicy.isAcceptable("file:///data/data/es.cuadrante.app/databases/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("android.resource://es.cuadrante.app/raw/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("https://example.com/tone.mp3"))
    }

    @Test
    fun onlyTheMediaStoreAndTheSettingsProviderAreAllowed() {
        // Our own share_plus FileProvider must never be opened as a sound.
        assertFalse(AlarmSoundPolicy.isAcceptable("content://es.cuadrante.app.flutter.share_provider/cache/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://es.cuadrante.app.fileprovider/x"))
        // Any other app's provider, and look-alikes of the allowed names.
        assertFalse(AlarmSoundPolicy.isAcceptable("content://com.android.contacts/contacts/1"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://media.evil/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://mediastore/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://settings.evil/system/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://media@evil/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://evil@media/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://Media/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content:///media/x"))
        assertFalse(AlarmSoundPolicy.isAcceptable("content://evil/?media/"))
        assertEquals(setOf("media", "settings"), AlarmSoundPolicy.ALLOWED_AUTHORITIES)
    }

    @Test
    fun theUriLimitMatchesTheDatabaseOne() {
        // maxAlarmSoundLength in shift_type.dart.
        assertEquals(512, AlarmSoundPolicy.MAX_URI_LENGTH)
        val atLimit = "content://media/" + "a".repeat(512 - "content://media/".length)
        assertEquals(512, atLimit.length)
        assertTrue(AlarmSoundPolicy.isAcceptable(atLimit))
        assertFalse(AlarmSoundPolicy.isAcceptable(atLimit + "a"))
    }

    @Test
    fun theDefaultEntryAndNothingPickedAreTheDefaultSound() {
        assertNull(AlarmSoundPolicy.normalize(null, defaultUri))
        assertNull(AlarmSoundPolicy.normalize(defaultUri, defaultUri))
    }

    @Test
    fun aPickedSoundIsKeptAsIs() {
        val picked = "content://media/internal/audio/media/42"
        assertEquals(picked, AlarmSoundPolicy.normalize(picked, defaultUri))
        assertEquals(picked, AlarmSoundPolicy.normalize(picked, null))
    }

    @Test
    fun aUriWeWouldNotStoreFallsBackToTheDefault() {
        assertNull(AlarmSoundPolicy.normalize("file:///sdcard/tone.mp3", defaultUri))
        assertNull(AlarmSoundPolicy.normalize("content://media/" + "a".repeat(600), defaultUri))
        assertNull(AlarmSoundPolicy.normalize("content://es.cuadrante.app.flutter.share_provider/x", defaultUri))
    }

    @Test
    fun titlesAreCleanedBeforeTheyReachTheScreen() {
        assertEquals("Cosmic", AlarmSoundPolicy.cleanTitle("  Cosmic  "))
        assertEquals("Doble espacio", AlarmSoundPolicy.cleanTitle("Doble\n\t espacio"))
        assertEquals("ppastahW", AlarmSoundPolicy.cleanTitle("‮ppastahW"))
        assertEquals("AB", AlarmSoundPolicy.cleanTitle("A\u0007B"))
        assertNull(AlarmSoundPolicy.cleanTitle(null))
        assertNull(AlarmSoundPolicy.cleanTitle("   \n "))
        assertEquals(
            "x".repeat(AlarmSoundPolicy.MAX_TITLE_LENGTH),
            AlarmSoundPolicy.cleanTitle("x".repeat(500)),
        )
    }

    @Test
    fun aStuckProviderGetsTheFallbackAfterTheTimeoutAndDoesNotBlockTheNextCall() {
        val pool = java.util.concurrent.Executors.newCachedThreadPool { r ->
            Thread(r).apply { isDaemon = true }
        }
        try {
            val never = java.util.concurrent.CountDownLatch(1)
            val started = System.nanoTime()
            val first = AlarmSoundPolicy.runBounded(pool, 1L, false) {
                never.await()
                true
            }
            val elapsedMs = (System.nanoTime() - started) / 1_000_000
            assertFalse(first)
            assertTrue("waited $elapsedMs ms", elapsedMs in 900..4000)
            // The next call does not queue behind the stuck one.
            assertTrue(AlarmSoundPolicy.runBounded(pool, 1L, false) { true })
        } finally {
            pool.shutdownNow()
        }
    }

    @Test
    fun aFailingCheckGetsTheFallbackToo() {
        val pool = java.util.concurrent.Executors.newCachedThreadPool()
        try {
            assertEquals(
                "x",
                AlarmSoundPolicy.runBounded(pool, 1L, "x") { throw IllegalStateException("boom") },
            )
        } finally {
            pool.shutdownNow()
        }
    }
}
