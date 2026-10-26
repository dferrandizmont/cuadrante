package app.cuadrante.cuadrante.widget

import app.cuadrante.cuadrante.widget.WidgetModelBuilder.Kind
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId

class WidgetUpcomingTest {
    private val zone = ZoneId.of("Europe/Madrid")
    private val json = javaClass.getResource("/widget_snapshot.json")!!.readText()
    private fun at(date: String): Long = LocalDate.parse(date).atStartOfDay(zone).toInstant().toEpochMilli()
    private fun build(kind: Kind, date: String = "2026-10-21", data: String = json) =
        WidgetModelBuilder.build(data, kind, at(date), zone)

    @Test fun agendaStartsTodayAndHasFourteenRealDates() {
        val content = build(Kind.AGENDA) as WidgetContent.Agenda
        assertEquals("2026-10-21", content.date)
        assertEquals(14, content.days.size)
        assertEquals("2026-11-03", content.days.last().date)
        assertEquals("Sin turno", content.noShift)
        assertEquals(listOf("M", "T"), content.days.first().shifts.map { it.code })
        assertEquals("06:00–14:00", content.days.first().shifts.first().timeLabel)
        assertTrue(content.days.first().hasNote)
        assertTrue(content.days[1].shifts.isEmpty())
        assertEquals("cuadrante://widget/day/2026-10-21?homeWidget", content.days.first().link)
    }

    @Test fun twoWeeksAlwaysStartMondayAndCrossMonth() {
        val content = build(Kind.TWO_WEEKS, "2026-10-25") as WidgetContent.TwoWeeks
        assertEquals("2026-10-19", content.days.first().date)
        assertEquals("2026-11-01", content.days.last().date)
        assertEquals(14, content.days.size)
        assertEquals(LocalDate.parse("2025-12-29"), WidgetRenderPlan.monday(LocalDate.parse("2026-01-01")))
        assertEquals(LocalDate.parse("2026-10-26"), WidgetRenderPlan.monday(LocalDate.parse("2026-10-26")))
    }

    @Test fun midnightMovesAgendaAndMondayAdvancesBothWeeksWithoutRepublishing() {
        val midnight = at("2026-10-26")
        val before = WidgetModelBuilder.build(json, Kind.AGENDA, midnight - 1, zone) as WidgetContent.Agenda
        val after = WidgetModelBuilder.build(json, Kind.AGENDA, midnight, zone) as WidgetContent.Agenda
        assertEquals("2026-10-25", before.days.first().date)
        assertEquals("2026-10-26", after.days.first().date)
        val oldWeeks = WidgetModelBuilder.build(json, Kind.TWO_WEEKS, midnight - 1, zone) as WidgetContent.TwoWeeks
        val newWeeks = WidgetModelBuilder.build(json, Kind.TWO_WEEKS, midnight, zone) as WidgetContent.TwoWeeks
        assertEquals("2026-10-19", oldWeeks.days.first().date)
        assertEquals("2026-10-26", newWeeks.days.first().date)
        assertEquals("2026-11-08", newWeeks.days.last().date)
    }

    @Test fun sundayMonthPreferenceStillStartsTwoWeeksOnMonday() {
        val sundayMonth = javaClass.getResource("/widget_snapshot_month_change.json")!!.readText()
        assertEquals("D", JSONObject(sundayMonth).getJSONArray("weekdayHeaders").getString(0))
        val content = build(Kind.TWO_WEEKS, "2026-11-01", sundayMonth) as WidgetContent.TwoWeeks
        assertEquals("2026-10-26", content.days.first().date)
        assertEquals("2026-11-08", content.days.last().date)
    }

    @Test fun lastEntryStillHasFullAgendaButAuxiliaryDaysNeverExtendExpiry() {
        val content = build(Kind.AGENDA, "2026-10-28") as WidgetContent.Agenda
        assertEquals("2026-11-10", content.days.last().date)
        for (kind in listOf(Kind.AGENDA, Kind.TWO_WEEKS)) {
            assertTrue(build(kind, "2026-10-29") is WidgetContent.Stale)
            assertTrue(build(kind, "2026-10-18") is WidgetContent.Stale)
        }
    }

    @Test fun absenceIsGenericWithoutTimeOrNote() {
        val absenceDay = (build(Kind.AGENDA) as WidgetContent.Agenda).days.first { it.date == "2026-10-23" }
        val shift = absenceDay.shifts.single()
        assertEquals("absence", shift.category)
        assertEquals("Ausencia", shift.code)
        assertEquals(shift.code, shift.name)
        assertNull(shift.timeLabel)
        assertNull(shift.compactTime)
        assertFalse(absenceDay.hasNote)
        // Ignore a forged auxiliary note marker too, using the category only.
        val root = JSONObject(json)
        val ds = root.getJSONArray("displayDays")
        for (i in 0 until ds.length()) if (ds.getJSONObject(i).getString("date") == "2026-10-23") {
            ds.getJSONObject(i).put("hasNote", true)
        }
        assertFalse((build(Kind.AGENDA, data = root.toString()) as WidgetContent.Agenda).days[2].hasNote)
    }

    @Test fun missingAuxiliaryDateIsHonestStale() {
        val root = JSONObject(json)
        root.getJSONArray("displayDays").remove(5)
        for (kind in listOf(Kind.AGENDA, Kind.TWO_WEEKS)) assertTrue(build(kind, data = root.toString()) is WidgetContent.Stale)
    }

    @Test fun v1OldWidgetsRemainCompatibleAndNewOnesNeedACompleteSafeRange() {
        val old = javaClass.getResource("/widget_snapshot_v1.json")!!.readText()
        for (kind in listOf(Kind.SMALL, Kind.MEDIUM, Kind.LARGE)) assertFalse(build(kind, data = old) is WidgetContent.Stale)
        for (kind in listOf(Kind.AGENDA, Kind.TWO_WEEKS)) assertTrue(build(kind, data = old) is WidgetContent.Stale)
        // An old payload with a complete fourteen-day range and no absence can
        // serve both new widgets without inventing dates or translating shifts.
        val root = JSONObject(json).put("v", 1)
        val days = JSONArray()
        val ds = root.getJSONArray("displayDays")
        for (i in 0 until ds.length()) {
            val day = JSONObject(ds.getJSONObject(i).toString())
            if (day.getString("date") >= "2026-10-19") {
                if ((0 until day.getJSONArray("shifts").length()).any { j -> day.getJSONArray("shifts").getJSONObject(j).getString("category") == "absence" }) day.put("shifts", JSONArray())
                days.put(day)
            }
        }
        root.put("days", days).remove("displayDays")
        assertTrue(build(Kind.AGENDA, data = root.toString()) is WidgetContent.Agenda)
        assertTrue(build(Kind.TWO_WEEKS, data = root.toString()) is WidgetContent.TwoWeeks)
        val privateShift = JSONObject(JSONObject(json).getJSONArray("displayDays").getJSONObject(0).getJSONArray("shifts").getJSONObject(0).toString()).put("category", "absence").put("code", "PRIVATE")
        days.getJSONObject(2).put("shifts", JSONArray().put(privateShift))
        for (kind in listOf(Kind.AGENDA, Kind.TWO_WEEKS)) assertTrue(build(kind, data = root.toString()) is WidgetContent.Stale)
    }

    @Test fun resizeAndTextScaleChooseOnlyWholeRowsUpToFourteen() {
        val size = WidgetRenderPlan.Size(250, 110)
        val days = (build(Kind.AGENDA) as WidgetContent.Agenda).days
        val singleShiftDay = days.first().copy(shifts = days.first().shifts.take(1))
        val singleShiftDays = List(14) { singleShiftDay }
        assertEquals(2, WidgetRenderPlan.agendaRows(size, singleShiftDays))
        assertEquals(7, WidgetRenderPlan.agendaRows(size.copy(height = 350), singleShiftDays))
        assertEquals(4, WidgetRenderPlan.agendaRows(size.copy(height = 350, fontScale = 2f), singleShiftDays))
        assertEquals(14, WidgetRenderPlan.agendaRows(size.copy(height = 2000), singleShiftDays))
        assertEquals(1, WidgetRenderPlan.agendaRows(size, days)) // First date has two shifts.
        assertTrue(WidgetRenderPlan.agendaRows(size.copy(height = 350), days) > WidgetRenderPlan.agendaRows(size, days))
        assertTrue(WidgetRenderPlan.agendaRows(size.copy(height = 350, fontScale = 2f), days) < WidgetRenderPlan.agendaRows(size.copy(height = 350), days))
    }

    @Test fun compactTimesAreShownOnlyWhenTheWholeRangeFits() {
        val size = WidgetRenderPlan.Size(350, 180)
        assertTrue(WidgetRenderPlan.timeFits(20f, 40f, size, 1))
        assertFalse(WidgetRenderPlan.timeFits(50f, 40f, size, 1))
        assertFalse(WidgetRenderPlan.timeFits(20f, 40f, size.copy(height = 110), 1))
        assertFalse(WidgetRenderPlan.timeFits(20f, 40f, size.copy(fontScale = 2f), 1))
        assertFalse(WidgetRenderPlan.timeFits(20f, 40f, size, 3))
    }

    @Test fun crowdedDaysKeepAnExplicitOverflowCountAndRespectLargeText() {
        val shifts = (build(Kind.AGENDA) as WidgetContent.Agenda).days.first().shifts
        val five = List(5) { shifts[it % shifts.size] }
        val size = WidgetRenderPlan.Size(350, 180)
        val slots = WidgetRenderPlan.twoWeeksSlots(five, size)
        assertEquals(2, slots.size)
        assertEquals(3, slots.last().hidden)
        assertTrue(slots.last().code.endsWith(" +3"))
        val large = WidgetRenderPlan.twoWeeksSlots(five, size.copy(height = 110, fontScale = 2f))
        assertEquals(1, large.size)
        assertEquals(4, large.single().hidden)
        assertTrue(WidgetRenderPlan.twoWeeksSlots(emptyList(), size).isEmpty())
        for (scale in listOf(1f, 1.3f, 2f)) {
            val small = size.copy(height = 110, fontScale = scale)
            val day = (build(Kind.AGENDA) as WidgetContent.Agenda).days.first().copy(shifts = five)
            val agenda = WidgetRenderPlan.agendaSlots(five, small)
            assertTrue(agenda.last().hidden > 0)
            assertTrue(WidgetRenderPlan.agendaDayHeight(small, day) + 16 <= small.height)
            assertTrue(WidgetRenderPlan.agendaSlots(emptyList(), small).isEmpty())
        }
    }

    @Test fun staleToFreshRestoresBothNewRootLayouts() {
        for (kind in listOf(Kind.AGENDA, Kind.TWO_WEEKS)) {
            assertEquals(WidgetRenderPlan.Root(true, false), WidgetRenderPlan.root(build(kind, "2026-10-29")))
            assertEquals(WidgetRenderPlan.Root(false, true), WidgetRenderPlan.root(build(kind)))
        }
    }
}
