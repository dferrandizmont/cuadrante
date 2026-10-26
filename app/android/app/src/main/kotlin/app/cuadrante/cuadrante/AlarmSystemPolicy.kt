package app.cuadrante.cuadrante

/**
 * Pure decisions of [AlarmSystemChannel], kept apart from the Android classes
 * so the JVM tests can run them.
 */
object NotificationPermissionPolicy {
    /** First Android version where notifications are a runtime permission. */
    const val RUNTIME_PERMISSION_SDK = 33

    /**
     * Whether asking for the notification permission again can do nothing, so
     * the only way out is the app's notification settings (H-T11-1):
     *
     * - They are on: nothing to ask.
     * - Before Android 13 there is no prompt at all; they can only be turned
     *   on in the settings.
     * - The permission is granted but the notifications are switched off in
     *   the settings (per app switch): a prompt cannot change that.
     * - Android 13+, permission denied: the system stops showing the prompt
     *   after the user denied it twice. `shouldShowRequestPermissionRationale`
     *   is false both before the first ask and after that second denial, so
     *   [askedBefore] (we asked at least once) tells them apart.
     */
    fun isBlocked(
        sdk: Int,
        notificationsEnabled: Boolean,
        permissionGranted: Boolean,
        askedBefore: Boolean,
        shouldShowRationale: Boolean,
    ): Boolean {
        if (notificationsEnabled) return false
        if (sdk < RUNTIME_PERMISSION_SDK) return true
        if (permissionGranted) return true
        return askedBefore && !shouldShowRationale
    }

    /**
     * Whether the "we asked once" mark must be cleared: the permission is
     * granted now. Left set, a later revocation from the settings would read
     * as "asked and denied for good" ([isBlocked]) when the system would show
     * the prompt again.
     */
    fun shouldForgetAsked(permissionGranted: Boolean, askedBefore: Boolean): Boolean =
        permissionGranted && askedBefore
}

/** Which broadcasts say that the device clock moved under a running app. */
object ClockChangePolicy {
    const val TIMEZONE = "timezone"
    const val TIME = "time"

    const val ACTION_TIMEZONE_CHANGED = "android.intent.action.TIMEZONE_CHANGED"
    const val ACTION_TIME_SET = "android.intent.action.TIME_SET"

    /** What the Dart side hears for [action]; null for anything else. */
    fun kindOf(action: String?): String? = when (action) {
        ACTION_TIMEZONE_CHANGED -> TIMEZONE
        ACTION_TIME_SET -> TIME
        else -> null
    }
}
