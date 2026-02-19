package com.macronotify.macro_notify

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat

class NotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        processNotification(sbn, "posted")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        processNotification(sbn, "removed")
    }

    private fun processNotification(sbn: StatusBarNotification, action: String) {
        try {
            val packageName = sbn.packageName

            // Verificar se o app está habilitado
            if (!isAppEnabled(packageName)) {
                Log.d(TAG, "App não habilitado: $packageName")
                return
            }

            val notification = sbn.notification
            val extras = notification.extras ?: return

            val title = extras.getString(NotificationCompat.EXTRA_TITLE) ?: ""
            val text = extras.getString(NotificationCompat.EXTRA_TEXT) ?: ""
            val timestamp = sbn.postTime

            val data = mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "timestamp" to timestamp
            )

            Log.d(TAG, "Notificação recebida: $data")

            // Salvar no banco de dados local
            val dbHelper = NotificationDatabaseHelper(this)
            dbHelper.insertNotification(data)

            // Enviar para o Flutter via EventChannel
            MainActivity.eventSink?.success(data)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao processar notificação", e)
        }
    }

    private fun isAppEnabled(packageName: String): Boolean {
        val prefs = getSharedPreferences("macro_notify_prefs", Context.MODE_PRIVATE)
        val enabledApps = prefs.getStringSet("enabled_apps", setOf()) ?: setOf()
        return enabledApps.contains(packageName)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Listener conectado")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Listener desconectado")
    }

    companion object {
        private const val TAG = "NotificationListener"
    }
}