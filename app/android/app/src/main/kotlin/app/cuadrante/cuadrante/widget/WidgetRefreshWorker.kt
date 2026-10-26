package app.cuadrante.cuadrante.widget

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * The safety net: every few hours (WorkManager keeps it across reboots)
 * redraws the widgets and re-arms the midnight alarm, in case the alarm was
 * lost (an aggressive battery manager, a force stop that was later undone).
 */
class WidgetRefreshWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        Log.i("CuadranteWidget", "refresh: work")
        return try {
            WidgetRenderer.refreshAll(applicationContext)
            WidgetScheduler.scheduleNext(applicationContext)
            Result.success()
        } catch (e: RuntimeException) {
            Log.w("CuadranteWidget", "work failed", e)
            Result.retry()
        }
    }
}
