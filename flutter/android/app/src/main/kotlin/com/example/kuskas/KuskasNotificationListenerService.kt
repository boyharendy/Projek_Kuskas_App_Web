package com.example.kuskas

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Locale

class KuskasNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "KuskasNotifListener"
        private const val CHANNEL_ID = "kuskas_transaction_alerts"
        var isAppInForeground = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        val extras = sbn.notification?.extras ?: return

        val title = extras.getString("android.title", "") ?: ""
        val text = extras.getCharSequence("android.text", "")?.toString() ?: ""

        Log.d(TAG, "Notification received from: $packageName, title: $title, text: $text")

        // Map packages to known payment providers
        val providerName = getProviderName(packageName, title) ?: return

        // Parse amount and type
        val amount = parseAmount(text) ?: parseAmount(title) ?: return
        val isIncome = determineIfIncome(title, text)
        val transactionType = if (isIncome) "income" else "expense"
        val description = if (isIncome) "Transfer Masuk $providerName" else "Pembayaran $providerName"
        val paymentMethod = if (providerName == "DANA" || providerName == "OVO" || providerName == "GoPay" || providerName == "ShopeePay") "e_wallet" else "bank_transfer"

        Log.d(TAG, "Parsed transaction - Provider: $providerName, Amount: $amount, Type: $transactionType")

        // Retrieve credentials from SharedPreferences
        val sharedPref = getSharedPreferences("kuskas_prefs", Context.MODE_PRIVATE)
        val supabaseUrl = sharedPref.getString("supabase_url", "") ?: ""
        val supabaseKey = sharedPref.getString("supabase_key", "") ?: ""
        val userId = sharedPref.getString("user_id", "") ?: ""

        // If credentials exist, upload to Supabase immediately in the background
        if (supabaseUrl.isNotEmpty() && supabaseKey.isNotEmpty() && userId.isNotEmpty()) {
            insertNotificationToSupabase(
                supabaseUrl = supabaseUrl,
                anonKey = supabaseKey,
                userId = userId,
                wallet = providerName,
                amount = amount,
                type = transactionType,
                desc = description,
                paymentMethod = paymentMethod
            )
        }

        if (isAppInForeground) {
            // App is open, broadcast to MainActivity
            sendBroadcastToApp(providerName, amount, transactionType, description)
        } else {
            // App is in background/closed, post local notification to alert user
            postLocalNotification(providerName, amount, transactionType, description)
        }
    }

    private fun getProviderName(packageName: String, title: String): String? {
        val pkg = packageName.lowercase(Locale.ROOT)
        val titleLower = title.lowercase(Locale.ROOT)

        return when {
            pkg.contains("id.dana") -> "DANA"
            pkg.contains("ovo.id") -> "OVO"
            pkg.contains("com.gojek.app") || pkg.contains("id.co.gopay.wallet") -> "GoPay"
            pkg.contains("com.seabank.id") -> "SeaBank"
            pkg.contains("com.shopee.id") || titleLower.contains("shopeepay") -> "ShopeePay"
            pkg.contains("com.bca") || pkg.contains("id.co.bca.mobile") -> "BCA"
            pkg.contains("id.co.mandiri.livin") -> "Mandiri"
            pkg.contains("id.co.bri.brimo") -> "BRI"
            pkg.contains("src.bni.mobile") -> "BNI"
            // Fallback check in title if app is not fully identified by package but is transactional
            titleLower.contains("dana") -> "DANA"
            titleLower.contains("ovo") -> "OVO"
            titleLower.contains("gopay") -> "GoPay"
            titleLower.contains("seabank") -> "SeaBank"
            titleLower.contains("shopeepay") -> "ShopeePay"
            else -> null
        }
    }

    private fun parseAmount(content: String): Double? {
        // Matches "Rp 50.000", "Rp.50.000,00", "IDR 50.000", etc.
        val amountRegex = Regex("(?i)(?:Rp|IDR)\\.?\\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?)")
        val matchResult = amountRegex.find(content) ?: return null
        val rawAmount = matchResult.groupValues[1]

        return try {
            var s = rawAmount.replace(" ", "")
            if (s.contains(",") && s.contains(".")) {
                val commaIdx = s.lastIndexOf(",")
                val dotIdx = s.lastIndexOf(".")
                s = if (commaIdx > dotIdx) {
                    s.substring(0, commaIdx).replace(".", "") + "." + s.substring(commaIdx + 1)
                } else {
                    s.substring(0, dotIdx).replace(",", "") + "." + s.substring(dotIdx + 1)
                }
            } else if (s.contains(",")) {
                val commaIdx = s.lastIndexOf(",")
                s = if (s.length - commaIdx == 3) {
                    s.substring(0, commaIdx).replace(".", "") + "." + s.substring(commaIdx + 1)
                } else {
                    s.replace(",", "")
                }
            } else if (s.contains(".")) {
                val dotIdx = s.lastIndexOf(".")
                s = if (s.length - dotIdx == 3) {
                    s.substring(0, dotIdx).replace(",", "") + "." + s.substring(dotIdx + 1)
                } else {
                    s.replace(".", "")
                }
            }
            s.toDoubleOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun determineIfIncome(title: String, text: String): Boolean {
        val combined = "$title $text".lowercase(Locale.ROOT)
        
        // Keywords signaling incoming funds
        val incomeKeywords = listOf(
            "masuk", "terima", "diterima", "ditambahkan", "top up", "topup", 
            "cashback", "refund", "kredit", "credit", "tambah", "kembalian", "incoming"
        )
        
        // Keywords signaling outgoing funds
        val expenseKeywords = listOf(
            "kirim", "keluar", "bayar", "pembayaran", "transfer ke", "berhasil kirim", 
            "debit", "debet", "tarik", "pemotongan", "belanja", "outgoing"
        )

        var score = 0
        for (kw in incomeKeywords) {
            if (combined.contains(kw)) score++
        }
        for (kw in expenseKeywords) {
            if (combined.contains(kw)) score--
        }

        // Default to income if no matching keyword (since most transaction notifications users care about are incoming alerts)
        return score >= 0
    }

    private fun sendBroadcastToApp(wallet: String, amount: Double, type: String, desc: String) {
        val intent = Intent("com.example.kuskas.NOTIFICATION_RECEIVED").apply {
            putExtra("wallet", wallet)
            putExtra("amount", amount)
            putExtra("type", type)
            putExtra("desc", desc)
        }
        sendBroadcast(intent)
    }

    private fun postLocalNotification(wallet: String, amount: Double, type: String, desc: String) {
        val context = applicationContext
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Intent to launch MainActivity and pass transaction details
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("wallet", wallet)
            putExtra("amount", amount)
            putExtra("type", type)
            putExtra("desc", desc)
            putExtra("from_notification", true)
        }

        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            System.currentTimeMillis().toInt(),
            launchIntent,
            flag
        )

        val formattedAmount = String.format("Rp %,.0f", amount).replace(",", ".")
        val directionText = if (type == "income") "masuk" else "keluar"
        val notificationTitle = "Transaksi $wallet Terdeteksi!"
        val notificationBody = "Ada dana $directionText sebesar $formattedAmount. Ketuk untuk menyimpan."

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(notificationTitle)
            .setContentText(notificationBody)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Standard generic system icon
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Pantauan Transaksi Kuskas"
            val descriptionText = "Notifikasi untuk mencatat transaksi otomatis"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun insertNotificationToSupabase(
        supabaseUrl: String,
        anonKey: String,
        userId: String,
        wallet: String,
        amount: Double,
        type: String,
        desc: String,
        paymentMethod: String
    ) {
        Thread {
            try {
                val url = java.net.URL("$supabaseUrl/rest/v1/notifications")
                val conn = url.openConnection() as java.net.HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("apikey", anonKey)
                conn.setRequestProperty("Authorization", "Bearer $anonKey")
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("Prefer", "return=minimal")
                conn.doOutput = true

                val jsonParam = org.json.JSONObject().apply {
                    put("user_id", userId)
                    put("title", "Transaksi $wallet Terdeteksi")
                    put("body", "Ada dana ${if (type == "income") "masuk" else "keluar"} sebesar Rp $amount")
                    put("wallet", wallet)
                    put("amount", amount)
                    put("type", type)
                    put("description", desc)
                    put("payment_method", paymentMethod)
                    put("is_read", false)
                    put("is_processed", false)
                }

                val os = conn.outputStream
                val writer = java.io.OutputStreamWriter(os, "UTF-8")
                writer.write(jsonParam.toString())
                writer.flush()
                writer.close()
                os.close()

                val responseCode = conn.responseCode
                Log.d(TAG, "Supabase insert response code: $responseCode")
                conn.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "Error inserting notification to Supabase", e)
            }
        }.start()
    }
}
