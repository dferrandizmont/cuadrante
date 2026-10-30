package es.cuadrante.app.widget

import es.cuadrante.app.widget.WidgetModelBuilder.Kind
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * The month grid of the large widget, read from snapshots the Dart builder
 * wrote:
 *
 *  - `widget_snapshot.json`: 10 days from Monday 2026-10-19, week starting on
 *    Monday (the October grid goes from 2026-09-28 to 2026-11-08).
 *  - `widget_snapshot_month_change.json`: 5 days from Friday 2026-10-30 with
 *    the week starting on Sunday. The October grid starts on Sunday 09-27;
 *    November begins on Sunday the 1st, which is its first cell (0).
 *    31 Oct N, 1 Nov T (holiday), 2 Nov M+T (note), 3 Nov L.
 */
class WidgetMonthTest {
    private val madrid = ZoneId.of("Europe/Madrid")
    private val october: String = resource("/widget_snapshot.json")
    private val change: String = resource("/widget_snapshot_month_change.json")

    private fun resource(name: String) = javaClass.getResource(name)!!.readText()

    private fun at(month: Int, d: Int, h: Int = 12, mi: Int = 0, s: Int = 0): Long =
        ZonedDateTime.of(LocalDateTime.of(2026, month, d, h, mi, s), madrid).toInstant().toEpochMilli()

    private fun large(json: String, now: Long): WidgetContent.Large =
        WidgetModelBuilder.build(json, Kind.LARGE, now, madrid) as WidgetContent.Large

    @Test
    fun theGridIsTheMonthOfTodayWithSixRowsOfSevenCells() {
        val c = large(october, at(10, 19))
        assertEquals("2026-10-19", c.date)
        assertEquals("2026-10", c.monthKey)
        assertEquals("Octubre 2026", c.title)
        assertEquals(listOf("L", "M", "X", "J", "V", "S", "D"), c.weekdayHeaders)
        assertEquals(42, c.cells.size)
        assertEquals("2026-09-28", c.cells.first().date)
        assertEquals("2026-11-08", c.cells.last().date)
        assertEquals(31, c.cells.count { it.inMonth })
        assertEquals(WidgetLinks.month("2026-10"), c.link)
        assertEquals("cuadrante://widget/month/2026-10", c.link)
    }

    @Test
    fun exactlyOneCellIsTodayAndItsTheRightDay() {
        val c = large(october, at(10, 19))
        assertEquals(1, c.cells.count { it.isToday })
        val today = c.cells.single { it.isToday }
        assertEquals("2026-10-19", today.date)
        assertEquals(21, c.cells.indexOf(today)) // row 3, column 0: a Monday
        assertEquals(listOf("N"), today.bands.map { it.code })
        // Tomorrow's draw moves the ring by itself.
        val next = large(october, at(10, 20, 0, 0, 5))
        assertEquals("2026-10-20", next.cells.single { it.isToday }.date)
        assertEquals(22, next.cells.indexOfFirst { it.isToday })
    }

    @Test
    fun cellsKeepDayNumberCodesNotesAndHolidays() {
        val c = large(october, at(10, 19))
        val byDate = c.cells.associateBy { it.date }
        assertEquals(20, byDate["2026-10-20"]!!.dayOfMonth)
        assertTrue(byDate["2026-10-20"]!!.isHoliday)
        assertEquals(listOf("M", "T"), byDate["2026-10-21"]!!.bands.map { it.code })
        assertTrue(byDate["2026-10-21"]!!.hasNote)
        assertTrue(byDate["2026-10-22"]!!.bands.isEmpty())
        assertEquals(WidgetLinks.day("2026-10-21"), byDate["2026-10-21"]!!.link)
    }

    @Test
    fun aCellShowsAtMostTwoShifts() {
        val band = Band("N", ShiftColors(pair(1), pair(2), pair(3), pair(4)))
        val cell = MonthCell(
            "2026-10-19", 19, inMonth = true, isToday = false, isHoliday = false,
            hasNote = false, bands = listOf(band, band.copy(code = "T"), band.copy(code = "M")),
        )
        assertEquals(2, WidgetDayLogic.MAX_CELL_BANDS)
        assertEquals(listOf("N", "T"), cell.shown.map { it.code })
        assertEquals(3, cell.bands.size)
    }

    private fun pair(v: Int) = ColorPair(v, v)

    // ---- Month change ---------------------------------------------------------------

    @Test
    fun onTheLastDayOfOctoberItStillShowsOctober() {
        val c = large(change, at(10, 31, 23, 59, 59))
        assertEquals("2026-10", c.monthKey)
        assertEquals("2026-10-31", c.cells.single { it.isToday }.date)
        assertEquals(34, c.cells.indexOfFirst { it.isToday })
    }

    @Test
    fun onTheFirstItShowsTheNewMonthFromTheSnapshotWithoutTheApp() {
        // Drawn on 31 Oct; nothing is republished; the draw at 00:00:02 reads the
        // clock and finds November in `months`.
        val c = large(change, at(11, 1, 0, 0, 2))
        assertEquals("2026-11", c.monthKey)
        assertEquals("Noviembre 2026", c.title)
        assertEquals(WidgetLinks.month("2026-11"), c.link)
        assertEquals(42, c.cells.size)
        // The week starts on Sunday: the 1st is the first cell, in the month and today.
        assertEquals("2026-11-01", c.cells.first().date)
        assertTrue(c.cells.first().inMonth)
        assertTrue(c.cells.first().isToday)
        assertEquals(1, c.cells.count { it.isToday })
        assertTrue(c.cells.first().isHoliday)
        assertEquals(30, c.cells.count { it.inMonth })
        assertFalse(c.cells.last().inMonth)
        assertEquals("2026-12-12", c.cells.last().date)
    }

    @Test
    fun weekdayHeadersFollowTheFirstDayOfTheWeekOfTheSnapshot() {
        assertEquals(
            listOf("D", "L", "M", "X", "J", "V", "S"),
            large(change, at(11, 2)).weekdayHeaders,
        )
        assertEquals(
            "2026-11-02",
            large(change, at(11, 2)).cells.single { it.isToday }.date,
        )
        assertEquals(1, large(change, at(11, 2)).cells.indexOfFirst { it.isToday })
    }

    @Test
    fun aDoubleShiftDayHasTwoCodes() {
        val c = large(change, at(11, 2))
        val cell = c.cells.single { it.isToday }
        assertEquals(listOf("M", "T"), cell.shown.map { it.code })
        assertTrue(cell.hasNote)
        assertNotEquals(cell.shown[0].colors.bar, cell.shown[1].colors.bar)
    }

    @Test
    fun daysOfOtherMonthsUseTheDimmedColoursOfTheirStyle() {
        val c = large(change, at(10, 31))
        val styles = JSONObject(change).getJSONArray("styles")
        val outside = c.cells.first { !it.inMonth && it.bands.isNotEmpty() }
        val inside = c.cells.first { it.inMonth && it.bands.any { b -> b.code == outside.bands.first().code } }
        val code = outside.bands.first().code
        val outColors = outside.bands.first().colors
        val inColors = inside.bands.first { it.code == code }.colors
        assertNotEquals("dimmed ink is not the shift ink", inColors.ink, outColors.ink)
        assertNotEquals(inColors.bar, outColors.bar)
        assertNotEquals(inColors.tint, outColors.tint)
        // Exactly the dim* fields of one of the styles.
        val dimInks = (0 until styles.length()).map { styles.getJSONObject(it).getLong("dimInkLight").toInt() }
        assertTrue(dimInks.contains(outColors.ink.light))
        val dimTints = (0 until styles.length()).map { styles.getJSONObject(it).getLong("dimTintDark").toInt() }
        assertTrue(dimTints.contains(outColors.tint.dark))
    }

    @Test
    fun inMonthCellsUseTheNormalColours() {
        val c = large(change, at(10, 31))
        val styles = JSONObject(change).getJSONArray("styles")
        val today = c.cells.single { it.isToday }
        val colors = today.bands.single().colors
        val inks = (0 until styles.length()).map { styles.getJSONObject(it).getLong("inkLight").toInt() }
        assertTrue(inks.contains(colors.ink.light))
    }

    // ---- Honest message -------------------------------------------------------------

    @Test
    fun whenTheTimelineIsExhaustedItIsTheOpenTheAppMessage() {
        val after = WidgetModelBuilder.build(change, Kind.LARGE, at(11, 4, 0, 0, 1), madrid)
        after as WidgetContent.Stale
        assertEquals(WidgetDayLogic.StaleReason.AFTER_LAST, after.reason)
        assertEquals("Abre Turnly para seguir al día", after.body)
        // The last published day is still a month.
        assertTrue(WidgetModelBuilder.build(change, Kind.LARGE, at(11, 3, 23, 59, 59), madrid) is WidgetContent.Large)
        val before = WidgetModelBuilder.build(change, Kind.LARGE, at(10, 29, 23, 59, 59), madrid)
        assertEquals(WidgetDayLogic.StaleReason.BEFORE_FIRST, (before as WidgetContent.Stale).reason)
    }

    @Test
    fun wrongPointersAreCorrectedByDateNotShownAsAWrongMonth() {
        // The pointers of 1 Nov say October's grid, cell 5.
        val damaged = change.replaceFirst(""""large":{"month":1,"todayCell":0}""", """"large":{"month":0,"todayCell":5}""")
        assertNotEquals(change, damaged)
        val c = large(damaged, at(11, 1, 9))
        assertEquals("2026-11", c.monthKey)
        assertEquals("2026-11-01", c.cells.single { it.isToday }.date)
    }

    @Test
    fun aSnapshotWithoutTheMonthOfTodayIsTheMessageNeverAWrongMonth() {
        val noNovember = change.replace(""""key":"2026-11"""", """"key":"2026-12"""")
        assertNotEquals(change, noNovember)
        val c = WidgetModelBuilder.build(noNovember, Kind.LARGE, at(11, 1, 9), madrid)
        assertEquals(WidgetDayLogic.StaleReason.NOT_FOUND, (c as WidgetContent.Stale).reason)
    }

    @Test
    fun aGridThatIsNotSixBySevenIsTheMessage() {
        val root = JSONObject(change)
        val cells = root.getJSONArray("months").getJSONObject(1).getJSONArray("cells")
        cells.remove(41)
        val c = WidgetModelBuilder.build(root.toString(), Kind.LARGE, at(11, 1, 9), madrid)
        assertEquals(WidgetDayLogic.StaleReason.NOT_FOUND, (c as WidgetContent.Stale).reason)
    }

    @Test
    fun missingWeekdayHeadersOrMonthsAreTheMessage() {
        for (field in listOf("weekdayHeaders", "months", "styles")) {
            val root = JSONObject(change)
            root.remove(field)
            val c = WidgetModelBuilder.build(root.toString(), Kind.LARGE, at(11, 1, 9), madrid)
            assertTrue(field, c is WidgetContent.Stale)
        }
    }

    @Test
    fun theOtherWidgetsStillReadTheSameSnapshots() {
        // The month data must not disturb the small and medium readers.
        val small = WidgetModelBuilder.build(change, Kind.SMALL, at(11, 1, 9), madrid) as WidgetContent.Small
        assertEquals("T", small.big)
        val medium = WidgetModelBuilder.build(change, Kind.MEDIUM, at(11, 1, 9), madrid) as WidgetContent.Medium
        assertEquals(7, medium.cells.size)
    }
}
