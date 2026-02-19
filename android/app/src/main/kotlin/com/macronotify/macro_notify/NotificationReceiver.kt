package com.macronotify.macro_notify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject

/**
 * BroadcastReceiver que recebe notificacoes do NotificationListener
 * e as processa para confirmar pagamentos PIX
 *
 * Fluxo:
 * 1. NotificationListener captura notificacao
 * 2. Envia broadcast com dados da notificacao
 * 3. NotificationReceiver recebe e extrai dados
 * 4. Flutter recebe via MethodChannel
 * 5. NotificationProcessor processa e envia para backend
 */
class NotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NotificationReceiver"
        private const val ACTION_NOTIFICATION = "com.macronotify.NOTIFICATION_RECEIVED"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        try {
            if (context == null || intent == null) return

            if (intent.action != ACTION_NOTIFICATION) {
                Log.d(TAG, "Intent ignorada: ${intent.action}")
                return
            }

            val notificationData = intent.getStringExtra("notification_data") ?: return
            Log.d(TAG, "Notificacao recebida via broadcast")

            // Parse dos dados
            val jsonData = JSONObject(notificationData)
            val packageName = jsonData.getString("packageName")
            val title = jsonData.getString("title")
            val text = jsonData.getString("text")
            val postTime = jsonData.getLong("postTime")

            Log.d(TAG, "Dados extraidos:")
            Log.d(TAG, "  - Package: $packageName")
            Log.d(TAG, "  - Title: $title")
            Log.d(TAG, "  - Text: ${text.take(50)}...")

            // Nota: O processamento real eh feito no Flutter
            // via NotificationProcessor que chama PaymentService
            // para enviar para o backend

        } catch (e: Exception) {
            Log.e(TAG, "Erro ao processar notificacao: ${e.message}", e)
        }
    }
}
