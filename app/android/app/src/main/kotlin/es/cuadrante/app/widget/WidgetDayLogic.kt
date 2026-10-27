package es.cuadrante.app.widget

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * The day logic of the home-screen widgets, free of Android classes so JVM
 * unit tests can cover it (`WidgetDayLogicTest`).
 *
 * The rule that keeps the widgets from ever showing yesterday: every time
 * they are drawn, the day is picked from the snapshot by the device's
 * CURRENT local date ([today]) — never "the first day" and never a day
 * remembered from an earlier draw. When that date is not in the snapshot the
 * widget shows its honest "open the app" message ([Selection.Stale]).
 */
object WidgetDayLogic {

    /** Why the widget shows the message instead of a day. */
    enum class StaleReason {
        /** Nothing published yet, or what is stored cannot be read. */
        NO_SNAPSHOT,

        /** Today is before the first published day (the clock went back). */
        BEFORE_FIRST,

        /** The 60 published days are over. */
        AFTER_LAST,

        /** Inside the range but not in the list (a damaged snapshot). */
        NOT_FOUND,
    }

    sealed interface Selection {
        /** The snapshot has [index] as the entry of today. */
        data class Day(val index: Int) : Selection

        data class Stale(val reason: StaleReason) : Selection
    }

    /** The civil date at [nowMillis] in [zone]: the device's local date. */
    fun today(nowMillis: Long, zone: ZoneId): LocalDate =
        Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()

    /**
     * Picks today's entry from [dates] (`yyyy-MM-dd`, ascending, one per
     * snapshot day). Dates are compared as text: ISO dates sort the same way
     * as the days they name.
     */
    fun select(dates: List<String>, today: LocalDate): Selection {
        if (dates.isEmpty()) return Selection.Stale(StaleReason.NO_SNAPSHOT)
        val iso = today.toString()
        val index = dates.indexOf(iso)
        if (index >= 0) return Selection.Day(index)
        return when {
            iso < dates.first() -> Selection.Stale(StaleReason.BEFORE_FIRST)
            iso > dates.last() -> Selection.Stale(StaleReason.AFTER_LAST)
            else -> Selection.Stale(StaleReason.NOT_FOUND)
        }
    }

    // ---- The month grid of the large widget ------------------------------------

    /** Columns of the month grid (the week). */
    const val MONTH_COLUMNS = 7

    /** Cells of a month grid: 6 rows by 7 columns. */
    const val MONTH_CELLS = 42

    /** Most shifts (codes and bar segments) a month cell shows. */
    const val MAX_CELL_BANDS = 2

    /** `yyyy-MM`, the key of the grid that shows [date]. */
    fun monthKey(date: LocalDate): String = date.toString().substring(0, 7)

    /** Row (0-5) and column (0-6) of grid cell [index]. */
    fun rowOf(index: Int): Int = index / MONTH_COLUMNS

    fun columnOf(index: Int): Int = index % MONTH_COLUMNS

    /**
     * The grid (index in `months`) that shows [today]. The day's own pointer
     * (`Day.large.month`) is used when it names today's month; if it does
     * not (a damaged snapshot) the grid is found by its key. Null when no grid
     * covers today: the widget then shows the "open the app" message instead
     * of a wrong month.
     */
    fun monthIndex(monthKeys: List<String>, pointer: Int, today: LocalDate): Int? {
        val key = monthKey(today)
        if (monthKeys.getOrNull(pointer) == key) return pointer
        return monthKeys.indexOf(key).takeIf { it >= 0 }
    }

    /**
     * The cell of [today] in a grid whose cells are [cellDates] (`yyyy-MM-dd`).
     * The pointer (`Day.large.todayCell`) is used when that cell is today; if it
     * is not, today is searched for by date. Null when the grid has not the
     * right shape or does not contain today.
     */
    fun todayCell(cellDates: List<String>, pointer: Int, today: LocalDate): Int? {
        if (cellDates.size != MONTH_CELLS) return null
        val iso = today.toString()
        if (cellDates.getOrNull(pointer) == iso) return pointer
        return cellDates.indexOf(iso).takeIf { it >= 0 }
    }

    /**
     * When to redraw next: the first instant of the next local day in [zone]
     * plus [marginSeconds]. The start of the day comes from the zone rules,
     * not from adding 24 h, so the 23 h and 25 h days of the clock changes
     * and the zones whose midnight does not exist on a given day (where the
     * day starts at 01:00) are right.
     */
    fun nextRefreshMillis(nowMillis: Long, zone: ZoneId, marginSeconds: Long = 2): Long {
        val tomorrow = today(nowMillis, zone).plusDays(1)
        val start = tomorrow.atStartOfDay(zone).toInstant().toEpochMilli()
        return start + marginSeconds * 1_000L
    }
}
