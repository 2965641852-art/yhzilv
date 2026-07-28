package com.yeheng.discipline

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yeheng.discipline/usage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> {
                        result.success(hasUsagePermission())
                    }
                    "openUsageSettings" -> {
                        openUsageSettings()
                        result.success(true)
                    }
                    "getTodayUsage" -> {
                        result.success(getTodayUsage())
                    }
                    "getWeeklyUsage" -> {
                        result.success(getWeeklyUsage())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOp(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOp(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getTodayUsage(): List<Map<String, Any>> {
        if (!hasUsagePermission()) return emptyList()

        val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()

        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = cal.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: return emptyList()

        val pm = packageManager

        // 一次性加载所有应用名映射，避免逐个查询失败
        val appNameMap = mutableMapOf<String, String>()
        try {
            val apps = pm.getInstalledApplications(0)
            for (ai in apps) {
                appNameMap[ai.packageName] = pm.getApplicationLabel(ai).toString()
            }
        } catch (e: Exception) {
            // fallback: 使用包名
        }

        // 按包名聚合
        val aggregated = mutableMapOf<String, MutableMap<String, Any>>()
        for (stat in stats) {
            if (stat.totalTimeInForeground <= 0) continue
            val pkg = stat.packageName
            if (aggregated.containsKey(pkg)) {
                val existing = aggregated[pkg]!!
                existing["usageDuration"] = (existing["usageDuration"] as Long) + stat.totalTimeInForeground
                if (stat.lastTimeUsed > (existing["lastUsed"] as Long)) {
                    existing["lastUsed"] = stat.lastTimeUsed
                }
            } else {
                val name = appNameMap[pkg] ?: pkg
                aggregated[pkg] = mutableMapOf(
                    "packageName" to pkg,
                    "appName" to name,
                    "usageDuration" to stat.totalTimeInForeground,
                    "lastUsed" to stat.lastTimeUsed
                )
            }
        }

        return aggregated.values.sortedByDescending { it["usageDuration"] as Long }
    }

    private fun getWeeklyUsage(): Map<String, Long> {
        if (!hasUsagePermission()) return emptyMap()

        val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val cal = java.util.Calendar.getInstance()

        val result = mutableMapOf<String, Long>()
        val dayNames = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")

        for (i in 6 downTo 0) {
            cal.timeInMillis = endTime
            cal.add(java.util.Calendar.DAY_OF_YEAR, -i)
            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
            cal.set(java.util.Calendar.MINUTE, 0)
            cal.set(java.util.Calendar.SECOND, 0)
            cal.set(java.util.Calendar.MILLISECOND, 0)
            val dayStart = cal.timeInMillis
            cal.set(java.util.Calendar.HOUR_OF_DAY, 23)
            cal.set(java.util.Calendar.MINUTE, 59)
            cal.set(java.util.Calendar.SECOND, 59)
            val dayEnd = cal.timeInMillis

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                dayStart,
                dayEnd
            )

            // 按包名去重，同一应用只取最大时长记录
            val seen = mutableSetOf<String>()
            var totalMs = 0L
            stats?.sortedByDescending { it.totalTimeInForeground }?.forEach { stat ->
                if (!seen.contains(stat.packageName)) {
                    seen.add(stat.packageName)
                    totalMs += stat.totalTimeInForeground
                }
            }

            val dayIndex = java.util.Calendar.getInstance().apply {
                timeInMillis = dayStart
            }.get(java.util.Calendar.DAY_OF_WEEK) - 1
            val label = dayNames[(dayIndex + 6) % 7]

            result[label] = totalMs / 60000
        }

        return result
    }
}
