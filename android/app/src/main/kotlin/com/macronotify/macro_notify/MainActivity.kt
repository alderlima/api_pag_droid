package com.macronotify.macro_notify

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.macronotify.macro_notify/notifications"
        private const val EVENT_CHANNEL = "com.macronotify.macro_notify/notifications_stream"
        private const val TAG = "MainActivity"
        private const val PREFS_NAME = "macro_notify_prefs"
        private const val ENABLED_APPS_KEY = "enabled_apps"


    }

    private lateinit var dbHelper: NotificationDatabaseHelper
    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        dbHelper = NotificationDatabaseHelper(this)
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // MethodChannel para comandos
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNotifications" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    val notifications = dbHelper.getNotifications(limit)
                    result.success(notifications)
                }
                "deleteNotification" -> {
                    val id = call.argument<Long>("id")
                    if (id != null) {
                        dbHelper.deleteNotification(id)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "ID é obrigatório", null)
                    }
                }
                "clearAllNotifications" -> {
                    dbHelper.clearAllNotifications()
                    result.success(true)
                }
                "getEnabledApps" -> {
                    val apps = dbHelper.getEnabledApps()
                    result.success(apps)
                }
                "enableApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val appName = call.argument<String>("appName")
                    if (packageName != null && appName != null) {
                        dbHelper.addEnabledApp(packageName, appName)
                        updateEnabledAppsPrefs()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName e appName são obrigatórios", null)
                    }
                }
                "disableApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        dbHelper.removeEnabledApp(packageName)
                        updateEnabledAppsPrefs()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName é obrigatório", null)
                    }
                }
                "isNotificationListenerEnabled" -> {
                    val isEnabled = isNotificationListenerEnabled()
                    result.success(isEnabled)
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "checkPermissions" -> {
                    val permissions = checkPermissions()
                    result.success(permissions)
                }
                "requestPermissions" -> {
                    requestPermissions()
                    result.success(true)
                }
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledApps()
                        Log.d(TAG, "Retornando ${apps.length()} apps instalados")
                        result.success(apps.toString())
                    } catch (e: Exception) {
                        Log.e(TAG, "Erro ao listar apps", e)
                        result.error("ERROR", "Erro ao listar aplicativos: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel para streaming de notificações
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    NotificationListener.eventSink = sink
                    Log.d(TAG, "EventChannel ouvindo")
                }

                override fun onCancel(arguments: Any?) {
                    NotificationListener.eventSink = null
                    Log.d(TAG, "EventChannel cancelado")
                }
            }
        )

        Log.d(TAG, "Canais configurados")
    }

    private fun getInstalledApps(): JSONArray {
        val apps = JSONArray()
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        for (appInfo in packages) {
            // Pular apps de sistema (opcional)
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) continue
            val appName = pm.getApplicationLabel(appInfo).toString()
            val packageName = appInfo.packageName
            val appObject = JSONObject().apply {
                put("name", appName)
                put("packageName", packageName)
            }
            apps.put(appObject)
        }
        return apps
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: ""
        return enabledListeners.contains(packageName)
    }

    private fun openNotificationListenerSettings() {
        startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"))
    }

    private fun checkPermissions(): Map<String, Boolean> {
        val postNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else true
        return mapOf(
            "notificationListener" to isNotificationListenerEnabled(),
            "postNotifications" to postNotifications
        )
    }

    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun updateEnabledAppsPrefs() {
        val enabledApps = dbHelper.getEnabledApps()
        val packageNames = enabledApps.map { it["packageName"] as String }.toSet()
        prefs.edit().putStringSet(ENABLED_APPS_KEY, packageNames).apply()
    }
}