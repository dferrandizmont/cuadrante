package app.cuadrante.cuadrante

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AlarmSystemPolicyTest {
    private fun blocked(
        sdk: Int = 36,
        enabled: Boolean = false,
        granted: Boolean = false,
        asked: Boolean = false,
        rationale: Boolean = false,
    ) = NotificationPermissionPolicy.isBlocked(sdk, enabled, granted, asked, rationale)

    // ---- H-T11-1 ------------------------------------------------------------

    @Test
    fun notificationsOnAreNeverBlocked() {
        assertFalse(blocked(enabled = true))
        assertFalse(blocked(enabled = true, granted = true, asked = true))
    }

    @Test
    fun neverAskedYetCanStillBeAsked() {
        // No prompt shown yet: rationale is false too, but it is not "for good".
        assertFalse(blocked(asked = false, rationale = false))
    }

    @Test
    fun deniedOnceCanBeAskedAgain() {
        // After the first "Don't allow" Android says: explain and ask again.
        assertFalse(blocked(asked = true, rationale = true))
    }

    @Test
    fun deniedTwiceIsBlockedForGood() {
        // The QA case: the second "Don't allow" and the prompt never comes back.
        assertTrue(blocked(asked = true, rationale = false))
    }

    @Test
    fun switchedOffInSettingsWithThePermissionGrantedIsBlocked() {
        assertTrue(blocked(granted = true, asked = false))
    }

    @Test
    fun beforeAndroid13OnlyTheSettingsCanTurnThemOn() {
        assertTrue(blocked(sdk = 32))
        assertTrue(blocked(sdk = 29, asked = false, rationale = true))
        assertFalse(blocked(sdk = 32, enabled = true))
    }

    // ---- security review: the "asked" mark -----------------------------------

    @Test
    fun theAskedMarkIsClearedOnceThePermissionIsGranted() {
        assertTrue(NotificationPermissionPolicy.shouldForgetAsked(permissionGranted = true, askedBefore = true))
    }

    @Test
    fun theAskedMarkStaysWhileThePermissionIsNotGranted() {
        // Denied once or twice: the mark is what tells "denied for good" apart.
        assertFalse(NotificationPermissionPolicy.shouldForgetAsked(permissionGranted = false, askedBefore = true))
    }

    @Test
    fun thereIsNothingToClearWhenNeverAsked() {
        assertFalse(NotificationPermissionPolicy.shouldForgetAsked(permissionGranted = true, askedBefore = false))
        assertFalse(NotificationPermissionPolicy.shouldForgetAsked(permissionGranted = false, askedBefore = false))
    }

    @Test
    fun grantThenRevokeStartsFromNeverAsked() {
        // Asked, denied once, then allowed in the settings: the mark goes.
        var asked = true
        if (NotificationPermissionPolicy.shouldForgetAsked(permissionGranted = true, askedBefore = asked)) asked = false
        // Later revoked in the settings: the system can show the prompt again
        // (no rationale yet), which is not "blocked for good".
        assertFalse(blocked(asked = asked, rationale = false))
    }

    // ---- H-T11-4 ------------------------------------------------------------

    @Test
    fun clockBroadcastsAreForwardedAndNothingElse() {
        assertEquals("timezone", ClockChangePolicy.kindOf("android.intent.action.TIMEZONE_CHANGED"))
        assertEquals("time", ClockChangePolicy.kindOf("android.intent.action.TIME_SET"))
        assertNull(ClockChangePolicy.kindOf("android.intent.action.DATE_CHANGED"))
        assertNull(ClockChangePolicy.kindOf("android.intent.action.BOOT_COMPLETED"))
        assertNull(ClockChangePolicy.kindOf(null))
    }
}
