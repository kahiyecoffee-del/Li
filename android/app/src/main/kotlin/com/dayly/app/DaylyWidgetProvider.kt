package com.dayly.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Today's program on the home screen; data comes from the app (home_widget). */
class DaylyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        // Yesterday's plan is not shown once the day changes.
        val fresh = widgetData.getString("day", null) == today
        val lines = if (fresh) widgetData.getString("lines", "") ?: "" else ""
        val summary =
            if (fresh) widgetData.getString("summary", "") ?: ""
            else widgetData.getString("staleHint", "") ?: ""
        val route = if (fresh) widgetData.getString("route", "/plan") ?: "/plan" else "/plan"
        val title = widgetData.getString("title", null) ?: "Dayly"
        val mood = if (fresh) widgetData.getString("mood", "happy") ?: "happy" else "curious"
        val (poseA, poseB) = poses(mood)
        val nextId = if (fresh) widgetData.getString("nextId", "") ?: "" else ""
        val doneLabel = widgetData.getString("doneLabel", "") ?: ""

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.dayly_widget).apply {
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_lines, lines)
                setViewVisibility(R.id.widget_lines, if (lines.isEmpty()) View.GONE else View.VISIBLE)
                setTextViewText(R.id.widget_summary, summary)
                setImageViewResource(R.id.widget_lio_a, poseA)
                setImageViewResource(R.id.widget_lio_b, poseB)
                val uri = Uri.parse("dayly://open?homeWidget&r=" + Uri.encode(route))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
                )
                // Tick off the next task: opens the app, which marks it done.
                val showDone = nextId.isNotEmpty() && doneLabel.isNotEmpty()
                setViewVisibility(R.id.widget_done, if (showDone) View.VISIBLE else View.GONE)
                if (showDone) {
                    setTextViewText(R.id.widget_done, doneLabel)
                    val doneUri = Uri.parse("dayly://open?homeWidget&r=" + Uri.encode("/plan?done=" + nextId))
                    setOnClickPendingIntent(
                        R.id.widget_done,
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, doneUri),
                    )
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** Lio's pose for the mood and the one it switches to now and then. */
    private fun poses(mood: String): Pair<Int, Int> = when (mood) {
        "curious" -> R.drawable.widget_lio_curious to R.drawable.widget_lio_thoughtful
        "excited" -> R.drawable.widget_lio_excited to R.drawable.widget_lio_happy
        "thoughtful" -> R.drawable.widget_lio_thoughtful to R.drawable.widget_lio_curious
        "sleepy" -> R.drawable.widget_lio_sleepy to R.drawable.widget_lio_sleepy
        else -> R.drawable.widget_lio_happy to R.drawable.widget_lio_heart
    }
}
