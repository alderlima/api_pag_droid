package com.macronotify.macro_notify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context != null && intent != null) {
            val action = intent.action
            val notificationData = intent.getStringExtra("notification_data")
            Log.d("NotificationReceiver", "Ação: $action, Dados: $notificationData")
        }
    }
}
