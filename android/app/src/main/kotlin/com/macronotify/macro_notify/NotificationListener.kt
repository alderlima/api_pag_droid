package com.macronotify.macro_notify

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Listener conectado")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Listener desconectado")
    }

    private fun bundleToJson(bundle: Bundle?): JSONObject {
        val json = JSONObject()
        if (bundle == null) return json
        
        for (key in bundle.keySet()) {
            try {
                val value = bundle.get(key)
                when (value) {
                    is Bundle -> json.put(key, bundleToJson(value))
                    is CharSequence -> json.put(key, value.toString())
                    is Array<*> -> {
                        val jsonArray = JSONArray()
                        for (item in value) {
                            jsonArray.put(item?.toString())
                        }
                        json.put(key, jsonArray)
                    }
                    // Tratamento para arrays de tipos primitivos comuns em Bundles
                    is LongArray -> {
                        val jsonArray = JSONArray()
                        value.forEach { jsonArray.put(it) }
                        json.put(key, jsonArray)
                    }
                    is IntArray -> {
                        val jsonArray = JSONArray()
                        value.forEach { jsonArray.put(it) }
                        json.put(key, jsonArray)
                    }
                    else -> json.put(key, value)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao converter Bundle para JSON para a chave: $key", e)
            }
        }
        return json
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        processNotification(sbn, "posted")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        processNotification(sbn, "removed")
    }

    private fun processNotification(sbn: StatusBarNotification, action: String) {
        try {
            val notification = sbn.notification

            val fullNotificationJson = JSONObject().apply {
                put("package", sbn.packageName)
                put("id", sbn.id)
                put("tag", sbn.tag)
                put("postTime", sbn.postTime)
                put("action", action) // Adicionado para saber se foi postada ou removida
                put("channelId", notification.channelId)
                put("category", notification.category)
                put("extras", bundleToJson(notification.extras))

                val actionsArray = JSONArray()
                notification.actions?.forEach { act ->
                    val actionJson = JSONObject().apply {
                        put("title", act.title?.toString())
                    }
                    actionsArray.put(actionJson)
                }
                put("actions", actionsArray)
            }

            Log.d(TAG, "Notificação DEBUG JSON: $fullNotificationJson")

            // Enviar para o Flutter via EventChannel
            eventSink?.success(fullNotificationJson.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao processar notificação", e)
        }
    }
}
