package es.cuadrante.app.widget

import es.cuadrante.app.widget.WidgetModelBuilder.Kind
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * H-T12-2: every draw must state the visibility of the "open the app" message
 * AND of the content, because the launcher re-applies a new `RemoteViews` on
 * the views it already has and keeps whatever the previous draw left.
 */
class WidgetRenderPlanTest {
    private val madrid = ZoneId.of("Europe/Madrid")
    private val json: String = javaClass.getResource("/widget_snapshot.json")!!.readText()

    private fun at(month: Int, d: Int): Long =
        ZonedDateTime.of(LocalDateTime.of(2026, month, d, 12, 0), madrid).toInstant().toEpochMilli()

    private fun plan(kind: Kind, now: Long) =
        WidgetRenderPlan.root(WidgetModelBuilder.build(json, kind, now, madrid))

    @Test
    fun staleShowsTheMessageAndHidesTheContent() {
        for (kind in Kind.values()) {
            // 61 days after the last published day: the "open the app" message.
            assertEquals(WidgetRenderPlan.Root(showStale = true, showContent = false), plan(kind, at(12, 19)))
            // No snapshot at all: the same.
            val none = WidgetRenderPlan.root(WidgetModelBuilder.build(null, kind, at(10, 20), madrid))
            assertEquals(WidgetRenderPlan.Root(showStale = true, showContent = false), none)
        }
    }

    @Test
    fun freshDataHidesTheMessageAndShowsTheContentExplicitly() {
        // The bug: the draw after a stale one never set stale=GONE / content=VISIBLE.
        for (kind in Kind.values()) {
            assertEquals(WidgetRenderPlan.Root(showStale = false, showContent = true), plan(kind, at(10, 20)))
        }
    }

    @Test
    fun staleThenFreshFlipsBothViews() {
        val stale = plan(Kind.SMALL, at(12, 19))
        val fresh = plan(Kind.SMALL, at(10, 20))
        assertEquals(!stale.showStale, fresh.showStale)
        assertEquals(!stale.showContent, fresh.showContent)
    }

    @Test
    fun barSegmentsAreAllStatedSoAnEmptyDayHidesThePreviousOnes() {
        assertEquals(listOf(false, false, false), WidgetRenderPlan.barVisibility(0, 3))
        assertEquals(listOf(true, false, false), WidgetRenderPlan.barVisibility(1, 3))
        assertEquals(listOf(true, true, false), WidgetRenderPlan.barVisibility(2, 3))
        assertEquals(listOf(true, true), WidgetRenderPlan.barVisibility(5, 2))
    }
}
