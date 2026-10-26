package app.cuadrante.cuadrante.widget

/**
 * The visibility decisions of a draw, as plain data so the JVM tests can check
 * them without `RemoteViews`.
 *
 * Why this exists (H-T12-2): when the launcher receives a new `RemoteViews`
 * with the SAME layout id as the one it already shows, it does not inflate a
 * fresh tree, it re-applies the actions on the existing views
 * (`RemoteViews.reapply`). Whatever a previous draw left on a view (the "open
 * the app" message made visible, the content hidden) stays unless the new
 * draw sets it again. A draw that only changed the visibility on the stale
 * path left the message on screen for ever after the data came back. So every
 * draw states the visibility of BOTH the message and the content, whatever
 * state it paints.
 */
object WidgetRenderPlan {
    const val MAX_AGENDA_ROWS = 14

    /** Current launcher bounds in dp, after selecting portrait/landscape options. */
    data class Size(val width: Int = 250, val height: Int = 110, val fontScale: Float = 1f)

    fun monday(today: java.time.LocalDate): java.time.LocalDate =
        today.minusDays((today.dayOfWeek.value - 1).toLong())

    fun agendaDayHeight(size: Size, day: DisplayDay): Int =
        16 + kotlin.math.ceil(28 * size.fontScale.coerceAtLeast(1f) * agendaSlots(day.shifts, size).size.coerceAtLeast(1)).toInt()

    /** A crowded first date still fits completely, with the rest named by +N. */
    fun agendaSlots(shifts: List<DisplayShift>, size: Size): List<ShiftSlot> {
        val shiftHeight = kotlin.math.ceil(28 * size.fontScale.coerceAtLeast(1f)).toInt()
        val count = ((size.height - 32) / shiftHeight).coerceAtLeast(1).coerceAtMost(shifts.size)
        return shifts.take(count).mapIndexed { i, shift ->
            ShiftSlot(shift, if (i == count - 1) shifts.size - count else 0)
        }
    }

    fun agendaRows(size: Size, days: List<DisplayDay>): Int {
        var used = 16
        var count = 0
        for (day in days.take(MAX_AGENDA_ROWS)) {
            used += agendaDayHeight(size, day)
            if (used > size.height && count > 0) break
            count++
            if (used > size.height) break
        }
        return count
    }

    /** Keep a whole compact time range or hide it; never truncate a range. */
    fun timeFits(timeWidthDp: Float, cellWidthDp: Float, size: Size, shiftCount: Int): Boolean =
        size.height >= 140 * size.fontScale.coerceAtLeast(1f) && shiftCount <= 2 &&
            timeWidthDp <= (cellWidthDp - 8).coerceAtLeast(0f)

    data class ShiftSlot(val shift: DisplayShift, val hidden: Int) {
        val code: String get() = shift.code + if (hidden > 0) " +$hidden" else ""
    }

    /** At most two codes, with an explicit overflow count and full spoken content. */
    fun twoWeeksSlots(shifts: List<DisplayShift>, size: Size): List<ShiftSlot> {
        val scale = size.fontScale.coerceAtLeast(1f)
        val available = (size.height - 16) / 2f - 8 - 12 * scale
        val count = (available / (16 * scale + 3)).toInt().coerceIn(1, 2).coerceAtMost(shifts.size)
        return shifts.take(count).mapIndexed { i, shift ->
            ShiftSlot(shift, if (i == count - 1) shifts.size - count else 0)
        }
    }

    /** Whether the "open the app" message and the normal content are shown. */
    data class Root(val showStale: Boolean, val showContent: Boolean)

    fun root(content: WidgetContent): Root {
        val stale = content is WidgetContent.Stale
        return Root(showStale = stale, showContent = !stale)
    }

    /**
     * Visibility of each of the [slots] bar segments of a cell with [bands]
     * shifts: a segment per shift, the rest hidden. With no shift, all hidden
     * (a previous draw may have shown several).
     */
    fun barVisibility(bands: Int, slots: Int): List<Boolean> =
        List(slots) { it < bands }
}
