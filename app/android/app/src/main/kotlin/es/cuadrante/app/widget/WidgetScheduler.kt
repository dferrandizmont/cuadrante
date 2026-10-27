package es.cuadrante.app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.ZoneId
import java.util.concurrent.TimeUnit

/**
 * Arms the two timers that keep the widgets on the right day when the app is
 * closed (`docs/widget-contrato.md`, "Android"):
 *
 *  - an alarm just after the next local midnight ([scheduleNext]),
 *    exact when the user allows it, inexact otherwise. Every refresh arms the
 *    next one, and a reboot, an update of the app or a change of date, time
 *    or zone re-arms it ([WidgetRefreshReceiver]);
 *  - a WorkManager task every 6 hours as a safety net ([ensureWorker]).
 *
 * Neither is needed for correctness of a single draw — each draw reads the
 * clock — only to make sure a draw happens soon after the day changes.
 */
object WidgetScheduler {
    private const val TAG = "CuadranteWidget"
    private const val REQUEST_CODE = 4101
    private const val WORK_NAME = "cuadrante.widget.refresh"

    /** Action of our own midnight alarm. */
    const val ACTION_MIDNIGHT = "es.cuadrante.app.widget.action.MIDNIGHT"

    /** Seconds after midnight when the alarm goes off (the draw reads the clock, so any margin is safe). */
    const val MARGIN_SECONDS = 2L

    /** Period of the WorkManager safety net. */
    const val WORK_HOURS = 6L

    private fun alarmIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetRefreshReceiver::class.java).setAction(ACTION_MIDNIGHT)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Arms the alarm for the next local midnight (+1 min), replacing the
     * previous one; with no widget placed, cancels it instead. Returns the
     * trigger time (null when cancelled).
     */
    fun scheduleNext(
        context: Context,
        nowMillis: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault(),
    ): Long? {
        if (WidgetRenderer.allIds(context).isEmpty()) {
            cancel(context)
            return null
        }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = WidgetDayLogic.nextRefreshMillis(nowMillis, zone, MARGIN_SECONDS)
        val pending = alarmIntent(context)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
        try {
            if (exact) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            } else {
                setInexact(alarms, at, pending)
            }
        } catch (e: SecurityException) {
            // The permission was revoked between the check and the call.
            setInexact(alarms, at, pending)
        }
        Log.i(TAG, "next refresh at $at (${if (exact) "exact" else "inexact"})")
        return at
    }

    /**
     * Without the exact-alarm permission the system picks the delivery time
     * inside a window of 75 % of the time left, up to one hour (`dumpsys
     * alarm` shows it; a tighter window is refused). So the day can change
     * on the widget up to an hour late until the user allows exact alarms;
     * the date/time/zone broadcasts, the WorkManager refresh and any visit to
     * the app redraw it earlier.
     */
    private fun setInexact(alarms: AlarmManager, at: Long, pending: PendingIntent) {
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
    }

    fun cancel(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(alarmIntent(context))
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }

    /** Keeps the periodic safety net enqueued (once, however often this is called). */
    fun ensureWorker(context: Context) {
        val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(WORK_HOURS, TimeUnit.HOURS).build()
        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
    }
}
