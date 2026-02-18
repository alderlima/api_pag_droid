package com.macronotify.macro_notify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device boot completed, iniciando NotificationListener")
            // O NotificationListener será iniciado automaticamente pelo sistema
            // quando o usuário ativar a permissão nas configurações
        }
    }
}
