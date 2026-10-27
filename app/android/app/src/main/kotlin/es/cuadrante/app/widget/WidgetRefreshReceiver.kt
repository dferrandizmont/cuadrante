package es.cuadrante.app.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Redraws every widget and arms the next midnight alarm. Declared for:
 *  - our own midnight alarm ([WidgetScheduler.ACTION_MIDNIGHT]);
 *  - the system's date, time and time-zone changes, which change "today"
 *    without any alarm of ours going off;
 *  - boot and app update, which lose the alarm.
 *
 * It does not matter which one fires: [WidgetRenderer.refreshAll] reads the
 * clock, so the widgets show the device's current day whatever the cause.
 */
class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "refresh: ${intent.action}")
        try {
            WidgetRenderer.refreshAll(context)
        } catch (e: RuntimeException) {
            // A broken snapshot or a launcher hiccup must never crash the app.
            Log.w(TAG, "refresh failed", e)
        }
        try {
            WidgetScheduler.scheduleNext(context)
            if (WidgetRenderer.allIds(context).isNotEmpty()) WidgetScheduler.ensureWorker(context)
        } catch (e: RuntimeException) {
            Log.w(TAG, "could not re-arm", e)
        }
    }

    private companion object {
        const val TAG = "CuadranteWidget"
    }
}
