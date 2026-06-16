package com.example.kuskas

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kuskas/notification_listener"
    private var methodChannel: MethodChannel? = null
    
    // Hold temporary transaction if launched from notification
    private var launchTransaction: Map<String, Any>? = null

    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val wallet = intent?.getStringExtra("wallet") ?: return
            val amount = intent.getDoubleExtra("amount", 0.0)
            val type = intent.getStringExtra("type") ?: "income"
            val desc = intent.getStringExtra("desc") ?: ""

            val transactionMap = mapOf(
                "wallet" to wallet,
                "amount" to amount,
                "type" to type,
                "desc" to desc
            )
            // Send to Flutter in real-time
            methodChannel?.invokeMethod("onTransactionDetected", transactionMap)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "getLaunchTransaction" -> {
                    result.success(launchTransaction)
                    launchTransaction = null // Clear after fetch
                }
                "syncCredentials" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val url = arguments?.get("url") as? String ?: ""
                    val key = arguments?.get("key") as? String ?: ""
                    val userId = arguments?.get("userId") as? String ?: ""
                    
                    val sharedPref = getSharedPreferences("kuskas_prefs", Context.MODE_PRIVATE)
                    with (sharedPref.edit()) {
                        putString("supabase_url", url)
                        putString("supabase_key", key)
                        putString("user_id", userId)
                        apply()
                    }
                    result.success(true)
                }
                "scheduleReminder" -> {
                    val arguments = call.arguments as? Map<*, *>
                    val hour = arguments?.get("hour") as? Int ?: 20
                    val minute = arguments?.get("minute") as? Int ?: 0
                    scheduleReminder(hour, minute)
                    result.success(true)
                }
                "cancelReminder" -> {
                    cancelReminder()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Check if launched with notification extras initially
        intent?.let { handleLaunchIntent(it) }
    }

    override fun onResume() {
        super.onResume()
        KuskasNotificationListenerService.isAppInForeground = true
        // Register receiver for real-time foreground updates
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationReceiver, IntentFilter("com.example.kuskas.NOTIFICATION_RECEIVED"), RECEIVER_EXPORTED)
        } else {
            registerReceiver(notificationReceiver, IntentFilter("com.example.kuskas.NOTIFICATION_RECEIVED"))
        }
    }

    override fun onPause() {
        super.onPause()
        KuskasNotificationListenerService.isAppInForeground = false
        // Unregister receiver
        try {
            unregisterReceiver(notificationReceiver)
        } catch (e: Exception) {
            // Ignore
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLaunchIntent(intent)
    }

    private fun handleLaunchIntent(intent: Intent) {
        if (intent.getBooleanExtra("from_notification", false)) {
            val wallet = intent.getStringExtra("wallet") ?: return
            val amount = intent.getDoubleExtra("amount", 0.0)
            val type = intent.getStringExtra("type") ?: "income"
            val desc = intent.getStringExtra("desc") ?: ""

            val transactionMap = mapOf(
                "wallet" to wallet,
                "amount" to amount,
                "type" to type,
                "desc" to desc
            )
            
            launchTransaction = transactionMap
            // If MethodChannel is already up, trigger it directly as well
            methodChannel?.invokeMethod("onTransactionDetected", transactionMap)
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":")
            for (name in names) {
                val cn = android.content.ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        } else {
            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun scheduleReminder(hour: Int, minute: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = Intent(this, KuskasReminderReceiver::class.java)
        
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(this, 1001, intent, flag)

        // Set alarm time
        val calendar = java.util.Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
            
            // If the time is in the past, schedule for tomorrow
            if (timeInMillis <= System.currentTimeMillis()) {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
            }
        }

        // Schedule daily repeating alarm
        alarmManager.setRepeating(
            android.app.AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            android.app.AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
        
        android.util.Log.d("KuskasReminder", "Reminder scheduled at $hour:$minute (repeating daily)")
    }

    private fun cancelReminder() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = Intent(this, KuskasReminderReceiver::class.java)
        
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(this, 1001, intent, flag)
        
        alarmManager.cancel(pendingIntent)
        android.util.Log.d("KuskasReminder", "Reminder cancelled")
    }
}
