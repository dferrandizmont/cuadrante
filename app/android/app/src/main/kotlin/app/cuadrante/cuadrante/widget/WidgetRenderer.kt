package app.cuadrante.cuadrante.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.graphics.Paint
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import app.cuadrante.cuadrante.MainActivity
import app.cuadrante.cuadrante.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.ZoneId

/**
 * Draws the five home-screen widgets from the snapshot the Flutter side stores
 * (`docs/widget-contrato.md`). Nothing here knows about shifts: it picks the
 * day for the device's CURRENT local date ([WidgetModelBuilder], which uses
 * [WidgetDayLogic]) and paints what the snapshot says, with its colours.
 *
 * Every draw reads the clock again, so any trigger (the midnight alarm, the
 * date/time/zone broadcasts, the WorkManager refresh, the launcher asking for
 * an update) shows the right day.
 */
object WidgetRenderer {
    /** Where `home_widget` stores what the app saves ([SNAPSHOT_KEY]). */
    private const val PREFERENCES = "HomeWidgetPreferences"
    const val SNAPSHOT_KEY = "cuadrante.widget.snapshot"

    val providers: List<Pair<Class<*>, WidgetModelBuilder.Kind>> = listOf(
        CuadranteSmallWidgetProvider::class.java to WidgetModelBuilder.Kind.SMALL,
        CuadranteMediumWidgetProvider::class.java to WidgetModelBuilder.Kind.MEDIUM,
        CuadranteLargeWidgetProvider::class.java to WidgetModelBuilder.Kind.LARGE,
        CuadranteAgendaWidgetProvider::class.java to WidgetModelBuilder.Kind.AGENDA,
        CuadranteTwoWeeksWidgetProvider::class.java to WidgetModelBuilder.Kind.TWO_WEEKS,
    )

    private fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun snapshotJson(context: Context): String? =
        preferences(context).getString(SNAPSHOT_KEY, null)

    /** Ids of every placed widget of every size. */
    fun allIds(context: Context): IntArray {
        val manager = AppWidgetManager.getInstance(context)
        return providers.flatMap { (cls, _) ->
            manager.getAppWidgetIds(ComponentName(context, cls)).toList()
        }.toIntArray()
    }

    /** Redraws every placed widget now (the clock is read here). */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for ((cls, kind) in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isNotEmpty()) update(context, manager, ids, kind)
        }
    }

    /** Redraws [ids], widgets of [kind]. */
    fun update(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
        kind: WidgetModelBuilder.Kind,
        nowMillis: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault(),
    ) {
        if (ids.isEmpty()) return
        val json = snapshotJson(context)
        for (id in ids) {
            val options = manager.getAppWidgetOptions(id)
            val landscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
            val width = options.getInt(if (landscape) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
            val height = options.getInt(if (landscape) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110)
            val size = WidgetRenderPlan.Size(width.coerceAtLeast(1), height.coerceAtLeast(1), context.resources.configuration.fontScale)
            manager.updateAppWidget(id, render(context, kind, json, nowMillis, zone, size))
        }
    }

    fun render(
        context: Context,
        kind: WidgetModelBuilder.Kind,
        json: String?,
        nowMillis: Long,
        zone: ZoneId,
        size: WidgetRenderPlan.Size = WidgetRenderPlan.Size(),
    ): RemoteViews {
        val content = WidgetModelBuilder.build(json, kind, nowMillis, zone)
        val layout = when (kind) {
            WidgetModelBuilder.Kind.SMALL -> R.layout.widget_small
            WidgetModelBuilder.Kind.MEDIUM -> R.layout.widget_medium
            WidgetModelBuilder.Kind.LARGE -> R.layout.widget_month
            WidgetModelBuilder.Kind.AGENDA -> R.layout.widget_agenda
            WidgetModelBuilder.Kind.TWO_WEEKS -> R.layout.widget_two_weeks
        }
        val views = RemoteViews(context.packageName, layout)
        val painter = Painter(context, views)
        // Always both, whatever the state: the launcher re-applies the actions
        // on the views it already has, so a hidden/visible left by the
        // previous draw survives unless this one sets it again (H-T12-2).
        painter.root(kind, WidgetRenderPlan.root(content))
        when (content) {
            is WidgetContent.Stale -> painter.stale(content, kind == WidgetModelBuilder.Kind.AGENDA || kind == WidgetModelBuilder.Kind.TWO_WEEKS)
            is WidgetContent.Small -> painter.small(content)
            is WidgetContent.Medium -> painter.medium(content)
            is WidgetContent.Large -> painter.large(content)
            is WidgetContent.Agenda -> painter.agenda(content, size)
            is WidgetContent.TwoWeeks -> painter.twoWeeks(content, size)
        }
        return views
    }

    private class Painter(val context: Context, val views: RemoteViews) {
        private val night: Boolean =
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
                Configuration.UI_MODE_NIGHT_YES

        // ---- Stale ----------------------------------------------------------

        /** Sets the visibility of the message AND of the content (see [WidgetRenderPlan]). */
        fun root(kind: WidgetModelBuilder.Kind, plan: WidgetRenderPlan.Root) {
            // RemoteViews reapplies old views: clear the stale announcement first.
            views.setContentDescription(R.id.widget_root, null)
            views.setViewVisibility(R.id.stale, visible(plan.showStale))
            val content = visible(plan.showContent)
            when (kind) {
                WidgetModelBuilder.Kind.SMALL -> {
                    views.setViewVisibility(R.id.content, content)
                    views.setViewVisibility(R.id.tint, content)
                }
                WidgetModelBuilder.Kind.MEDIUM -> views.setViewVisibility(R.id.strip, content)
                WidgetModelBuilder.Kind.LARGE -> views.setViewVisibility(R.id.month_content, content)
                WidgetModelBuilder.Kind.AGENDA -> views.setViewVisibility(R.id.agenda_content, content)
                WidgetModelBuilder.Kind.TWO_WEEKS -> views.setViewVisibility(R.id.two_weeks_content, content)
            }
        }

        private fun visible(on: Boolean): Int = if (on) View.VISIBLE else View.GONE

        fun stale(content: WidgetContent.Stale, homeWidget: Boolean = false) {
            views.setTextViewText(
                R.id.stale_title,
                content.title ?: context.getString(R.string.widget_empty_title),
            )
            views.setTextViewText(
                R.id.stale_body,
                content.body ?: context.getString(R.string.widget_empty_body),
            )
            views.setContentDescription(
                R.id.widget_root,
                "${content.title ?: context.getString(R.string.widget_empty_title)}. " +
                    (content.body ?: context.getString(R.string.widget_empty_body)),
            )
            open(R.id.widget_root, WidgetLinks.APP + if (homeWidget) "?homeWidget" else "")
        }

        // ---- Small ----------------------------------------------------------

        fun small(c: WidgetContent.Small) {
            val first = c.shifts.firstOrNull()
            views.setTextViewText(R.id.date, c.dateLabel)
            color(
                R.id.date,
                "setTextColor",
                if (c.isHoliday) R.color.widget_holiday else R.color.widget_text_muted,
            )
            views.setTextViewText(R.id.code, c.big)
            val size = when {
                c.isEmpty -> 22f
                c.big.length <= 2 -> 44f
                c.big.length <= 4 -> 32f
                else -> 24f
            }
            views.setTextViewTextSize(R.id.code, TypedValue.COMPLEX_UNIT_SP, size)
            views.setTextViewText(R.id.detail, c.detail.orEmpty())
            views.setViewVisibility(R.id.detail, if (c.detail == null) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.tomorrow, c.tomorrow)

            if (first != null) {
                paint(R.id.tint, "setColorFilter", first.colors.tint)
                paint(R.id.code, "setTextColor", first.colors.ink)
            } else {
                // A day without shift: just the surface, no bar.
                color(R.id.tint, "setColorFilter", R.color.widget_surface)
                color(R.id.code, "setTextColor", R.color.widget_text_muted)
            }
            // With no shift every segment is hidden (a previous draw may have shown three).
            bars(c.shifts, intArrayOf(R.id.bar0, R.id.bar1, R.id.bar2))
            views.setContentDescription(
                R.id.widget_root,
                c.description?.let { "$it. ${c.tomorrow}" }
                    ?: listOfNotNull(c.dateLabel, c.big, c.detail, c.tomorrow).joinToString(". "),
            )
            open(R.id.widget_root, c.link)
        }

        // ---- Medium ---------------------------------------------------------

        fun medium(c: WidgetContent.Medium) {
            views.removeAllViews(R.id.strip)
            for (cell in c.cells) views.addView(R.id.strip, cell(cell))
            open(R.id.widget_root, c.link)
        }

        private fun cell(c: StripCell): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_strip_cell)
            val p = Painter(context, v)
            return p.fillCell(c)
        }

        private fun fillCell(c: StripCell): RemoteViews {
            views.setTextViewText(R.id.cell_weekday, c.weekdayShort)
            views.setTextViewText(R.id.cell_day, c.dayOfMonth.toString())
            if (c.isHoliday) color(R.id.cell_day, "setTextColor", R.color.widget_holiday)
            if (c.isToday) {
                views.setViewVisibility(R.id.cell_ring, View.VISIBLE)
                color(R.id.cell_ring, "setColorFilter", R.color.widget_today_ring)
                views.setTextViewTextSize(R.id.cell_day, TypedValue.COMPLEX_UNIT_SP, 15f)
            }
            val codes = intArrayOf(R.id.cell_code0, R.id.cell_code1, R.id.cell_code2)
            val bands = c.bands.take(codes.size)
            val codeSize = when (bands.size) {
                0, 1 -> 20f
                2 -> 14f
                else -> 11f
            }
            if (bands.isEmpty()) {
                // Empty day: the surface alone, just the number.
                color(R.id.cell_tint, "setColorFilter", R.color.widget_surface)
                views.setViewVisibility(R.id.cell_bar0, View.GONE)
                views.setViewVisibility(R.id.cell_code0, View.GONE)
            }
            bands.forEachIndexed { i, band ->
                views.setViewVisibility(codes[i], View.VISIBLE)
                views.setTextViewText(codes[i], band.code)
                views.setTextViewTextSize(codes[i], TypedValue.COMPLEX_UNIT_SP, codeSize)
                paint(codes[i], "setTextColor", band.colors.ink)
            }
            if (bands.isNotEmpty()) {
                paint(R.id.cell_tint, "setColorFilter", bands.first().colors.tint)
                bars(bands, intArrayOf(R.id.cell_bar0, R.id.cell_bar1, R.id.cell_bar2))
            }
            views.setContentDescription(
                R.id.cell,
                c.description ?: (listOf(c.date) + bands.map { it.code }).joinToString(" "),
            )
            open(R.id.cell, c.link)
            return views
        }

        // ---- Large (month) --------------------------------------------------

        /**
         * Title, weekday headers and the 6x7 cells. A fixed layout of six rows
         * that gets its cells with `addView`, like the strip of the medium
         * widget: one [RemoteViews] per draw, no adapter or service that has
         * to be notified, so a draw at midnight with the app closed is the
         * same simple operation as any other.
         */
        fun large(c: WidgetContent.Large) {
            views.setTextViewText(R.id.month_title, c.title)
            views.setContentDescription(R.id.month_header, c.title)
            open(R.id.month_header, c.link)
            val headers = intArrayOf(
                R.id.month_h0, R.id.month_h1, R.id.month_h2, R.id.month_h3,
                R.id.month_h4, R.id.month_h5, R.id.month_h6,
            )
            headers.forEachIndexed { i, id -> views.setTextViewText(id, c.weekdayHeaders[i]) }
            val rows = intArrayOf(
                R.id.month_row0, R.id.month_row1, R.id.month_row2,
                R.id.month_row3, R.id.month_row4, R.id.month_row5,
            )
            for (row in rows) views.removeAllViews(row)
            c.cells.forEachIndexed { i, cell ->
                val v = RemoteViews(context.packageName, R.layout.widget_month_cell)
                views.addView(rows[WidgetDayLogic.rowOf(i)], Painter(context, v).fillMonthCell(cell))
            }
            // A tap in the gaps between cells opens the app on today.
            open(R.id.widget_root, WidgetLinks.day(c.date))
        }

        private fun fillMonthCell(c: MonthCell): RemoteViews {
            views.setTextViewText(R.id.mcell_day, c.dayOfMonth.toString())
            val bands = c.shown
            val dayColor = when {
                !c.inMonth -> R.color.widget_text_muted
                c.isHoliday -> R.color.widget_holiday
                else -> R.color.widget_text_secondary
            }
            color(R.id.mcell_day, "setTextColor", dayColor)
            if (c.isToday) {
                views.setViewVisibility(R.id.mcell_ring, View.VISIBLE)
                color(R.id.mcell_ring, "setColorFilter", R.color.widget_today_ring)
            }
            val codes = intArrayOf(R.id.mcell_code0, R.id.mcell_code1)
            val codeSize = if (bands.size > 1) 10f else 14f
            if (bands.isEmpty()) {
                // A day without shift: the surface alone, just the number.
                color(R.id.mcell_tint, "setColorFilter", R.color.widget_surface)
                views.setViewVisibility(R.id.mcell_bars, View.GONE)
            } else {
                paint(R.id.mcell_tint, "setColorFilter", bands.first().colors.tint)
                bars(bands, intArrayOf(R.id.mcell_bar0, R.id.mcell_bar1))
            }
            codes.forEachIndexed { i, id ->
                val band = bands.getOrNull(i)
                if (band == null) {
                    views.setViewVisibility(id, View.GONE)
                } else {
                    views.setViewVisibility(id, View.VISIBLE)
                    views.setTextViewText(id, band.code)
                    views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, codeSize)
                    paint(id, "setTextColor", band.colors.ink)
                }
            }
            val description = buildList {
                add(c.dayOfMonth.toString())
                addAll(c.bands.map { it.code })
                if (c.isToday) add(context.getString(R.string.widget_today))
            }
            views.setContentDescription(R.id.mcell, c.description ?: description.joinToString(" "))
            open(R.id.mcell, c.link)
            return views
        }

        // ---- Helpers --------------------------------------------------------

        fun agenda(c: WidgetContent.Agenda, size: WidgetRenderPlan.Size) {
            views.removeAllViews(R.id.agenda_content)
            val noShift = c.noShift ?: context.getString(R.string.widget_no_shift)
            for (day in c.days.take(WidgetRenderPlan.agendaRows(size, c.days))) {
                val row = RemoteViews(context.packageName, R.layout.widget_agenda_row)
                val p = Painter(context, row)
                row.setTextViewText(R.id.agenda_date, day.dateLabel)
                row.setTextViewTextSize(R.id.agenda_date, TypedValue.COMPLEX_UNIT_SP,
                    fittedSize(day.dateLabel, 12f, 72f, size.fontScale))
                p.color(R.id.agenda_date, "setTextColor", if (day.isHoliday) R.color.widget_holiday else R.color.widget_text_secondary)
                row.setViewVisibility(R.id.agenda_note, visible(day.hasNote))
                row.removeAllViews(R.id.agenda_shifts)
                if (day.shifts.isEmpty()) {
                    val shift = RemoteViews(context.packageName, R.layout.widget_agenda_shift)
                    shift.setViewVisibility(R.id.agenda_chip, View.GONE)
                    shift.setTextViewText(R.id.agenda_shift_text, noShift)
                    row.addView(R.id.agenda_shifts, shift)
                }
                for (slot in WidgetRenderPlan.agendaSlots(day.shifts, size)) {
                    val s = slot.shift
                    val shift = RemoteViews(context.packageName, R.layout.widget_agenda_shift)
                    val sp = Painter(context, shift)
                    shift.setTextViewText(R.id.agenda_shift_code, slot.code)
                    val detail = s.timeLabel ?: s.name.takeIf { it != s.code }.orEmpty()
                    shift.setTextViewText(R.id.agenda_shift_text, detail)
                    val codeWidth = (measuredWidth(slot.code, 13f, size.fontScale) + 12).coerceAtLeast(32f)
                    val textWidth = (size.width - 16 - 72 - codeWidth - 8).coerceAtLeast(1f)
                    // Use the full preformatted time, shrinking only when needed;
                    // split shifts must never end in an ellipsis or half a range.
                    val detailSize = fittedSize(detail, 13f, textWidth, size.fontScale)
                    shift.setTextViewTextSize(R.id.agenda_shift_text, TypedValue.COMPLEX_UNIT_SP, detailSize)
                    sp.paint(R.id.agenda_chip_tint, "setColorFilter", s.colors.disc)
                    sp.paint(R.id.agenda_shift_code, "setTextColor", s.colors.ink)
                    sp.paint(R.id.agenda_shift_bar, "setColorFilter", s.colors.bar)
                    row.addView(R.id.agenda_shifts, shift)
                }
                row.setContentDescription(R.id.agenda_row, displayDescription(day, noShift))
                p.open(R.id.agenda_row, day.link)
                views.addView(R.id.agenda_content, row)
            }
            open(R.id.widget_root, WidgetLinks.day(c.date) + "?homeWidget")
        }

        fun twoWeeks(c: WidgetContent.TwoWeeks, size: WidgetRenderPlan.Size) {
            val rows = intArrayOf(R.id.two_weeks_row0, R.id.two_weeks_row1)
            rows.forEach { views.removeAllViews(it) }
            c.days.forEachIndexed { i, day ->
                val cell = RemoteViews(context.packageName, R.layout.widget_two_weeks_cell)
                val p = Painter(context, cell)
                val cellWidth = (size.width - 16) / 7f - 4
                val dateLabel = "${day.weekdayShort} ${day.dayOfMonth}"
                cell.setTextViewText(R.id.tw_date, dateLabel)
                cell.setTextViewTextSize(R.id.tw_date, TypedValue.COMPLEX_UNIT_SP,
                    fittedSize(dateLabel, 10f, (cellWidth - 4).coerceAtLeast(1f), size.fontScale))
                p.color(R.id.tw_date, "setTextColor", if (day.isHoliday) R.color.widget_holiday else R.color.widget_text_secondary)
                cell.setViewVisibility(R.id.tw_ring, visible(day.date == c.date))
                p.color(R.id.tw_ring, "setColorFilter", R.color.widget_today_ring)
                cell.setViewVisibility(R.id.tw_note, visible(day.hasNote))
                cell.removeAllViews(R.id.tw_shifts)
                for (slot in WidgetRenderPlan.twoWeeksSlots(day.shifts, size)) {
                    val s = slot.shift
                    val shift = RemoteViews(context.packageName, R.layout.widget_two_weeks_shift)
                    val sp = Painter(context, shift)
                    shift.setTextViewText(R.id.tw_code, slot.code)
                    shift.setTextViewTextSize(R.id.tw_code, TypedValue.COMPLEX_UNIT_SP,
                        fittedSize(slot.code, 13f, (cellWidth - 4).coerceAtLeast(1f), size.fontScale))
                    sp.paint(R.id.tw_code, "setTextColor", s.colors.ink)
                    sp.paint(R.id.tw_shift_tint, "setColorFilter", s.colors.tint)
                    sp.paint(R.id.tw_bar, "setColorFilter", s.colors.bar)
                    val time = s.compactTime
                    val measure = Paint().apply { textSize = 10f * size.fontScale }
                    val fits = time != null && WidgetRenderPlan.timeFits(measure.measureText(time), cellWidth, size, day.shifts.size)
                    shift.setTextViewText(R.id.tw_time, time.orEmpty())
                    shift.setViewVisibility(R.id.tw_time, visible(fits))
                    cell.addView(R.id.tw_shifts, shift)
                }
                cell.setContentDescription(R.id.tw_cell, displayDescription(day, c.noShift ?: context.getString(R.string.widget_no_shift)))
                p.open(R.id.tw_cell, day.link)
                views.addView(rows[i / 7], cell)
            }
            open(R.id.widget_root, WidgetLinks.day(c.date) + "?homeWidget")
        }

        private fun displayDescription(day: DisplayDay, noShift: String): String =
            day.description ?: buildList {
            add(day.dateLabel)
            if (day.shifts.isEmpty()) add(noShift)
            for (s in day.shifts) add(listOfNotNull(s.code, s.name, s.timeLabel).distinct().joinToString(" "))
            if (day.hasNote) add(context.getString(R.string.widget_has_note))
        }.joinToString(". ")

        private fun measuredWidth(text: String, sp: Float, scale: Float): Float =
            Paint().apply { textSize = sp * scale; isFakeBoldText = true }.measureText(text)

        private fun fittedSize(text: String, sp: Float, width: Float, scale: Float): Float {
            val measured = measuredWidth(text, sp, scale)
            return if (measured <= width || measured == 0f) sp else sp * width / measured
        }

        /** One bar segment per shift (up to the number of views), in order. */
        private fun bars(bands: List<Band>, ids: IntArray) {
            val shown = WidgetRenderPlan.barVisibility(bands.size, ids.size)
            ids.forEachIndexed { i, id ->
                views.setViewVisibility(id, visible(shown[i]))
                bands.getOrNull(i)?.let { paint(id, "setColorFilter", it.colors.bar) }
            }
        }

        /** Sets [method] (an int setter) to the colour that fits the mode. */
        private fun paint(id: Int, method: String, pair: ColorPair) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher picks light or dark when it shows the widget,
                // so a theme change needs no redraw.
                views.setColorInt(id, method, pair.light, pair.dark)
            } else {
                views.setInt(id, method, if (night) pair.dark else pair.light)
            }
        }

        /** Same, with a colour resource (light/dark come from `values-night`). */
        private fun color(id: Int, method: String, res: Int) = paint(id, method, resourcePair(res))

        /** The light and the dark value of colour resource [res]. */
        private fun resourcePair(res: Int): ColorPair {
            fun at(mode: Int): Int {
                val config = Configuration(context.resources.configuration)
                config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or mode
                return context.createConfigurationContext(config).getColor(res)
            }
            return ColorPair(at(Configuration.UI_MODE_NIGHT_NO), at(Configuration.UI_MODE_NIGHT_YES))
        }

        /** A tap on [id] opens the app with [link] (`cuadrante://widget/day/<date>`). */
        private fun open(id: Int, link: String) {
            val intent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(link),
            )
            views.setOnClickPendingIntent(id, intent)
        }
    }
}
