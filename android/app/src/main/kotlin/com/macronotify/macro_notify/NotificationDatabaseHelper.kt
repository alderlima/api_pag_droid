package com.macronotify.macro_notify

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log
import org.json.JSONObject

class NotificationDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val TAG = "NotificationDB"
        private const val DATABASE_NAME = "macro_notify.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_NOTIFICATIONS = "notifications"
        private const val TABLE_ENABLED_APPS = "enabled_apps"

        // Colunas da tabela notifications
        private const val COLUMN_ID = "id"
        private const val COLUMN_PACKAGE_NAME = "package_name"
        private const val COLUMN_TITLE = "title"
        private const val COLUMN_TEXT = "text"
        private const val COLUMN_SUB_TEXT = "sub_text"
        private const val COLUMN_BIG_TEXT = "big_text"
        private const val COLUMN_KEY = "notification_key"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_ACTION = "action"
        private const val COLUMN_NOTIFICATION_ID = "notification_id"
        private const val COLUMN_RAW_DATA = "raw_data"
        private const val COLUMN_IS_ACTIVE = "is_active"

        // Colunas da tabela enabled_apps
        private const val COLUMN_APP_PACKAGE = "package_name"
        private const val COLUMN_APP_NAME = "app_name"
        private const val COLUMN_APP_ENABLED = "is_enabled"
    }

    override fun onCreate(db: SQLiteDatabase) {
        try {
            // Criar tabela de notificações
            val createNotificationsTable = """
                CREATE TABLE IF NOT EXISTS $TABLE_NOTIFICATIONS (
                    $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                    $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                    $COLUMN_TITLE TEXT,
                    $COLUMN_TEXT TEXT,
                    $COLUMN_SUB_TEXT TEXT,
                    $COLUMN_BIG_TEXT TEXT,
                    $COLUMN_KEY TEXT UNIQUE,
                    $COLUMN_TIMESTAMP INTEGER NOT NULL,
                    $COLUMN_ACTION TEXT,
                    $COLUMN_NOTIFICATION_ID INTEGER,
                    $COLUMN_RAW_DATA TEXT,
                    $COLUMN_IS_ACTIVE INTEGER DEFAULT 1
                )
            """.trimIndent()

            // Criar tabela de apps habilitados
            val createEnabledAppsTable = """
                CREATE TABLE IF NOT EXISTS $TABLE_ENABLED_APPS (
                    $COLUMN_APP_PACKAGE TEXT PRIMARY KEY,
                    $COLUMN_APP_NAME TEXT NOT NULL,
                    $COLUMN_APP_ENABLED INTEGER DEFAULT 1
                )
            """.trimIndent()

            db.execSQL(createNotificationsTable)
            db.execSQL(createEnabledAppsTable)

            Log.d(TAG, "Tabelas criadas com sucesso")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao criar tabelas: ${e.message}", e)
        }
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        try {
            db.execSQL("DROP TABLE IF EXISTS $TABLE_NOTIFICATIONS")
            db.execSQL("DROP TABLE IF EXISTS $TABLE_ENABLED_APPS")
            onCreate(db)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao fazer upgrade do banco: ${e.message}", e)
        }
    }

    fun insertNotification(rawData: String) {
        try {
            val db = writableDatabase
            val data = JSONObject(rawData)

            val values = android.content.ContentValues().apply {
                put(COLUMN_PACKAGE_NAME, data.optString("packageName", ""))
                put(COLUMN_TITLE, data.optString("title", ""))
                put(COLUMN_TEXT, data.optString("text", ""))
                put(COLUMN_SUB_TEXT, data.optString("subText", ""))
                put(COLUMN_BIG_TEXT, data.optString("bigText", ""))
                put(COLUMN_KEY, data.optString("key", ""))
                put(COLUMN_TIMESTAMP, data.optLong("timestamp", System.currentTimeMillis()))
                put(COLUMN_ACTION, data.optString("action", "posted"))
                put(COLUMN_NOTIFICATION_ID, data.optInt("id", 0))
                put(COLUMN_RAW_DATA, rawData)
                put(COLUMN_IS_ACTIVE, 1)
            }

            db.insert(TABLE_NOTIFICATIONS, null, values)
            Log.d(TAG, "Notificação inserida com sucesso")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao inserir notificação: ${e.message}", e)
        }
    }

    fun getNotifications(limit: Int = 100): List<Map<String, Any>> {
        val notifications = mutableListOf<Map<String, Any>>()
        try {
            val db = readableDatabase
            val cursor = db.query(
                TABLE_NOTIFICATIONS,
                null,
                null,
                null,
                null,
                null,
                "$COLUMN_TIMESTAMP DESC",
                limit.toString()
            )

            cursor.use {
                while (it.moveToNext()) {
                    val notification = mapOf(
                        "id" to it.getLong(it.getColumnIndexOrThrow(COLUMN_ID)),
                        "packageName" to it.getString(it.getColumnIndexOrThrow(COLUMN_PACKAGE_NAME)),
                        "title" to it.getString(it.getColumnIndexOrThrow(COLUMN_TITLE)),
                        "text" to it.getString(it.getColumnIndexOrThrow(COLUMN_TEXT)),
                        "subText" to it.getString(it.getColumnIndexOrThrow(COLUMN_SUB_TEXT)),
                        "bigText" to it.getString(it.getColumnIndexOrThrow(COLUMN_BIG_TEXT)),
                        "timestamp" to it.getLong(it.getColumnIndexOrThrow(COLUMN_TIMESTAMP)),
                        "action" to it.getString(it.getColumnIndexOrThrow(COLUMN_ACTION)),
                        "isActive" to it.getInt(it.getColumnIndexOrThrow(COLUMN_IS_ACTIVE))
                    )
                    notifications.add(notification)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao buscar notificações: ${e.message}", e)
        }
        return notifications
    }

    fun deleteNotification(id: Long) {
        try {
            val db = writableDatabase
            db.delete(TABLE_NOTIFICATIONS, "$COLUMN_ID = ?", arrayOf(id.toString()))
            Log.d(TAG, "Notificação deletada: $id")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao deletar notificação: ${e.message}", e)
        }
    }

    fun clearAllNotifications() {
        try {
            val db = writableDatabase
            db.delete(TABLE_NOTIFICATIONS, null, null)
            Log.d(TAG, "Todas as notificações foram limpas")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao limpar notificações: ${e.message}", e)
        }
    }

    fun addEnabledApp(packageName: String, appName: String) {
        try {
            val db = writableDatabase
            val values = android.content.ContentValues().apply {
                put(COLUMN_APP_PACKAGE, packageName)
                put(COLUMN_APP_NAME, appName)
                put(COLUMN_APP_ENABLED, 1)
            }
            db.insertWithOnConflict(TABLE_ENABLED_APPS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
            Log.d(TAG, "App habilitado: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao habilitar app: ${e.message}", e)
        }
    }

    fun removeEnabledApp(packageName: String) {
        try {
            val db = writableDatabase
            db.delete(TABLE_ENABLED_APPS, "$COLUMN_APP_PACKAGE = ?", arrayOf(packageName))
            Log.d(TAG, "App desabilitado: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao desabilitar app: ${e.message}", e)
        }
    }

    fun getEnabledApps(): List<Map<String, String>> {
        val apps = mutableListOf<Map<String, String>>()
        try {
            val db = readableDatabase
            val cursor = db.query(
                TABLE_ENABLED_APPS,
                null,
                "$COLUMN_APP_ENABLED = ?",
                arrayOf("1"),
                null,
                null,
                null
            )

            cursor.use {
                while (it.moveToNext()) {
                    val app = mapOf(
                        "packageName" to it.getString(it.getColumnIndexOrThrow(COLUMN_APP_PACKAGE)),
                        "appName" to it.getString(it.getColumnIndexOrThrow(COLUMN_APP_NAME))
                    )
                    apps.add(app)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao buscar apps habilitados: ${e.message}", e)
        }
        return apps
    }
}
