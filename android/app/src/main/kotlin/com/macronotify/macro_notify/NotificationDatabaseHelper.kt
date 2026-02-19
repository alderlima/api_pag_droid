package com.macronotify.macro_notify

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class NotificationDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "macro_notify.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_NOTIFICATIONS = "notifications"
        private const val TABLE_ENABLED_APPS = "enabled_apps"

        private const val COLUMN_ID = "id"
        private const val COLUMN_PACKAGE_NAME = "package_name"
        private const val COLUMN_TITLE = "title"
        private const val COLUMN_TEXT = "text"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_ACTION = "action"
        private const val COLUMN_IS_ACTIVE = "is_active"

        private const val COLUMN_APP_PACKAGE = "package_name"
        private const val COLUMN_APP_NAME = "app_name"
        private const val COLUMN_APP_ENABLED = "is_enabled"
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_NOTIFICATIONS (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                $COLUMN_TITLE TEXT,
                $COLUMN_TEXT TEXT,
                $COLUMN_TIMESTAMP INTEGER NOT NULL,
                $COLUMN_ACTION TEXT,
                $COLUMN_IS_ACTIVE INTEGER DEFAULT 1
            )
        """)

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_ENABLED_APPS (
                $COLUMN_APP_PACKAGE TEXT PRIMARY KEY,
                $COLUMN_APP_NAME TEXT NOT NULL,
                $COLUMN_APP_ENABLED INTEGER DEFAULT 1
            )
        """)
        Log.d("NotificationDB", "Tabelas criadas")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_NOTIFICATIONS")
        db.execSQL("DROP TABLE IF EXISTS $TABLE_ENABLED_APPS")
        onCreate(db)
    }

    fun insertNotification(data: Map<String, Any>) {
        try {
            val db = writableDatabase
            val values = ContentValues().apply {
                put(COLUMN_PACKAGE_NAME, data["packageName"] as? String ?: "")
                put(COLUMN_TITLE, data["title"] as? String ?: "")
                put(COLUMN_TEXT, data["text"] as? String ?: "")
                put(COLUMN_TIMESTAMP, data["timestamp"] as? Long ?: System.currentTimeMillis())
                put(COLUMN_ACTION, data["action"] as? String ?: "posted")
                put(COLUMN_IS_ACTIVE, 1)
            }
            db.insert(TABLE_NOTIFICATIONS, null, values)
            Log.d("NotificationDB", "Notificação inserida")
        } catch (e: Exception) {
            Log.e("NotificationDB", "Erro ao inserir notificação", e)
        }
    }

    fun getNotifications(limit: Int = 100): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val db = readableDatabase
        val cursor = db.query(
            TABLE_NOTIFICATIONS,
            null, null, null, null, null,
            "$COLUMN_TIMESTAMP DESC",
            limit.toString()
        )
        cursor.use {
            val idIdx = it.getColumnIndexOrThrow(COLUMN_ID)
            val pkgIdx = it.getColumnIndexOrThrow(COLUMN_PACKAGE_NAME)
            val titleIdx = it.getColumnIndexOrThrow(COLUMN_TITLE)
            val textIdx = it.getColumnIndexOrThrow(COLUMN_TEXT)
            val tsIdx = it.getColumnIndexOrThrow(COLUMN_TIMESTAMP)
            val actionIdx = it.getColumnIndexOrThrow(COLUMN_ACTION)
            val activeIdx = it.getColumnIndexOrThrow(COLUMN_IS_ACTIVE)

            while (it.moveToNext()) {
                list.add(mapOf(
                    "id" to it.getLong(idIdx),
                    "packageName" to it.getString(pkgIdx),
                    "title" to it.getString(titleIdx),
                    "text" to it.getString(textIdx),
                    "timestamp" to it.getLong(tsIdx),
                    "action" to it.getString(actionIdx),
                    "isActive" to it.getInt(activeIdx)
                ))
            }
        }
        return list
    }

    fun deleteNotification(id: Long) {
        writableDatabase.delete(TABLE_NOTIFICATIONS, "$COLUMN_ID = ?", arrayOf(id.toString()))
    }

    fun clearAllNotifications() {
        writableDatabase.delete(TABLE_NOTIFICATIONS, null, null)
    }

    fun addEnabledApp(packageName: String, appName: String) {
        val values = ContentValues().apply {
            put(COLUMN_APP_PACKAGE, packageName)
            put(COLUMN_APP_NAME, appName)
            put(COLUMN_APP_ENABLED, 1)
        }
        writableDatabase.insertWithOnConflict(TABLE_ENABLED_APPS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun removeEnabledApp(packageName: String) {
        writableDatabase.delete(TABLE_ENABLED_APPS, "$COLUMN_APP_PACKAGE = ?", arrayOf(packageName))
    }

    fun getEnabledApps(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val cursor = readableDatabase.query(
            TABLE_ENABLED_APPS,
            null, "$COLUMN_APP_ENABLED = ?", arrayOf("1"), null, null, null
        )
        cursor.use {
            val pkgIdx = it.getColumnIndexOrThrow(COLUMN_APP_PACKAGE)
            val nameIdx = it.getColumnIndexOrThrow(COLUMN_APP_NAME)
            while (it.moveToNext()) {
                list.add(mapOf(
                    "packageName" to it.getString(pkgIdx),
                    "appName" to it.getString(nameIdx)
                ))
            }
        }
        return list
    }
}