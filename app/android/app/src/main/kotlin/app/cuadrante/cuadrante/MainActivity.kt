package app.cuadrante.cuadrante

import android.content.ContentResolver
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Opens a `.cuadrante` that another app hands to Cuadrante (WhatsApp, Files,
 * Drive) and answers whether the system backup is on. Documented in
 * docs/copia-de-seguridad.md ("Abrir un .cuadrante desde otra app").
 *
 * Safety limits, all on purpose:
 * - Only `content://` URIs are read. A `file://` URI (which would let another
 *   app point us at our own private files) is ignored.
 * - The bytes are read through the [android.content.ContentResolver] with the
 *   permission the sender granted for that one URI, in 64 KB chunks and never
 *   more than [MAX_BYTES] (the same 8 MB cap as `BackupCodec.maxFileBytes`):
 *   a bigger file is refused without reading the rest.
 * - The read happens off the UI thread, on a thread of its own per file, with
 *   an overall 60 s deadline ([DeadlineReader]): a provider that hangs ends as
 *   `{error: "unreadable"}` and cannot hold up the next file.
 * - Nothing is restored here. Dart gets the bytes, decodes and validates them
 *   (`BackupCodec.decode`) and shows the preview; only the user's confirmation
 *   replaces data.
 * - The URI is remembered, not the bytes, until Dart asks for them once. A
 *   launch intent that Android hands back (recreation, recents) is not
 *   remembered again ([LaunchPolicy]).
 * - "Guardar en el móvil" (`saveDocument`) opens the system's save dialog and
 *   writes the exported bytes to the one place the user picks ([DocumentSaver]).
 * - The alarm sound picker (`AlarmSoundChannel`, channel `app.cuadrante/sounds`)
 *   lives in its own class; this activity only registers it and forwards the
 *   result of the system picker.
 * - The preview is protected against tapjacking: while it is on screen, touches
 *   through an overlay are dropped (`filterTouchesWhenObscured`) and, from
 *   Android 12, other apps' overlay windows are hidden.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var sounds: AlarmSoundChannel? = null
    private var alarmSystem: AlarmSystemChannel? = null
    private val saver = DocumentSaver(this)
    private var pendingUri: Uri? = null
    private var pendingSender: String? = null
    private var restoredFromState = false
    private val reader = DeadlineReader(DeadlineReader.DEFAULT_DEADLINE_MILLIS)

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before super: configureFlutterEngine runs inside it.
        restoredFromState = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPending" -> result.success(pendingUri != null)
                "discardPending" -> {
                    consumePending()
                    result.success(null)
                }
                "readPending" -> readPending(result)
                "saveDocument" -> saver.save(
                    call.argument<String>("fileName"),
                    call.argument<ByteArray>("bytes"),
                    result,
                )
                "systemBackupState" -> result.success(systemBackupState())
                "setPreviewProtection" -> {
                    setPreviewProtection(call.arguments == true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        this.channel = channel
        val sounds = AlarmSoundChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AlarmSoundChannel.CHANNEL)
            .setMethodCallHandler(sounds)
        this.sounds?.shutdown()
        this.sounds = sounds
        alarmSystem?.stop()
        alarmSystem = AlarmSystemChannel(this, flutterEngine.dartExecutor.binaryMessenger).also {
            it.start()
        }
        // The intent the app was started with; Dart asks for it once it is up.
        // Not when Android hands the same one back (recreated, or reopened from
        // the recents list): that file was dealt with the first time.
        val launch = intent
        if (LaunchPolicy.isFreshFile(restoredFromState, launch?.flags ?: 0)) {
            rememberFileOf(launch)
        } else {
            setIntent(Intent(Intent.ACTION_MAIN))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // The activity's own intent is the newest one (the referrer below is
        // read from it).
        setIntent(intent)
        // singleTop: the app was already running and got a file.
        if (LaunchPolicy.isFreshFile(false, intent.flags) && rememberFileOf(intent)) {
            channel?.invokeMethod("incomingAvailable", null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (sounds?.onActivityResult(requestCode, resultCode, data) == true) return
        if (saver.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        sounds?.shutdown()
        alarmSystem?.stop()
        reader.shutdown()
        saver.shutdown()
        super.onDestroy()
    }

    /** Remembers the content URI of a VIEW or SEND intent. True if there was one. */
    private fun rememberFileOf(intent: Intent?): Boolean {
        val uri: Uri? = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND ->
                if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            else -> null
        }
        if (uri == null || uri.scheme != ContentResolver.SCHEME_CONTENT) return false
        pendingUri = uri
        pendingSender = senderOf(intent)
        return true
    }

    /** Forgets the remembered file, and the launch intent that carried it. */
    private fun consumePending() {
        pendingUri = null
        pendingSender = null
        // So that Android has no VIEW/SEND intent left to hand back to us.
        setIntent(Intent(Intent.ACTION_MAIN))
    }

    /**
     * Who sent the file, for the preview: `"Label (package)"` or just the
     * package, or `null` when the system does not say. **Informational, not a
     * proof, and it grants nothing**: the user's confirmation is the only gate.
     * The `EXTRA_REFERRER*` extras, with which an intent can claim to come from
     * someone else, are removed first, so [getReferrer] answers with what the
     * system recorded about the caller.
     */
    private fun senderOf(intent: Intent?): String? {
        intent?.removeExtra(Intent.EXTRA_REFERRER)
        intent?.removeExtra(Intent.EXTRA_REFERRER_NAME)
        val pkg = try {
            Referrer.packageOf(referrer?.toString())
        } catch (e: Exception) {
            null
        } ?: return null
        if (pkg == packageName) return null
        val label = try {
            @Suppress("DEPRECATION")
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (e: Exception) {
            // Package visibility (Android 11+): most apps cannot be looked up.
            null
        }
        return Referrer.display(pkg, label)
    }

    /**
     * Hands the remembered file to Dart, once: `null` when there is none,
     * `{bytes: ByteArray, sender: String?}`, or
     * `{error: "tooLarge" | "unreadable"}` (also when the 60 s deadline passes).
     */
    private fun readPending(result: MethodChannel.Result) {
        val uri = pendingUri
        if (uri == null) {
            result.success(null)
            return
        }
        val sender = pendingSender
        consumePending()
        reader.start(
            open = { contentResolver.openInputStream(uri) },
            maxBytes = MAX_BYTES,
        ) { outcome ->
            val reply: Map<String, Any?> = when (outcome) {
                is ReadOutcome.Bytes -> mapOf("bytes" to outcome.bytes, "sender" to sender)
                ReadOutcome.TooLarge -> mapOf("error" to "tooLarge")
                ReadOutcome.Unreadable -> mapOf("error" to "unreadable")
            }
            runOnUiThread {
                try {
                    result.success(reply)
                } catch (e: Exception) {
                    // The engine went away while the file was being read.
                }
            }
        }
    }

    /**
     * Tapjacking guard of the restore preview: another app's overlay must not
     * be able to sit over "Restaurar" and pass a tap through.
     * - `filterTouchesWhenObscured` on the window's root view: a touch that
     *   reaches it while another window covers it is dropped (all versions).
     * - Android 12+: other apps' overlay windows are hidden outright
     *   (`HIDE_OVERLAY_WINDOWS`, a normal permission declared in the manifest).
     */
    private fun setPreviewProtection(on: Boolean) {
        window.decorView.filterTouchesWhenObscured = on
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                window.setHideOverlayWindows(on)
            } catch (e: SecurityException) {
                // Permission missing: the touch filter above still applies.
            }
        }
    }

    /**
     * Whether Google's backup is on for the user: "on", "off", or "unknown" when
     * the phone does not say (it is a system setting that apps are not meant to
     * read, so any doubt is "unknown", never a guess), or when the app itself
     * opted out of backups.
     */
    private fun systemBackupState(): String {
        return try {
            if ((applicationInfo.flags and ApplicationInfo.FLAG_ALLOW_BACKUP) == 0) {
                "off"
            } else {
                when (Settings.Secure.getInt(contentResolver, "backup_enabled", -1)) {
                    1 -> "on"
                    0 -> "off"
                    else -> "unknown"
                }
            }
        } catch (e: Exception) {
            "unknown"
        }
    }

    companion object {
        private const val CHANNEL = "app.cuadrante/backup"

        /** Same as `BackupCodec.maxFileBytes`. */
        private const val MAX_BYTES = 8 * 1024 * 1024
    }
}
