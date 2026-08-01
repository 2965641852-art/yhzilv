package com.yeheng.discipline.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import com.yeheng.discipline.MainActivity
import com.yeheng.discipline.R

class TodoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
    }

    companion object {
        private const val PREFS = "widget_data"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_todo)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val count = prefs.getInt("pending", 0)
            val items = prefs.getString("items", "") ?: ""

            views.setTextViewText(R.id.widget_todos, "📋 待办 ${count}项")
            if (items.isNotEmpty()) {
                views.setTextViewText(R.id.widget_todos, "📋 待办 ${count}项\n$items")
            }
            val habits = prefs.getString("habits", "") ?: ""
            if (habits.isNotEmpty()) {
                views.setTextViewText(R.id.widget_habits, "✅ 习惯\n$habits")
            } else {
                views.setTextViewText(R.id.widget_habits, "✅ 暂无习惯")
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pi = PendingIntent.getActivity(context, 0, intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                else PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, TodoWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(componentName)
            for (id in ids) updateWidget(context, appWidgetManager, id)
        }
    }
}
