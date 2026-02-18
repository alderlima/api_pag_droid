package com.macronotify.macro_notify

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL_ID = "macro_notify_channel"
        private const val PREFS_NAME = "macro_notify_prefs"
        private const val ENABLED_APPS_KEY = "enabled_apps"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn != null) {
            handleNotification(sbn, "posted")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        if (sbn != null) {
            handleNotification(sbn, "removed")
        }
    }

    private fun handleNotification(sbn: StatusBarNotification, action: String) {
        try {
            val packageName = sbn.packageName
            val notification = sbn.notification
            val key = sbn.key
            val postTime = sbn.postTime

            // Verificar se o app está habilitado para monitoramento
            if (!isAppEnabled(packageName)) {
                Log.d(TAG, "App $packageName não está habilitado para monitoramento")
                return
            }

            // Extrair informações da notificação
            val title = extractTitle(notification)
            val text = extractText(notification)
            val subText = extractSubText(notification)
            val bigText = extractBigText(notification)

            // Criar objeto JSON com os dados
            val notificationData = JSONObject().apply {
                put("packageName", packageName)
                put("title", title)
                put("text", text)
                put("subText", subText)
                put("bigText", bigText)
                put("key", key)
                put("postTime", postTime)
                put("timestamp", System.currentTimeMillis())
                put("action", action)
                put("id", sbn.id)
            }

            Log.d(TAG, "Notificação capturada: $notificationData")

            // Salvar no banco de dados
            saveNotificationToDatabase(notificationData.toString())

            // Enviar para Flutter via método channel
            sendToFlutter(notificationData)

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao processar notificação: ${e.message}", e)
        }
    }

    private fun extractTitle(notification: android.app.Notification): String {
        return try {
            val extras = notification.extras
            extras.getString(android.app.Notification.EXTRA_TITLE, "")
        } catch (e: Exception) {
            ""
        }
    }

    private fun extractText(notification: android.app.Notification): String {
        return try {
            val extras = notification.extras
            extras.getString(android.app.Notification.EXTRA_TEXT, "")
        } catch (e: Exception) {
            ""
        }
    }

    private fun extractSubText(notification: android.app.Notification): String {
        return try {
            val extras = notification.extras
            extras.getString(android.app.Notification.EXTRA_SUB_TEXT, "")
        } catch (e: Exception) {
            ""
        }
    }

    private fun extractBigText(notification: android.app.Notification): String {
        return try {
            val extras = notification.extras
            extras.getString(android.app.Notification.EXTRA_BIG_TEXT, "")
        } catch (e: Exception) {
            ""
        }
    }

    private fun isAppEnabled(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val enabledApps = prefs.getStringSet(ENABLED_APPS_KEY, setOf()) ?: setOf()
        return enabledApps.contains(packageName)
    }

    private fun saveNotificationToDatabase(data: String) {
        try {
            val dbHelper = NotificationDatabaseHelper(this)
            dbHelper.insertNotification(data)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao salvar notificação no banco: ${e.message}", e)
        }
    }

    private fun sendToFlutter(data: JSONObject) {
        try {
            val intent = Intent("com.macronotify.NOTIFICATION_RECEIVED")
            intent.putExtra("notification_data", data.toString())
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar para Flutter: ${e.message}", e)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener conectado")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListener desconectado")
    }
}
