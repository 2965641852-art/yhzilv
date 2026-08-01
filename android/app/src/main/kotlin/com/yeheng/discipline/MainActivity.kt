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
import com.yeheng.discipline.widget.TodoWidgetProvider

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
                    "updateWidget" -> {
                        updateWidgetData(call.arguments as Map<String, Any>)
                        result.success(true)
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
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun updateWidgetData(data: Map<String, Any>) {
        val prefs = getSharedPreferences("widget_data", MODE_PRIVATE)
        prefs.edit().apply {
            val t = data["title"] as? String; if (!t.isNullOrEmpty()) putString("title", t)
            val p = data["pending"] as? Number; if (p != null) putInt("pending", p.toInt())
            val i = data["items"] as? String; if (!i.isNullOrEmpty()) putString("items", i)
            val h = data["habits"] as? String; if (!h.isNullOrEmpty()) putString("habits", h)
            apply()
        }
        TodoWidgetProvider.updateAllWidgets(this)
    }

    // 内置常见应用名映射（不依赖 Android 权限 API）
    private val KNOWN_APPS = mapOf(
        "com.tencent.mm" to "微信",
        "com.tencent.mobileqq" to "QQ",
        "com.tencent.wework" to "企业微信",
        "com.ss.android.ugc.aweme" to "抖音",
        "com.ss.android.ugc.aweme.lite" to "抖音极速版",
        "com.smile.gifmaker" to "快手",
        "com.kuaishou.nebula" to "快手极速版",
        "com.xingin.xhs" to "小红书",
        "com.sina.weibo" to "微博",
        "com.zhihu.android" to "知乎",
        "com.baidu.tieba" to "百度贴吧",
        "com.baidu.searchbox" to "百度",
        "com.android.chrome" to "Chrome",
        "com.bilibili.app.in" to "哔哩哔哩",
        "com.taobao.taobao" to "淘宝",
        "com.tmall.wireless" to "天猫",
        "com.jingdong.app.mall" to "京东",
        "com.xunmeng.pinduoduo" to "拼多多",
        "com.meituan.android" to "美团",
        "com.sankuai.meituan.takeoutnew" to "美团外卖",
        "com.eg.android.AlipayGphone" to "支付宝",
        "com.netease.cloudmusic" to "网易云音乐",
        "com.kugou.android" to "酷狗音乐",
        "com.tencent.qqmusic" to "QQ音乐",
        "com.tencent.qqlive" to "腾讯视频",
        "com.youku.phone" to "优酷",
        "com.qiyi.video" to "爱奇艺",
        "com.cctv.yangshipin.app.androidp" to "央视频",
        "com.UCMobile" to "UC浏览器",
        "com.android.browser" to "浏览器",
        "com.android.email" to "邮箱",
        "com.android.calendar" to "日历",
        "com.android.settings" to "设置",
        "com.android.phone" to "电话",
        "com.android.mms" to "短信",
        "com.android.contacts" to "联系人",
        "com.android.camera" to "相机",
        "com.android.gallery3d" to "相册",
        "com.android.systemui" to "系统界面",
        "com.android.launcher" to "桌面",
        "com.miui.home" to "桌面",
        "com.huawei.android.launcher" to "桌面",
        "com.oppo.launcher" to "桌面",
        "com.vivo.launcher" to "桌面",
        "com.samsung.android.app.spage" to "桌面",
        "com.google.android.youtube" to "YouTube",
        "com.google.android.gm" to "Gmail",
        "com.google.android.apps.maps" to "Google地图",
        "com.google.android.apps.photos" to "Google相册",
        "com.twitter.android" to "X/Twitter",
        "com.instagram.android" to "Instagram",
        "com.facebook.katana" to "Facebook",
        "com.spotify.music" to "Spotify",
        "com.tencent.tmgp.sgame" to "王者荣耀",
        "com.tencent.tmgp.pubgmhd" to "和平精英",
        "com.tencent.tmgp.cf" to "穿越火线",
        "com.netease.hyxd" to "荒野行动",
        "com.miHoYo.Yuanshen" to "原神",
        "com.hypergryph.arknights" to "明日方舟",
        "com.miHoYo.hkrpg" to "崩坏星穹铁道",
        "tv.danmaku.bili" to "B站",
        "com.douban.frodo" to "豆瓣",
        "com.tencent.weread" to "微信读书",
        "com.chaozh.iReaderFree" to "掌阅",
        "com.jjwxc.reader" to "晋江文学城",
        "com.gotokeep.keep" to "Keep",
        "com.codoon.gps" to "咕咚",
        "com.tencent.news" to "腾讯新闻",
        "com.ss.android.article.news" to "今日头条",
        "com.netease.newsreader.activity" to "网易新闻",
        "com.baidu.BaiduMap" to "百度地图",
        "com.autonavi.minimap" to "高德地图",
        "com.tencent.map" to "腾讯地图",
        "com.didi.passenger" to "滴滴出行",
        "ctrip.android.view" to "携程",
        "com.MobileTicket" to "铁路12306",
        "com.taobao.idlefish" to "闲鱼",
        "com.alibaba.android.rimet" to "钉钉",
        "com.tencent.wemeet.app" to "腾讯会议",
        "com.bytedance.lark" to "飞书",
        "com.tencent.androidqqmail" to "QQ邮箱",
        "com.netease.mobimail" to "网易邮箱大师"
    )

    // 尝试多种方式获取应用名
    private fun getAppName(pkg: String): String {
        // 1. 内置映射
        KNOWN_APPS[pkg]?.let { return it }

        // 2. PackageManager
        try {
            val ai = packageManager.getApplicationInfo(pkg, 0)
            val label = packageManager.getApplicationLabel(ai)
            if (label != null && label.toString() != pkg) return label.toString()
        } catch (_: Exception) {}

        // 3. Launch intent
        try {
            val intent = packageManager.getLaunchIntentForPackage(pkg)
            if (intent != null) {
                val label = intent.resolveActivityInfo(packageManager, 0)?.loadLabel(packageManager)
                if (label != null && label.toString() != pkg) return label.toString()
            }
        } catch (_: Exception) {}

        return pkg
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

        // 使用 UsageEvents 精确计算前台时间
        val usageMap = mutableMapOf<String, Long>()
        val lastForeground = mutableMapOf<String, Long>()
        val lastUsedMap = mutableMapOf<String, Long>()

        try {
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = android.app.usage.UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val pkg = event.packageName ?: continue
                when (event.eventType) {
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastForeground[pkg] = event.timeStamp
                    }
                    android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED -> {
                        if (!lastForeground.containsKey(pkg)) {
                            lastForeground[pkg] = event.timeStamp
                        }
                    }
                    android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED,
                    android.app.usage.UsageEvents.Event.ACTIVITY_STOPPED -> {
                        val start = lastForeground.remove(pkg)
                        if (start != null) {
                            usageMap[pkg] = (usageMap[pkg] ?: 0L) + (event.timeStamp - start)
                        }
                    }
                }
                lastUsedMap[pkg] = event.timeStamp
            }
            // 仍在运行的 app
            for ((pkg, start) in lastForeground) {
                usageMap[pkg] = (usageMap[pkg] ?: 0L) + (endTime - start)
            }
        } catch (e: Exception) {
            // events 查询失败，回退到 queryUsageStats
            return getTodayUsageFallback()
        }

        return usageMap
            .filter { it.value > 0 }
            .map { (pkg, duration) ->
                mutableMapOf(
                    "packageName" to pkg,
                    "appName" to getAppName(pkg),
                    "usageDuration" to duration,
                    "lastUsed" to (lastUsedMap[pkg] ?: 0L)
                )
            }
            .sortedByDescending { it["usageDuration"] as Long }
    }

    // 回退方案：使用 queryUsageStats
    private fun getTodayUsageFallback(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = cal.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return emptyList()

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
                aggregated[pkg] = mutableMapOf(
                    "packageName" to pkg,
                    "appName" to getAppName(pkg),
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
