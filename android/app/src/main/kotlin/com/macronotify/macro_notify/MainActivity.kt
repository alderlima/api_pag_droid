package com.macronotify.macro_notify

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.macronotify.macro_notify/notifications"
        private const val TAG = "MainActivity"
        private const val PREFS_NAME = "macro_notify_prefs"
        private const val ENABLED_APPS_KEY = "enabled_apps"
    }

    private lateinit var channel: MethodChannel
    private lateinit var dbHelper: NotificationDatabaseHelper
    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        dbHelper = NotificationDatabaseHelper(this)
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
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
                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannel configurado com sucesso")
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: ""
        val packageName = packageName
        return enabledListeners.contains(packageName)
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        startActivity(intent)
    }

    private fun checkPermissions(): Map<String, Boolean> {
        return mapOf(
            "notificationListener" to isNotificationListenerEnabled(),
            "postNotifications" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                    checkSelfPermission("android.permission.POST_NOTIFICATIONS") == android.content.pm.PackageManager.PERMISSION_GRANTED)
        )
    }

    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(
                arrayOf("android.permission.POST_NOTIFICATIONS"),
                1001
            )
        }
    }

    private fun updateEnabledAppsPrefs() {
        val enabledApps = dbHelper.getEnabledApps()
        val packageNames = enabledApps.map { it["packageName"] ?: "" }.toSet()
        prefs.edit().putStringSet(ENABLED_APPS_KEY, packageNames).apply()
        Log.d(TAG, "Apps habilitados atualizados: $packageNames")
    }
}
