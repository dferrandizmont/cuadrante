package app.cuadrante.cuadrante

/**
 * Decisions about incoming intents that need no Android classes, so the JVM
 * unit tests in `src/test` cover them.
 */
object LaunchPolicy {
    /** `Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`. */
    const val FLAG_LAUNCHED_FROM_HISTORY = 0x00100000

    /**
     * Whether the file of the intent the activity was started with is new.
     *
     * Android hands the *original* launch intent back when the activity is
     * recreated (rotation, the system killed the process) or opened again from
     * the recents list. Remembering its file then would open the restore
     * preview once more on every such start: a file the user already dealt
     * with would come back.
     */
    fun isFreshFile(hasSavedInstanceState: Boolean, intentFlags: Int): Boolean =
        !hasSavedInstanceState && (intentFlags and FLAG_LAUNCHED_FROM_HISTORY) == 0
}

/** Who sent the file, from the referrer URI the system reports. */
object Referrer {
    private const val ANDROID_APP = "android-app://"

    /**
     * The package in an `android-app://<package>[/...]` referrer, or `null`
     * for anything else (a web page, nothing). Informational only: the
     * preview shows it to the user, it grants nothing.
     */
    fun packageOf(referrer: String?): String? {
        if (referrer == null || !referrer.startsWith(ANDROID_APP)) return null
        val authority = referrer.substring(ANDROID_APP.length).substringBefore('/')
            .substringBefore('?').substringBefore('#')
        return authority.takeIf { it.isNotBlank() && it.length <= 255 && it.all(::isPackageChar) }
    }

    private fun isPackageChar(c: Char) = c.isLetterOrDigit() || c == '.' || c == '_'

    /** Longest app label shown next to the package. */
    const val MAX_LABEL = 50

    /**
     * What the preview shows as the sender. The package is verified by the
     * system and goes FIRST; the app label is chosen by that app (a hostile
     * one can call itself "WhatsApp"), so it is only a hint after it, without
     * control, line-break or bidi characters and capped at [MAX_LABEL].
     */
    fun display(pkg: String, label: String?): String {
        val clean = label
            ?.replace(Regex("\\s+"), " ")
            ?.filter { !it.isISOControl() && Character.getType(it) != Character.FORMAT.toInt() }
            ?.trim()
            ?.take(MAX_LABEL)
        return if (clean.isNullOrBlank() || clean == pkg) pkg else "$pkg · $clean"
    }
}
