package es.cuadrante.app.widget

import es.cuadrante.app.widget.WidgetModelBuilder.Kind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Reads the snapshot the Dart builder wrote
 * (`src/test/resources/widget_snapshot.json`, 10 days from Monday 2026-10-19;
 * `widget_android_fixture_test.dart` keeps it equal to the builder's output).
 *
 *  19 Mon  N          22:00-06:00, tomorrow T 14-22
 *  20 Tue  T          holiday "Fiesta de prueba"
 *  21 Wed  M+T        override with two shifts and a note
 *  22 Thu  (empty)    override with no shift
 *  23 Fri  vacation   override
 *  24 Sat  T          rotation again, ... up to the 28th
 */
class WidgetModelBuilderTest {
    private val madrid = ZoneId.of("Europe/Madrid")
    private val canary = ZoneId.of("Atlantic/Canary")
    private val json: String =
        javaClass.getResource("/widget_snapshot.json")!!.readText()

    private fun at(d: Int, h: Int = 12, mi: Int = 0, s: Int = 0, month: Int = 10, zone: ZoneId = madrid): Long =
        ZonedDateTime.of(LocalDateTime.of(2026, month, d, h, mi, s), zone).toInstant().toEpochMilli()

    private fun small(now: Long, zone: ZoneId = madrid) =
        WidgetModelBuilder.build(json, Kind.SMALL, now, zone)

    private fun medium(now: Long, zone: ZoneId = madrid) =
        WidgetModelBuilder.build(json, Kind.MEDIUM, now, zone)

    @Test
    fun completeDescriptionsFollowTodayAtMidnightAndIncludeAllShifts() {
        val first = small(at(19)) as WidgetContent.Small
        val description = requireNotNull(first.description)
        assertTrue(description.startsWith("hoy. "))
        assertTrue(description.contains("2026"))
        assertTrue(description.contains("Noche de 22:00 a 06:00"))
        val strip = medium(at(19)) as WidgetContent.Medium
        assertTrue(strip.cells[1].description!!.contains("festivo: Fiesta de prueba"))
        assertFalse(strip.cells[1].description!!.startsWith("hoy."))
        assertTrue(strip.cells[2].description!!.contains("Mañana de 06:00 a 14:00"))
        assertTrue(strip.cells[2].description!!.contains("Tarde de 14:00 a 22:00"))
        assertTrue(strip.cells[2].description!!.contains("con nota"))
        val next = medium(at(20)) as WidgetContent.Medium
        assertTrue(next.cells.first().description!!.startsWith("hoy."))
        val month = WidgetModelBuilder.build(json, Kind.LARGE, at(20), madrid) as WidgetContent.Large
        assertTrue(month.cells.single { it.date == "2026-10-20" }.description!!.startsWith("hoy."))
        assertFalse(month.cells.single { it.date == "2026-10-19" }.description!!.startsWith("hoy."))
    }

    @Test
    fun oldSnapshotWithoutDescriptionsStillRenders() {
        val old = org.json.JSONObject(json).apply { remove("descriptions") }.toString()
        val content = WidgetModelBuilder.build(old, Kind.SMALL, at(19), madrid) as WidgetContent.Small
        assertNull(content.description)
        assertEquals("N", content.big)
    }

    @Test
    fun smallShowsTodayWithTomorrowBelow() {
        val c = small(at(19)) as WidgetContent.Small
        assertEquals("2026-10-19", c.date)
        assertEquals("lun 19", c.dateLabel)
        assertEquals("N", c.big)
        assertEquals("22:00–06:00", c.detail)
        assertEquals("Mañana: T 14–22", c.tomorrow)
        assertFalse(c.isEmpty)
        assertFalse(c.isHoliday)
        assertEquals(WidgetLinks.day("2026-10-19"), c.link)
        assertEquals(listOf("N"), c.shifts.map { it.code })
    }

    @Test
    fun afterMidnightTheSnapshotShowsTheNextDayWithoutTheApp() {
        // The widget was drawn on the 19th; nothing is republished; at 00:01 the
        // draw reads the clock and gets the 20th.
        assertEquals("N", (small(at(19, 23, 59, 59)) as WidgetContent.Small).big)
        val after = small(at(20, 0, 1)) as WidgetContent.Small
        assertEquals("2026-10-20", after.date)
        assertEquals("T", after.big)
        assertTrue(after.isHoliday)
        assertEquals("mar 20", after.dateLabel)
    }

    @Test
    fun severalShiftsEmptyDaysAndVacation() {
        val double = small(at(21)) as WidgetContent.Small
        assertEquals("M+T", double.big)
        assertEquals(2, double.shifts.size)
        assertEquals(listOf("M", "T"), double.shifts.map { it.code })

        val empty = small(at(22)) as WidgetContent.Small
        assertTrue(empty.isEmpty)
        assertEquals("Sin turno", empty.big)
        assertNull(empty.detail)
        assertTrue(empty.shifts.isEmpty())

        val vacation = small(at(23)) as WidgetContent.Small
        assertEquals(1, vacation.shifts.size)
        assertNull(vacation.detail?.takeIf { it.contains("–") })
    }

    @Test
    fun colorsComeFromTheSnapshotInLightAndDark() {
        val c = small(at(19)) as WidgetContent.Small
        val colors = c.shifts.single().colors
        for (pair in listOf(colors.bar, colors.tint, colors.ink, colors.disc)) {
            assertEquals("opaque", 0xFF, pair.light ushr 24)
            assertEquals("opaque", 0xFF, pair.dark ushr 24)
        }
        assertNotEquals("the dark tint is another colour", colors.tint.light, colors.tint.dark)
    }

    @Test
    fun mediumIsTheStripOfSevenDaysFromToday() {
        val c = medium(at(19)) as WidgetContent.Medium
        assertEquals(7, c.cells.size)
        assertEquals("2026-10-19", c.cells.first().date)
        assertTrue(c.cells.first().isToday)
        assertEquals(1, c.cells.count { it.isToday })
        assertEquals(
            (19..25).map { "2026-10-$it" },
            c.cells.map { it.date },
        )
        assertEquals(listOf("lun", "mar", "mié", "jue", "vie", "sáb", "dom"), c.cells.map { it.weekdayShort })
        assertEquals(listOf("N"), c.cells[0].bands.map { it.code })
        assertEquals(listOf("T"), c.cells[1].bands.map { it.code })
        assertEquals(listOf("M", "T"), c.cells[2].bands.map { it.code })
        assertTrue(c.cells[2].hasNote)
        assertTrue(c.cells[1].isHoliday)
        assertTrue(c.cells[3].bands.isEmpty())
        // Each band carries the colours of its style.
        assertNotEquals(c.cells[0].bands[0].colors.ink, c.cells[1].bands[0].colors.ink)
        assertEquals(WidgetLinks.day("2026-10-21"), c.cells[2].link)
    }

    @Test
    fun mediumMovesWithTheClockToo() {
        val c = medium(at(22, 0, 5)) as WidgetContent.Medium
        assertEquals("2026-10-22", c.cells.first().date)
        assertTrue(c.cells.first().isToday)
        assertTrue("Thursday has no shift", c.cells.first().bands.isEmpty())
    }

    @Test
    fun theStripKeepsGoingPastTheLastPublishedDay() {
        // 2026-10-28 is the last of the 10 published days; its strip goes to 11-03.
        val c = medium(at(28)) as WidgetContent.Medium
        assertEquals("2026-10-28", c.cells.first().date)
        assertEquals("2026-11-03", c.cells.last().date)
    }

    @Test
    fun outsideThePublishedDaysIsTheHonestMessageNotADay() {
        for (kind in Kind.values()) {
            val after = WidgetModelBuilder.build(json, kind, at(29), madrid)
            assertTrue(after is WidgetContent.Stale)
            after as WidgetContent.Stale
            assertEquals(WidgetDayLogic.StaleReason.AFTER_LAST, after.reason)
            assertEquals("Cuadrante", after.title)
            assertEquals("Abre Cuadrante para seguir al día", after.body)

            val before = WidgetModelBuilder.build(json, kind, at(18, 23, 59, 59), madrid)
            assertEquals(
                WidgetDayLogic.StaleReason.BEFORE_FIRST,
                (before as WidgetContent.Stale).reason,
            )
        }
    }

    @Test
    fun theLastPublishedDayIsStillShown() {
        assertEquals("2026-10-28", (small(at(28, 23, 59, 59)) as WidgetContent.Small).date)
        assertTrue(small(at(29, 0, 0, 0)) is WidgetContent.Stale)
    }

    @Test
    fun aTimeZoneChangeMovesToTheClockOfTheNewZone() {
        // 22:30 UTC on the 19th.
        val instant = java.time.Instant.parse("2026-10-19T22:30:00Z").toEpochMilli()
        assertEquals("2026-10-20", (small(instant, madrid) as WidgetContent.Small).date)
        assertEquals("2026-10-19", (small(instant, canary) as WidgetContent.Small).date)
    }

    @Test
    fun missingBrokenOrFutureSnapshotsAreTheMessageNeverACrash() {
        val now = at(19)
        for (bad in listOf(null, "", "not json", "{}", """{"v":3,"days":[]}""", """{"v":1}""", """{"v":1,"days":[{}]}""")) {
            for (kind in Kind.values()) {
                val c = WidgetModelBuilder.build(bad, kind, now, madrid)
                assertTrue("$bad", c is WidgetContent.Stale)
                assertEquals(WidgetDayLogic.StaleReason.NO_SNAPSHOT, (c as WidgetContent.Stale).reason)
                assertNull(c.title)
            }
        }
    }

    @Test
    fun aDayMissingItsDataIsTheMessageToo() {
        // Valid header and dates, but the day has none of its content.
        val broken = """{"v":1,"staleTitle":"T","staleBody":"B","days":[{"date":"2026-10-19"}]}"""
        val c = WidgetModelBuilder.build(broken, Kind.SMALL, at(19), madrid) as WidgetContent.Stale
        assertEquals(WidgetDayLogic.StaleReason.NOT_FOUND, c.reason)
    }
}
