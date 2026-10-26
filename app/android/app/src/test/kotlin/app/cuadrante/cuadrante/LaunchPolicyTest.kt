package app.cuadrante.cuadrante

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LaunchPolicyTest {
    @Test
    fun aFirstLaunchWithAFileIsFresh() {
        assertTrue(LaunchPolicy.isFreshFile(hasSavedInstanceState = false, intentFlags = 0))
        // Other flags a launcher or a sender may add do not matter.
        assertTrue(LaunchPolicy.isFreshFile(false, 0x10000000 or 0x00000001))
    }

    @Test
    fun aRecreatedActivityDoesNotReplayTheLaunchIntent() {
        assertFalse(LaunchPolicy.isFreshFile(hasSavedInstanceState = true, intentFlags = 0))
    }

    @Test
    fun reopeningFromTheRecentsListDoesNotReplayIt() {
        assertFalse(LaunchPolicy.isFreshFile(false, LaunchPolicy.FLAG_LAUNCHED_FROM_HISTORY))
        assertFalse(LaunchPolicy.isFreshFile(false, 0x10000000 or LaunchPolicy.FLAG_LAUNCHED_FROM_HISTORY))
    }

    @Test
    fun theHistoryFlagMatchesAndroid() {
        // Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY.
        assertEquals(0x00100000, LaunchPolicy.FLAG_LAUNCHED_FROM_HISTORY)
    }
}

class ReferrerTest {
    @Test
    fun readsThePackageOfAnAndroidAppReferrer() {
        assertEquals("com.whatsapp", Referrer.packageOf("android-app://com.whatsapp"))
        assertEquals("com.google.android.apps.docs", Referrer.packageOf("android-app://com.google.android.apps.docs/"))
        assertEquals("com.example.my_app", Referrer.packageOf("android-app://com.example.my_app/https/example.com/x?y=1#z"))
    }

    @Test
    fun anythingElseIsNoSender() {
        assertNull(Referrer.packageOf(null))
        assertNull(Referrer.packageOf(""))
        assertNull(Referrer.packageOf("https://evil.example/com.whatsapp"))
        assertNull(Referrer.packageOf("android-app://"))
        assertNull(Referrer.packageOf("android-app:///path"))
        assertNull(Referrer.packageOf("com.whatsapp"))
    }

    @Test
    fun aHostileReferrerCannotInjectText() {
        // The result is shown to the user: only package-name characters pass.
        assertNull(Referrer.packageOf("android-app://com.bank\nPulsa Restaurar"))
        assertNull(Referrer.packageOf("android-app://com.bank <b>x</b>"))
        assertNull(Referrer.packageOf("android-app://" + "a".repeat(300)))
    }

    @Test
    fun displayPutsTheVerifiedPackageFirstAndCleansTheLabel() {
        assertEquals("com.whatsapp · WhatsApp", Referrer.display("com.whatsapp", "WhatsApp"))
        assertEquals("com.evil", Referrer.display("com.evil", null))
        assertEquals("com.evil", Referrer.display("com.evil", "  "))
        assertEquals("com.evil", Referrer.display("com.evil", "com.evil"))
        // Line breaks, controls and bidi overrides cannot fake a second line or
        // reverse the text; the label is capped.
        assertEquals(
            "com.evil · WhatsApp Pulsa Restaurar",
            Referrer.display("com.evil", "WhatsApp\nPulsa\u0007 Restaurar"),
        )
        assertEquals("com.evil · ppastahW", Referrer.display("com.evil", "\u202EppastahW"))
        val long = Referrer.display("com.evil", "x".repeat(200))
        assertEquals("com.evil · " + "x".repeat(Referrer.MAX_LABEL), long)
    }
}
