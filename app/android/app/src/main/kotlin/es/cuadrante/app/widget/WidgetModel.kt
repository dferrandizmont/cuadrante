package es.cuadrante.app.widget

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId

/** Colour of an element in light and dark mode (ARGB ints, as in the snapshot). */
data class ColorPair(val light: Int, val dark: Int)

/** The four colours of a shift (`docs/widget-contrato.md`, section 3). */
data class ShiftColors(
    val bar: ColorPair,
    val tint: ColorPair,
    val ink: ColorPair,
    val disc: ColorPair,
)

/** One shift band of a cell: its code and its colours. */
data class Band(val code: String, val colors: ShiftColors)

/** Auxiliary v2 data. Times and privacy-safe absence labels arrive ready to paint. */
data class DisplayShift(
    val code: String,
    val name: String,
    val timeLabel: String?,
    val compactTime: String?,
    val category: String,
    val colors: ShiftColors,
)

data class DisplayDay(
    val date: String,
    val weekdayShort: String,
    val dayOfMonth: Int,
    val dateLabel: String,
    val isHoliday: Boolean,
    val hasNote: Boolean,
    val shifts: List<DisplayShift>,
    val description: String? = null,
) {
    val link: String get() = WidgetLinks.day(date) + "?homeWidget"
}

/** One of the seven cells of the medium widget. */
data class StripCell(
    val date: String,
    val weekdayShort: String,
    val dayOfMonth: Int,
    val isToday: Boolean,
    val isHoliday: Boolean,
    val hasNote: Boolean,
    val bands: List<Band>,
    val description: String? = null,
) {
    val link: String get() = WidgetLinks.day(date)
}

/** One of the 42 cells of the month widget. Out-of-month cells carry the dimmed colours. */
data class MonthCell(
    val date: String,
    val dayOfMonth: Int,
    val inMonth: Boolean,
    val isToday: Boolean,
    val isHoliday: Boolean,
    val hasNote: Boolean,
    val bands: List<Band>,
    val description: String? = null,
) {
    /** The shifts the cell has room for ([WidgetDayLogic.MAX_CELL_BANDS]). */
    val shown: List<Band> get() = bands.take(WidgetDayLogic.MAX_CELL_BANDS)

    val link: String get() = WidgetLinks.day(date)
}

/** What a widget draws. Built by [WidgetModelBuilder]; the renderer only paints it. */
sealed interface WidgetContent {
    /** The fourteen available dates; the render plan chooses the rows that fit. */
    data class Agenda(val date: String, val noShift: String?, val days: List<DisplayDay>) : WidgetContent

    /** Two Monday-first weeks, independent of the user's month-grid preference. */
    data class TwoWeeks(val date: String, val noShift: String?, val days: List<DisplayDay>) : WidgetContent

    /** The "open the app" message. */
    data class Stale(
        val reason: WidgetDayLogic.StaleReason,
        /** From the snapshot; null when there is none (the resources' texts are used). */
        val title: String?,
        val body: String?,
    ) : WidgetContent

    /** 2x2: today big, with tomorrow below. */
    data class Small(
        val date: String,
        val dateLabel: String,
        val isHoliday: Boolean,
        val big: String,
        val isEmpty: Boolean,
        val detail: String?,
        val tomorrow: String,
        val shifts: List<Band>,
        val description: String? = null,
    ) : WidgetContent {
        val link: String get() = WidgetLinks.day(date)
    }

    /** 4x2: the strip of seven days from today. */
    data class Medium(val date: String, val cells: List<StripCell>) : WidgetContent {
        val link: String get() = WidgetLinks.day(date)
    }

    /** 4x4: the month grid of today's month. */
    data class Large(
        val date: String,
        /** `yyyy-MM`. */
        val monthKey: String,
        /** "Octubre 2026". */
        val title: String,
        /** The seven column headers, in the order of the grid. */
        val weekdayHeaders: List<String>,
        /** Always [WidgetDayLogic.MONTH_CELLS], row by row. */
        val cells: List<MonthCell>,
    ) : WidgetContent {
        /** A tap on the header opens the month. */
        val link: String get() = WidgetLinks.month(monthKey)
    }
}

/** The links a widget tap opens (the Dart side reads the same ones: `widget_links.dart`). */
object WidgetLinks {
    const val SCHEME = "cuadrante"
    const val HOST = "widget"

    fun day(isoDate: String): String = "$SCHEME://$HOST/day/$isoDate"

    /** [monthKey] is `yyyy-MM`. */
    fun month(monthKey: String): String = "$SCHEME://$HOST/month/$monthKey"

    /** Opens the app without naming a day. */
    const val APP = "$SCHEME://$HOST"
}

/**
 * Turns the JSON snapshot (`lib/features/widget/domain/widget_snapshot.dart`)
 * into what a widget draws for a given instant. Pure: no Android classes, so
 * the JVM tests run it on a snapshot written by the Dart code.
 *
 * Reading is defensive: a missing or broken snapshot, another version or a
 * missing key never throws; the result is the "open the app" message.
 */
object WidgetModelBuilder {
    const val SUPPORTED_VERSION = 2

    enum class Kind { SMALL, MEDIUM, LARGE, AGENDA, TWO_WEEKS }

    /** The content of a [kind] widget at [nowMillis] in [zone] (the device's zone). */
    fun build(json: String?, kind: Kind, nowMillis: Long, zone: ZoneId): WidgetContent {
        val root = parse(json) ?: return WidgetContent.Stale(
            WidgetDayLogic.StaleReason.NO_SNAPSHOT, null, null,
        )
        val days = root.optJSONArray("days")
        val dates = dates(days)
        val selection = WidgetDayLogic.select(dates, WidgetDayLogic.today(nowMillis, zone))
        if (selection !is WidgetDayLogic.Selection.Day) {
            val reason = (selection as WidgetDayLogic.Selection.Stale).reason
            return WidgetContent.Stale(
                reason,
                root.optString("staleTitle").ifEmpty { null },
                root.optString("staleBody").ifEmpty { null },
            )
        }
        return try {
            val day = days!!.getJSONObject(selection.index)
            when (kind) {
                Kind.SMALL -> small(root, day)
                Kind.MEDIUM -> medium(root, day)
                Kind.LARGE -> large(root, day, WidgetDayLogic.today(nowMillis, zone))
                Kind.AGENDA -> WidgetContent.Agenda(
                    day.getString("date"), root.optStringOrNull("noShift"),
                    displayDays(root, WidgetDayLogic.today(nowMillis, zone), WidgetDayLogic.today(nowMillis, zone)),
                )
                Kind.TWO_WEEKS -> WidgetContent.TwoWeeks(
                    day.getString("date"), root.optStringOrNull("noShift"),
                    displayDays(root, WidgetRenderPlan.monday(WidgetDayLogic.today(nowMillis, zone)), WidgetDayLogic.today(nowMillis, zone)),
                )
            }
        } catch (_: JSONException) {
            WidgetContent.Stale(WidgetDayLogic.StaleReason.NOT_FOUND, null, null)
        }
    }

    /** The dates of the days, or empty when the snapshot cannot be used. */
    fun dates(days: JSONArray?): List<String> {
        if (days == null) return emptyList()
        return List(days.length()) { days.optJSONObject(it)?.optString("date").orEmpty() }
            .takeIf { list -> list.all { it.isNotEmpty() } } ?: emptyList()
    }

    private fun parse(json: String?): JSONObject? {
        if (json.isNullOrEmpty()) return null
        return try {
            JSONObject(json).takeIf { it.optInt("v", -1) in 1..SUPPORTED_VERSION }
        } catch (_: JSONException) {
            null
        }
    }

    private fun displayDays(root: JSONObject, start: LocalDate, today: LocalDate): List<DisplayDay> {
        val v1 = root.getInt("v") == 1
        val source = root.getJSONArray(if (v1) "days" else "displayDays")
        val byDate = (0 until source.length()).map { source.getJSONObject(it) }
            .associateBy { it.getString("date") }
        return List(WidgetRenderPlan.MAX_AGENDA_ROWS) { i ->
            val iso = start.plusDays(i.toLong()).toString()
            val d = byDate[iso] ?: throw JSONException("incomplete display range")
            val shifts = d.getJSONArray("shifts")
            val parsed = List(shifts.length()) { j ->
                val s = shifts.getJSONObject(j)
                // Old snapshots contain the private absence name/code. They may
                // still serve the original widgets, but cannot serve these new ones.
                if (v1 && s.getString("category") == "absence") throw JSONException("private v1 absence")
                DisplayShift(s.getString("code"), s.getString("name"),
                    s.optStringOrNull("timeLabel"), s.optStringOrNull("compactTime"),
                    s.getString("category"), colorsOf(s))
            }
            DisplayDay(iso, d.getString("weekdayShort"), d.getInt("dayOfMonth"),
                d.getString("dateLabel"), d.getBoolean("isHoliday"),
                // Even malformed auxiliary data must not expose a note marker on an absence.
                d.getBoolean("hasNote") && parsed.none { it.category == "absence" }, parsed,
                description(root, iso, iso == today.toString(), auxiliary = true))
        }
    }

    private fun small(root: JSONObject, day: JSONObject): WidgetContent.Small {
        val small = day.getJSONObject("small")
        val shifts = day.getJSONArray("shifts")
        return WidgetContent.Small(
            date = day.getString("date"),
            dateLabel = day.getString("dateLabel"),
            isHoliday = day.optBoolean("isHoliday"),
            description = description(root, day.getString("date"), true),
            big = small.getString("big"),
            isEmpty = small.optBoolean("isEmpty"),
            detail = small.optStringOrNull("detail"),
            tomorrow = small.optString("tomorrow"),
            shifts = List(shifts.length()) {
                val s = shifts.getJSONObject(it)
                Band(s.getString("code"), colorsOf(s))
            },
        )
    }

    private fun medium(root: JSONObject, day: JSONObject): WidgetContent.Medium {
        val styles = root.getJSONArray("styles")
        val cells = day.getJSONObject("medium").getJSONArray("cells")
        return WidgetContent.Medium(
            date = day.getString("date"),
            cells = List(cells.length()) { i ->
                val c = cells.getJSONObject(i)
                val bands = c.getJSONArray("bands")
                StripCell(
                    date = c.getString("date"),
                    weekdayShort = c.getString("weekdayShort"),
                    dayOfMonth = c.getInt("dayOfMonth"),
                    isToday = c.optBoolean("isToday"),
                    description = description(root, c.getString("date"), c.optBoolean("isToday")),
                    isHoliday = c.optBoolean("isHoliday"),
                    hasNote = c.optBoolean("hasNote"),
                    bands = List(bands.length()) { b ->
                        val band = bands.getJSONObject(b)
                        Band(
                            band.getString("code"),
                            colorsOf(styles.getJSONObject(band.getInt("style"))),
                        )
                    },
                )
            },
        )
    }

    /**
     * The month grid of [today] (`months[day.large.month]`, `weekdayHeaders`,
     * `day.large.todayCell`). A grid that is not today's, or has not 42
     * cells, throws [JSONException]: the caller shows the message instead of
     * a wrong month.
     */
    private fun large(root: JSONObject, day: JSONObject, today: LocalDate): WidgetContent.Large {
        val styles = root.getJSONArray("styles")
        val months = root.getJSONArray("months")
        val headers = root.getJSONArray("weekdayHeaders")
        if (headers.length() != WidgetDayLogic.MONTH_COLUMNS) throw JSONException("weekdayHeaders")
        val pointer = day.getJSONObject("large")
        val keys = List(months.length()) { months.getJSONObject(it).getString("key") }
        val index = WidgetDayLogic.monthIndex(keys, pointer.getInt("month"), today)
            ?: throw JSONException("no month for $today")
        val month = months.getJSONObject(index)
        val cells = month.getJSONArray("cells")
        val dates = List(cells.length()) { cells.getJSONObject(it).getString("date") }
        val todayCell = WidgetDayLogic.todayCell(dates, pointer.getInt("todayCell"), today)
            ?: throw JSONException("no cell for $today")
        return WidgetContent.Large(
            date = day.getString("date"),
            monthKey = keys[index],
            title = month.getString("title"),
            weekdayHeaders = List(headers.length()) { headers.getString(it) },
            cells = List(cells.length()) { i ->
                val c = cells.getJSONObject(i)
                val inMonth = c.getBoolean("inMonth")
                val bands = c.getJSONArray("bands")
                MonthCell(
                    date = c.getString("date"),
                    dayOfMonth = c.getInt("dayOfMonth"),
                    inMonth = inMonth,
                    isToday = i == todayCell,
                    description = description(root, c.getString("date"), i == todayCell),
                    isHoliday = c.optBoolean("isHoliday"),
                    hasNote = c.optBoolean("hasNote"),
                    bands = List(bands.length()) { b ->
                        val band = bands.getJSONObject(b)
                        Band(
                            band.getString("code"),
                            // Days of the neighbouring months use the dimmed colours.
                            colorsOf(styles.getJSONObject(band.getInt("style")), dim = !inMonth),
                        )
                    },
                )
            },
        )
    }

    /**
     * `bar`/`tint`/`ink`/`disc`, each for light and dark, of a shift or a style;
     * with [dim], the "other month" variant of a style (`dimBarLight`...).
     */
    private fun colorsOf(o: JSONObject, dim: Boolean = false): ShiftColors {
        fun pair(name: String): ColorPair {
            val key = if (dim) "dim" + name.replaceFirstChar { it.uppercase() } else name
            return ColorPair(o.getLong("${key}Light").toInt(), o.getLong("${key}Dark").toInt())
        }
        return ShiftColors(pair("bar"), pair("tint"), pair("ink"), pair("disc"))
    }

    /** Optional extension: old v1/v2 snapshots keep their original fallback. */
    private fun description(root: JSONObject, date: String, isToday: Boolean,
                            auxiliary: Boolean = false): String? {
        val texts = root.optJSONObject("descriptions") ?: return null
        val redacted = if (auxiliary) texts.optJSONObject("absences")?.optStringOrNull(date) else null
        val label = redacted ?: texts.optJSONObject("days")?.optStringOrNull(date) ?: return null
        val today = if (isToday) texts.optStringOrNull("today") else null
        return listOfNotNull(today, label).joinToString(". ")
    }

    private fun JSONObject.optStringOrNull(name: String): String? =
        if (isNull(name) || !has(name)) null else getString(name)
}
