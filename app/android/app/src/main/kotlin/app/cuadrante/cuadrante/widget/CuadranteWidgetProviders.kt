package app.cuadrante.cuadrante.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

/**
 * Base of the three widgets. The launcher (or `home_widget`'s `updateWidget`
 * after the app publishes) asks for an update; every update draws from the
 * clock and arms the next midnight alarm.
 *
 * The class names are part of the contract with the Dart side
 * (`kWidgetSmallProvider`, `kWidgetMediumProvider`, `kWidgetLargeProvider`) and with the widgets
 * already placed: renaming one orphans them.
 */
abstract class CuadranteWidgetProvider(private val kind: WidgetModelBuilder.Kind) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        WidgetRenderer.update(context, manager, appWidgetIds, kind)
        WidgetScheduler.scheduleNext(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        WidgetRenderer.update(context, manager, intArrayOf(appWidgetId), kind)
    }

    override fun onEnabled(context: Context) {
        WidgetScheduler.ensureWorker(context)
        WidgetScheduler.scheduleNext(context)
    }

    override fun onDisabled(context: Context) {
        // The last widget of this size is gone; stop the timers if it was the last of all.
        if (WidgetRenderer.allIds(context).isEmpty()) WidgetScheduler.cancel(context)
    }
}

/** 2x2: today and tomorrow. */
class CuadranteSmallWidgetProvider : CuadranteWidgetProvider(WidgetModelBuilder.Kind.SMALL)

/** 4x2: the next seven days. */
class CuadranteMediumWidgetProvider : CuadranteWidgetProvider(WidgetModelBuilder.Kind.MEDIUM)

/** 4x4: the month grid. */
class CuadranteLargeWidgetProvider : CuadranteWidgetProvider(WidgetModelBuilder.Kind.LARGE)

/** Resizable list of today and the next days, up to fourteen. */
class CuadranteAgendaWidgetProvider : CuadranteWidgetProvider(WidgetModelBuilder.Kind.AGENDA)

/** 4x2: current Monday-first week and the following week. */
class CuadranteTwoWeeksWidgetProvider : CuadranteWidgetProvider(WidgetModelBuilder.Kind.TWO_WEEKS)
