package es.cuadrante.app.widget

import es.cuadrante.app.widget.WidgetDayLogic.Selection
import es.cuadrante.app.widget.WidgetDayLogic.StaleReason
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

class WidgetDayLogicTest {
    private val madrid = ZoneId.of("Europe/Madrid")
    private val canary = ZoneId.of("Atlantic/Canary")

    /** Sixty consecutive dates from 2026-10-19, like the snapshot. */
    private val dates = (0 until 60).map { LocalDate.of(2026, 10, 19).plusDays(it.toLong()).toString() }

    private val margin = 2_000L

    private fun millis(zone: ZoneId, y: Int, mo: Int, d: Int, h: Int = 0, mi: Int = 0, s: Int = 0): Long =
        ZonedDateTime.of(LocalDateTime.of(y, mo, d, h, mi, s), zone).toInstant().toEpochMilli()

    private fun pick(now: Long, zone: ZoneId = madrid): Selection =
        WidgetDayLogic.select(dates, WidgetDayLogic.today(now, zone))

    // ---- The day is the device's current date ---------------------------------

    @Test
    fun theLastSecondOfADayIsStillThatDay() {
        assertEquals(Selection.Day(0), pick(millis(madrid, 2026, 10, 19, 23, 59, 59)))
        assertEquals(Selection.Day(0), pick(millis(madrid, 2026, 10, 19, 0, 0, 0)))
    }

    @Test
    fun midnightMovesToTheNextDay() {
        assertEquals(Selection.Day(1), pick(millis(madrid, 2026, 10, 20, 0, 0, 0)))
        assertEquals(Selection.Day(1), pick(millis(madrid, 2026, 10, 20, 0, 1, 0)))
    }

    @Test
    fun everyHourOfTheSixtyDaysPicksTheDayOfTheClockNeverAnotherOne() {
        var now = millis(madrid, 2026, 10, 19, 0, 0, 0)
        val end = millis(madrid, 2026, 12, 25, 0, 0, 0)
        while (now < end) {
            val local = WidgetDayLogic.today(now, madrid)
            when (val s = pick(now)) {
                is Selection.Day -> assertEquals("at $now", local.toString(), dates[s.index])
                is Selection.Stale -> assertTrue("at $now: $local", local > LocalDate.of(2026, 12, 17))
            }
            now += Duration.ofMinutes(30).toMillis()
        }
    }

    @Test
    fun theSixtiethDayIsShownAndTheNextOneIsStale() {
        assertEquals(Selection.Day(59), pick(millis(madrid, 2026, 12, 17, 23, 59, 59)))
        assertEquals(Selection.Stale(StaleReason.AFTER_LAST), pick(millis(madrid, 2026, 12, 18, 0, 0, 0)))
        assertEquals(Selection.Stale(StaleReason.AFTER_LAST), pick(millis(madrid, 2027, 3, 1, 12)))
    }

    @Test
    fun aClockBeforeTheFirstDayIsStaleNotAWrongDay() {
        assertEquals(Selection.Stale(StaleReason.BEFORE_FIRST), pick(millis(madrid, 2026, 10, 18, 23, 59, 59)))
        assertEquals(Selection.Stale(StaleReason.BEFORE_FIRST), pick(millis(madrid, 2020, 1, 1)))
    }

    @Test
    fun aDamagedListIsStaleAndEmptyMeansNoSnapshot() {
        val gap = dates.filterIndexed { i, _ -> i != 5 } // 2026-10-24 missing
        assertEquals(
            Selection.Stale(StaleReason.NOT_FOUND),
            WidgetDayLogic.select(gap, LocalDate.of(2026, 10, 24)),
        )
        assertEquals(
            Selection.Stale(StaleReason.NO_SNAPSHOT),
            WidgetDayLogic.select(emptyList(), LocalDate.of(2026, 10, 24)),
        )
    }

    // ---- Daylight saving ------------------------------------------------------

    @Test
    fun theDayOfTheAutumnClockChangeLastsTwentyFiveHoursAndNothingIsSkipped() {
        // 2026-10-25: 03:00 CEST goes back to 02:00 CET.
        val start = millis(madrid, 2026, 10, 25, 0, 0, 0)
        val next = millis(madrid, 2026, 10, 26, 0, 0, 0)
        assertEquals(Duration.ofHours(25).toMillis(), next - start)
        val index = dates.indexOf("2026-10-25")
        // The repeated 02:xx hour, both times, is still the 25th.
        assertEquals(Selection.Day(index), pick(start + Duration.ofHours(2).toMillis() + 1_800_000))
        assertEquals(Selection.Day(index), pick(start + Duration.ofHours(3).toMillis() + 1_800_000))
        assertEquals(Selection.Day(index), pick(next - 1))
        assertEquals(Selection.Day(index + 1), pick(next))
    }

    @Test
    fun theDayOfTheSpringClockChangeLastsTwentyThreeHours() {
        // 2027-03-28: 02:00 CET jumps to 03:00 CEST.
        val start = millis(madrid, 2027, 3, 28, 0, 0, 0)
        val next = millis(madrid, 2027, 3, 29, 0, 0, 0)
        assertEquals(Duration.ofHours(23).toMillis(), next - start)
        val springDates = (0 until 60).map { LocalDate.of(2027, 3, 1).plusDays(it.toLong()).toString() }
        val index = springDates.indexOf("2027-03-28")
        assertEquals(Selection.Day(index), WidgetDayLogic.select(springDates, WidgetDayLogic.today(next - 1, madrid)))
        assertEquals(Selection.Day(index + 1), WidgetDayLogic.select(springDates, WidgetDayLogic.today(next, madrid)))
    }

    @Test
    fun theNextRefreshIsTheNextLocalMidnightPlusMargin() {
        val noon = millis(madrid, 2026, 10, 19, 12)
        assertEquals(millis(madrid, 2026, 10, 20, 0, 0) + margin, WidgetDayLogic.nextRefreshMillis(noon, madrid))
        // One second before midnight: still tonight's midnight.
        assertEquals(
            millis(madrid, 2026, 10, 20, 0, 0) + margin,
            WidgetDayLogic.nextRefreshMillis(millis(madrid, 2026, 10, 19, 23, 59, 59), madrid),
        )
        // Exactly at midnight (and the minute after): the following midnight, never "now".
        assertEquals(
            millis(madrid, 2026, 10, 21, 0, 0) + margin,
            WidgetDayLogic.nextRefreshMillis(millis(madrid, 2026, 10, 20, 0, 0, 0), madrid),
        )
        assertEquals(
            millis(madrid, 2026, 10, 21, 0, 0) + margin,
            WidgetDayLogic.nextRefreshMillis(millis(madrid, 2026, 10, 20, 0, 1, 0), madrid),
        )
    }

    @Test
    fun theNextRefreshIsAlwaysAfterNowAndOnTheNextDate() {
        var now = millis(madrid, 2026, 10, 20, 0, 0, 0)
        val end = millis(madrid, 2026, 10, 30, 0, 0, 0) // crosses the 25 h day
        while (now < end) {
            val at = WidgetDayLogic.nextRefreshMillis(now, madrid)
            assertTrue(at > now)
            assertEquals(
                WidgetDayLogic.today(now, madrid).plusDays(1),
                WidgetDayLogic.today(at, madrid),
            )
            // And never later than a day and a bit away.
            assertTrue(at - now <= Duration.ofHours(25).toMillis() + margin)
            now += Duration.ofMinutes(7).toMillis()
        }
    }

    @Test
    fun theRefreshAcrossTheClockChangesLandsAfterTheirMidnight() {
        // The 25-hour day: from noon on the 25th the next midnight is 12 h + 1 h away.
        val noon = millis(madrid, 2026, 10, 25, 12)
        val at = WidgetDayLogic.nextRefreshMillis(noon, madrid)
        assertEquals(millis(madrid, 2026, 10, 26, 0, 0) + margin, at)
        assertEquals(Duration.ofHours(12).toMillis() + margin, at - noon)
        // The 23-hour day.
        val noon2 = millis(madrid, 2027, 3, 28, 12)
        assertEquals(millis(madrid, 2027, 3, 29, 0, 0) + margin, WidgetDayLogic.nextRefreshMillis(noon2, madrid))
    }

    @Test
    fun aZoneWhoseMidnightDoesNotExistStartsTheDayAtOne() {
        // Brazil began summer time at 00:00 -> 01:00 on 2018-11-04.
        val saoPaulo = ZoneId.of("America/Sao_Paulo")
        val now = millis(saoPaulo, 2018, 11, 3, 12)
        val at = WidgetDayLogic.nextRefreshMillis(now, saoPaulo)
        val local = ZonedDateTime.ofInstant(java.time.Instant.ofEpochMilli(at), saoPaulo)
        assertEquals(LocalDate.of(2018, 11, 4), local.toLocalDate())
        assertEquals(1, local.hour)
        assertEquals(0, local.minute)
    }

    // ---- Time-zone changes ----------------------------------------------------

    @Test
    fun theSameInstantIsAnotherDayInAnotherZone() {
        // 22:30 UTC on the 19th: 00:30 on the 20th in Madrid (CEST), 23:30 on the 19th in the Canaries.
        val instant = java.time.Instant.parse("2026-10-19T22:30:00Z").toEpochMilli()
        assertEquals(Selection.Day(1), pick(instant, madrid))
        assertEquals(Selection.Day(0), pick(instant, canary))
        // And so does the next refresh: each zone's own midnight.
        val madridAt = WidgetDayLogic.nextRefreshMillis(instant, madrid)
        val canaryAt = WidgetDayLogic.nextRefreshMillis(instant, canary)
        assertEquals(millis(madrid, 2026, 10, 21, 0, 0) + margin, madridAt)
        assertEquals(millis(canary, 2026, 10, 20, 0, 0) + margin, canaryAt)
    }

    @Test
    fun travellingWestAnHourAfterMidnightGoesBackToYesterdayAndForwardAgain() {
        val instant = millis(madrid, 2026, 10, 20, 0, 30)
        assertEquals(Selection.Day(1), pick(instant, madrid))
        assertEquals(Selection.Day(0), pick(instant, canary)) // 23:30 on the 19th
        assertEquals(Selection.Day(1), pick(instant, madrid)) // and back
    }

    // ---- The month grid of the large widget ---------------------------------------

    private val octoberCells = (0 until 42).map { LocalDate.of(2026, 9, 28).plusDays(it.toLong()).toString() }

    @Test
    fun theMonthKeyIsYearAndMonth() {
        assertEquals("2026-10", WidgetDayLogic.monthKey(LocalDate.of(2026, 10, 31)))
        assertEquals("2027-01", WidgetDayLogic.monthKey(LocalDate.of(2027, 1, 1)))
    }

    @Test
    fun cellsAreSixRowsOfSevenColumns() {
        assertEquals(42, WidgetDayLogic.MONTH_CELLS)
        assertEquals(0 to 0, WidgetDayLogic.rowOf(0) to WidgetDayLogic.columnOf(0))
        assertEquals(0 to 6, WidgetDayLogic.rowOf(6) to WidgetDayLogic.columnOf(6))
        assertEquals(1 to 0, WidgetDayLogic.rowOf(7) to WidgetDayLogic.columnOf(7))
        assertEquals(3 to 0, WidgetDayLogic.rowOf(21) to WidgetDayLogic.columnOf(21))
        assertEquals(5 to 6, WidgetDayLogic.rowOf(41) to WidgetDayLogic.columnOf(41))
        // Every cell has exactly one row of 0..5 and one column of 0..6.
        for (i in 0 until 42) {
            assertTrue(WidgetDayLogic.rowOf(i) in 0..5)
            assertTrue(WidgetDayLogic.columnOf(i) in 0..6)
            assertEquals(i, WidgetDayLogic.rowOf(i) * 7 + WidgetDayLogic.columnOf(i))
        }
    }

    @Test
    fun theMonthIsTheOneOfTodayAndOnTheFirstItIsTheNewOne() {
        val keys = listOf("2026-10", "2026-11", "2026-12")
        assertEquals(0, WidgetDayLogic.monthIndex(keys, 0, LocalDate.of(2026, 10, 31)))
        assertEquals(1, WidgetDayLogic.monthIndex(keys, 1, LocalDate.of(2026, 11, 1)))
        assertEquals(2, WidgetDayLogic.monthIndex(keys, 2, LocalDate.of(2026, 12, 1)))
    }

    @Test
    fun aWrongMonthPointerIsCorrectedByTheKeyAndAMissingMonthIsNull() {
        val keys = listOf("2026-10", "2026-11")
        assertEquals(1, WidgetDayLogic.monthIndex(keys, 0, LocalDate.of(2026, 11, 3)))
        assertEquals(1, WidgetDayLogic.monthIndex(keys, 99, LocalDate.of(2026, 11, 3)))
        assertEquals(1, WidgetDayLogic.monthIndex(keys, -1, LocalDate.of(2026, 11, 3)))
        assertNull(WidgetDayLogic.monthIndex(keys, 0, LocalDate.of(2026, 12, 1)))
        assertNull(WidgetDayLogic.monthIndex(emptyList(), 0, LocalDate.of(2026, 10, 19)))
    }

    @Test
    fun todayCellIsThePointerWhenItIsRightAndFoundByDateWhenNot() {
        val today = LocalDate.of(2026, 10, 19)
        assertEquals(21, WidgetDayLogic.todayCell(octoberCells, 21, today))
        assertEquals(21, WidgetDayLogic.todayCell(octoberCells, 3, today))
        assertEquals(21, WidgetDayLogic.todayCell(octoberCells, 500, today))
        // A day of the grid that belongs to the next month is a cell too.
        assertEquals(41, WidgetDayLogic.todayCell(octoberCells, 41, LocalDate.of(2026, 11, 8)))
    }

    @Test
    fun noTodayCellWhenTheGridDoesNotHaveTodayOrIsNotSixBySeven() {
        assertNull(WidgetDayLogic.todayCell(octoberCells, 0, LocalDate.of(2026, 12, 1)))
        assertNull(WidgetDayLogic.todayCell(octoberCells.take(35), 21, LocalDate.of(2026, 10, 19)))
        assertNull(WidgetDayLogic.todayCell(emptyList(), 0, LocalDate.of(2026, 10, 19)))
    }

    @Test
    fun theMidnightBeforeTheFirstOfAMonthRefreshesJustAfterIt() {
        val at = WidgetDayLogic.nextRefreshMillis(millis(madrid, 2026, 10, 31, 23, 0), madrid)
        assertEquals(millis(madrid, 2026, 11, 1, 0, 0, 2), at)
        // Year change too.
        val ny = WidgetDayLogic.nextRefreshMillis(millis(madrid, 2026, 12, 31, 12, 0), madrid)
        assertEquals(millis(madrid, 2027, 1, 1, 0, 0, 2), ny)
        // The refresh draws the first: its date is the new month's.
        assertEquals(
            "2026-11",
            WidgetDayLogic.monthKey(WidgetDayLogic.today(at, madrid)),
        )
    }
}
