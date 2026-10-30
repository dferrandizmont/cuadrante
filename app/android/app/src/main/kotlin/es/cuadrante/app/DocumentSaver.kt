package es.cuadrante.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * "Guardar en el móvil": hands the bytes of an exported `.turnly` to the
 * system's own save dialog (`ACTION_CREATE_DOCUMENT`, the Storage Access
 * Framework), so the user picks the folder (Descargas, a card, a cloud app)
 * without the app asking for any storage permission.
 *
 * Part of the `app.cuadrante/backup` channel, method `saveDocument({fileName,
 * bytes})`. Replies `"saved"`, `"cancelled"` (the user went back: nothing was
 * written) or fails with `PlatformException`:
 * - `busy`: a save dialog is already open.
 * - `unavailable`: no app can show the dialog.
 * - `unwritable`: the chosen place refused the bytes.
 *
 * The app writes only what Dart sent, to the one URI the user chose; it never
 * reads that place back and keeps no permission to it.
 *
 * If the activity is re-created while the dialog is open, the new instance has
 * no bytes to write: the dialog has already created an EMPTY document, so it
 * is deleted (`DocumentsContract.deleteDocument`, only if the provider says it
 * is 0 bytes: a replaced existing file is left alone) and the reply that was left
 * waiting is failed with `unwritable`, which Dart shows as «couldn't save».
 */
class DocumentSaver(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private val writer: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "cuadrante-save").apply { isDaemon = true }
    }

    fun save(fileName: String?, bytes: ByteArray?, result: MethodChannel.Result) {
        if (fileName == null || bytes == null) {
            result.error("bad_args", "fileName and bytes are required", null)
            return
        }
        if (pending != null) {
            result.error("busy", "A save dialog is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = MIME_TYPE
            putExtra(Intent.EXTRA_TITLE, DocumentName.sanitize(fileName))
        }
        pending = result
        pendingBytes = bytes
        waiting = result
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_SAVE_DOCUMENT)
        } catch (e: Exception) {
            pending = null
            pendingBytes = null
            waiting = null
            result.error("unavailable", "No app can save the file", null)
        }
    }

    /** Forwarded from `Activity.onActivityResult`. True if the request was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE_DOCUMENT) return false
        val result = pending
        if (result == null) {
            discardLostSave(resultCode, data?.data)
            return true
        }
        val bytes = pendingBytes
        pending = null
        pendingBytes = null
        waiting = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            result.success("cancelled")
            return true
        }
        // The write can take a moment (a cloud provider): off the UI thread.
        writer.execute {
            val failed = try {
                // "wt": replace what the dialog may have left in an existing file.
                val out = activity.contentResolver.openOutputStream(uri, "wt")
                    ?: throw java.io.IOException("no stream")
                out.use { it.write(bytes) }
                false
            } catch (e: Exception) {
                true
            }
            activity.runOnUiThread {
                try {
                    if (failed) {
                        result.error("unwritable", "The place refused the file", null)
                    } else {
                        result.success("saved")
                    }
                } catch (e: Exception) {
                    // The engine went away while the file was being written.
                }
            }
        }
        return true
    }

    /**
     * The dialog answered a save that this instance knows nothing about (the
     * activity was re-created meanwhile): the bytes are gone. Removes the
     * empty document the dialog created, if it did, and fails the reply left
     * waiting by the old instance (best effort: its engine may be gone too).
     */
    private fun discardLostSave(resultCode: Int, uri: Uri?) {
        val lost = waiting
        waiting = null
        val created = resultCode == Activity.RESULT_OK && uri != null
        // The user may have picked an existing file to replace: delete only a
        // document we know is empty, never one with someone's old backup in it.
        if (created && isEmptyDocument(uri!!)) {
            try {
                DocumentsContract.deleteDocument(activity.contentResolver, uri)
            } catch (e: Exception) {
                // The place does not allow it: the file stays, empty.
            }
        }
        try {
            if (created) {
                lost?.error("unwritable", "The save was interrupted", null)
            } else {
                lost?.success("cancelled")
            }
        } catch (e: Exception) {
            // The engine that was waiting for it is gone.
        }
    }

    /** True only when the provider reports a size of exactly 0 bytes. */
    private fun isEmptyDocument(uri: Uri): Boolean = try {
        activity.contentResolver.query(
            uri, arrayOf(OpenableColumns.SIZE), null, null, null,
        )?.use { c ->
            val col = c.getColumnIndex(OpenableColumns.SIZE)
            c.moveToFirst() && col >= 0 && !c.isNull(col) && c.getLong(col) == 0L
        } ?: false
    } catch (e: Exception) {
        false
    }

    fun shutdown() {
        writer.shutdown()
    }

    companion object {
        private const val REQUEST_SAVE_DOCUMENT = 4208

        /**
         * The reply of the save waiting for the dialog. Kept per process, not
         * per instance, so an activity re-created while the dialog is open
         * can still answer it (see [discardLostSave]).
         */
        @Volatile
        private var waiting: MethodChannel.Result? = null
        const val MIME_TYPE = "application/octet-stream"
    }
}

/** Pure Kotlin, so the JVM unit tests cover it. */
object DocumentName {
    /** A name with no folder in it, whatever Dart sent; never empty. */
    fun sanitize(name: String): String {
        val last = name.substringAfterLast('/').substringAfterLast('\\').trim()
        return last.ifEmpty { "turnly.turnly" }
    }
}
