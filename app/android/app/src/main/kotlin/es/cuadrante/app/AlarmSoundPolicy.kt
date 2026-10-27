package es.cuadrante.app

/**
 * Decisions about alarm sounds that need no Android classes, so the JVM unit
 * tests in `src/test` cover them (docs/alarmas.md, "Sonido por tipo de turno").
 */
object AlarmSoundPolicy {
    /** Same as `maxAlarmSoundLength` in `shift_type.dart`. */
    const val MAX_URI_LENGTH = 512

    /** Longest sound title handed to Dart. */
    const val MAX_TITLE_LENGTH = 80

    /** Longest wait for one question to a content provider. */
    const val CHECK_TIMEOUT_SECONDS = 3L

    private const val CONTENT_PREFIX = "content://"

    /**
     * The only content authorities a sound may come from: the media store
     * (ringtones, user-added ones included) and the settings provider (the
     * default entries). Anything else, our own FileProvider
     * (`<appId>.flutter.share_provider`) and any other app's included, is
     * refused: a backup or a crafted intent must not make the app open it.
     */
    val ALLOWED_AUTHORITIES: Set<String> = setOf("media", "settings")

    /**
     * Whether [uri] can be stored as the sound of a shift type: a `content://`
     * URI of an allowed authority ([ALLOWED_AUTHORITIES], compared exactly, so
     * `media@other` or `media.evil` do not pass) that fits the database limit.
     * A `file://` URI is never taken (it could point at the app's own private
     * files, and Android refuses to hand it to the notification service
     * anyway).
     */
    fun isAcceptable(uri: String?): Boolean {
        if (uri == null || uri.length > MAX_URI_LENGTH || !uri.startsWith(CONTENT_PREFIX)) return false
        val rest = uri.substring(CONTENT_PREFIX.length)
        val authority = rest.takeWhile { it != '/' && it != '?' && it != '#' }
        return authority in ALLOWED_AUTHORITIES
    }

    /**
     * Runs [work] on [pool] and waits at most [timeoutSeconds] for it; [fallback]
     * answers a timeout or a failure. The wait is per call: a provider that
     * never answers keeps only its own pool thread (cancelled, interrupted)
     * and the next call goes to another one when [pool] is a cached pool.
     */
    fun <T> runBounded(
        pool: java.util.concurrent.ExecutorService,
        timeoutSeconds: Long,
        fallback: T,
        work: () -> T,
    ): T {
        val future = pool.submit(java.util.concurrent.Callable { work() })
        return try {
            future.get(timeoutSeconds, java.util.concurrent.TimeUnit.SECONDS)
        } catch (e: Exception) {
            // Timeout, failure or interruption: the caller gets the safe answer.
            future.cancel(true)
            fallback
        }
    }

    /**
     * What Dart gets for the URI the picker returned: `null` means "the
     * default sound" (nothing picked, the default entry of the list, or a URI
     * we would not store); anything else is the URI to keep.
     */
    fun normalize(picked: String?, defaultUri: String?): String? = when {
        picked == null -> null
        picked == defaultUri -> null
        isAcceptable(picked) -> picked
        else -> null
    }

    /**
     * A sound title safe to show: whitespace collapsed, no control, line-break
     * or bidi characters, capped at [MAX_TITLE_LENGTH]; `null` when nothing is
     * left. It comes from a content provider, so it is treated as untrusted.
     */
    fun cleanTitle(raw: String?): String? =
        raw?.replace(Regex("\\s+"), " ")
            ?.filter { !it.isISOControl() && Character.getType(it) != Character.FORMAT.toInt() }
            ?.trim()
            ?.take(MAX_TITLE_LENGTH)
            ?.takeIf { it.isNotEmpty() }
}
