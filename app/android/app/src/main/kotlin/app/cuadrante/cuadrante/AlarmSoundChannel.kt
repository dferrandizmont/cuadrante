package app.cuadrante.cuadrante

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * The `app.cuadrante/sounds` channel: lets the user choose the sound of the
 * alarms of a shift type with the system's own picker and checks that a chosen
 * sound can still be played (docs/alarmas.md, "Sonido por tipo de turno").
 *
 * - `pick({current})`: opens `ACTION_RINGTONE_PICKER` (alarm and notification
 *   sounds, with the default entry, without "silent"). Replies `null` when the
 *   user goes back, otherwise `{uri: String?, title: String?}`; a null `uri`
 *   is "the default sound" ([AlarmSoundPolicy.normalize]).
 * - `title({uri})`: the sound's display name, or `null` when it cannot be read.
 * - `isAvailable({uri})`: whether the sound can be opened. Anything that
 *   throws or takes longer than 3 s is "no": the alarm then rings on the
 *   default channel. Each call waits on its own thread, so a provider that
 *   never answers does not block the other calls.
 *
 * Only `content://` URIs travel, and nothing is played here. No resource is
 * involved, so R8 has nothing to strip.
 */
class AlarmSoundChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var pending: MethodChannel.Result? = null
    // Cached, daemon threads: every call waits on its own thread for at most
    // CHECK_TIMEOUT_SECONDS, so one stuck provider never holds up the rest.
    private val worker: ExecutorService = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "alarm-sound").apply { isDaemon = true }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(call.argument<String>("current"), result)
            "title" -> inBackground(call.argument<String>("uri"), result, null) { titleOf(it) }
            "isAvailable" -> inBackground(call.argument<String>("uri"), result, false) { canOpen(it) }
            else -> result.notImplemented()
        }
    }

    private fun pick(current: String?, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A sound is already being picked", null)
            return
        }
        val existing = current?.takeIf { AlarmSoundPolicy.isAcceptable(it) }?.let(Uri::parse)
            ?: Settings.System.DEFAULT_NOTIFICATION_URI
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_NOTIFICATION,
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI, Settings.System.DEFAULT_NOTIFICATION_URI)
            putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, existing)
        }
        pending = result
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_PICK_SOUND)
        } catch (e: Exception) {
            // No picker on this phone: the caller keeps what it had.
            pending = null
            result.success(null)
        }
    }

    /** Forwarded from `Activity.onActivityResult`. True if the request was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_SOUND) return false
        val result = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return true
        }
        val picked: Uri? = if (Build.VERSION.SDK_INT >= 33) {
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        val uri = AlarmSoundPolicy.normalize(
            picked?.toString(),
            Settings.System.DEFAULT_NOTIFICATION_URI.toString(),
        )
        if (uri == null) {
            result.success(mapOf("uri" to null, "title" to null))
            return true
        }
        // The title is read off the UI thread: a provider may be slow.
        worker.execute {
            val title = AlarmSoundPolicy.runBounded(worker, AlarmSoundPolicy.CHECK_TIMEOUT_SECONDS, null) {
                titleOf(uri)
            }
            activity.runOnUiThread { result.success(mapOf("uri" to uri, "title" to title)) }
        }
        return true
    }

    /**
     * Runs [work] on the worker thread with the `uri` argument and replies on
     * the UI thread; [fallback] answers a missing argument or a failure.
     */
    private fun inBackground(
        uri: String?,
        result: MethodChannel.Result,
        fallback: Any?,
        work: (String) -> Any?,
    ) {
        if (uri == null) {
            result.success(fallback)
            return
        }
        worker.execute {
            val reply = AlarmSoundPolicy.runBounded(worker, AlarmSoundPolicy.CHECK_TIMEOUT_SECONDS, fallback) {
                work(uri)
            }
            try {
                activity.runOnUiThread { result.success(reply) }
            } catch (e: Exception) {
                // The engine went away meanwhile.
            }
        }
    }

    private fun titleOf(uri: String): String? = try {
        if (!AlarmSoundPolicy.isAcceptable(uri)) {
            null
        } else {
            AlarmSoundPolicy.cleanTitle(
                RingtoneManager.getRingtone(activity, Uri.parse(uri))?.getTitle(activity),
            )
        }
    } catch (e: Exception) {
        null
    }

    private fun canOpen(uri: String): Boolean = try {
        AlarmSoundPolicy.isAcceptable(uri) &&
            (activity.contentResolver.openAssetFileDescriptor(Uri.parse(uri), "r")?.use { true } ?: false)
    } catch (e: Exception) {
        false
    }

    fun shutdown() {
        // The Activity is going away with the picker open: answer "went back"
        // so the Dart side does not wait for ever.
        val waiting = pending
        pending = null
        try {
            waiting?.success(null)
        } catch (e: Exception) {
            // The engine is already gone.
        }
        worker.shutdown()
    }

    companion object {
        const val CHANNEL = "app.cuadrante/sounds"
        private const val REQUEST_PICK_SOUND = 4207
    }
}
