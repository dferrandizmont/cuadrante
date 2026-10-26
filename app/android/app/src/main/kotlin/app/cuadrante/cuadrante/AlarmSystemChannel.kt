package app.cuadrante.cuadrante

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

/**
 * The `app.cuadrante/alarm_system` channel (docs/alarmas.md, "Permiso de
 * notificaciones denegado" and "Cambio de hora o de zona con la app abierta").
 *
 * Dart asks:
 * - `notificationsBlocked`: true when the notifications are off and asking
 *   again would do nothing ([NotificationPermissionPolicy]).
 * - `markNotificationsAsked`: call right before the system prompt, so that
 *   "never asked" and "denied for good" can be told apart.
 * - `openNotificationSettings`: opens the app's notification settings
 *   (`ACTION_APP_NOTIFICATION_SETTINGS`); falls back to the app details
 *   screen. Replies whether a screen opened.
 *
 * Android tells Dart (while the process lives):
 * - `clockChanged("timezone" | "time")` on `TIMEZONE_CHANGED` / `TIME_SET`.
 *   The receiver is registered at runtime (these broadcasts are not delivered
 *   to manifest receivers of apps that are not running anyway, and the widget
 *   has its own); it lives as long as the engine does.
 */
class AlarmSystemChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val kind = ClockChangePolicy.kindOf(intent?.action) ?: return
            if (kind == ClockChangePolicy.TIMEZONE) {
                // The JVM caches the default zone; the system resets it for
                // the process on its own, but not necessarily before this
                // broadcast arrives.
                TimeZone.setDefault(null)
            }
            channel.invokeMethod("clockChanged", kind)
        }
    }
    private var registered = false

    fun start() {
        if (registered) return
        val filter = IntentFilter().apply {
            addAction(ClockChangePolicy.ACTION_TIMEZONE_CHANGED)
            addAction(ClockChangePolicy.ACTION_TIME_SET)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity.registerReceiver(receiver, filter)
        }
        registered = true
    }

    fun stop() {
        if (registered) {
            try {
                activity.unregisterReceiver(receiver)
            } catch (e: IllegalArgumentException) {
                // Already gone.
            }
            registered = false
        }
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "notificationsBlocked" -> result.success(notificationsBlocked())
            "markNotificationsAsked" -> {
                preferences().edit().putBoolean(KEY_ASKED, true).apply()
                result.success(null)
            }
            "openNotificationSettings" -> result.success(openNotificationSettings())
            else -> result.notImplemented()
        }
    }

    private fun preferences() =
        activity.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun notificationsBlocked(): Boolean {
        val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val granted = Build.VERSION.SDK_INT < NotificationPermissionPolicy.RUNTIME_PERMISSION_SDK ||
            activity.checkSelfPermission(POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        val rationale = Build.VERSION.SDK_INT >= 33 &&
            activity.shouldShowRequestPermissionRationale(POST_NOTIFICATIONS)
        var asked = preferences().getBoolean(KEY_ASKED, false)
        if (NotificationPermissionPolicy.shouldForgetAsked(granted, asked)) {
            // Granted now: a later revocation starts from "never asked".
            preferences().edit().putBoolean(KEY_ASKED, false).apply()
            asked = false
        }
        return NotificationPermissionPolicy.isBlocked(
            sdk = Build.VERSION.SDK_INT,
            notificationsEnabled = manager.areNotificationsEnabled(),
            permissionGranted = granted,
            askedBefore = asked,
            shouldShowRationale = rationale,
        )
    }

    private fun openNotificationSettings(): Boolean {
        val notifications = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        val details = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", activity.packageName, null),
        )
        for (intent in listOf(notifications, details)) {
            try {
                activity.startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next screen.
            } catch (e: SecurityException) {
                // Same.
            }
        }
        return false
    }

    companion object {
        const val CHANNEL = "app.cuadrante/alarm_system"
        private const val PREFERENCES = "cuadrante_alarm_system"
        private const val KEY_ASKED = "notifications_asked"
        private const val POST_NOTIFICATIONS = "android.permission.POST_NOTIFICATIONS"
    }
}
