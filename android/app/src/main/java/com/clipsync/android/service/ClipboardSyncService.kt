package com.clipsync.android.service

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.clipsync.android.ClipSyncApp
import com.clipsync.android.MainActivity
import com.clipsync.android.protocol.ProtocolEngine

class ClipboardSyncService : Service() {

    private lateinit var clipboardManager: ClipboardManager
    private var lastSyncedHash: String? = null
    private var lastSyncTimestamp: Long = 0L
    private val suppressionWindowMs: Long = 750L

    private val clipListener = ClipboardManager.OnPrimaryClipChangedListener {
        handleClipboardChange()
    }

    override fun onCreate() {
        super.onCreate()
        try {
            val cm = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            if (cm != null) {
                clipboardManager = cm
                clipboardManager.addPrimaryClipChangedListener(clipListener)
            }
        } catch (e: Exception) {
            android.util.Log.e("ClipboardSyncService", "Failed to register clipListener: ${e.message}", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val notification = createNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    1001,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(1001, notification)
            }
        } catch (e: Exception) {
            android.util.Log.e("ClipboardSyncService", "startForeground failed: ${e.message}", e)
        }
        return START_STICKY
    }

    private fun handleClipboardChange() {
        try {
            if (!::clipboardManager.isInitialized) return
            val clip = clipboardManager.primaryClip ?: return
            if (clip.itemCount == 0) return

            val item = clip.getItemAt(0)
            val text = item.text?.toString() ?: return

            // 1. Loop Prevention check: ignore if within programmatic paste suppression window
            val now = System.currentTimeMillis()
            if (now - lastSyncTimestamp < suppressionWindowMs) {
                return
            }

            // 2. Hash comparison: ignore if identical to last synced payload
            val contentHash = ProtocolEngine.sha256(text)
            if (contentHash == lastSyncedHash) {
                return
            }

            // 3. Sensitive Content Check
            val isSensitive = ProtocolEngine.isSensitiveContent(text)

            // Update local tracking
            lastSyncedHash = contentHash
            lastSyncTimestamp = now

            // Broadcast to application listeners (without logging secret payload content)
            val syncIntent = Intent("com.clipsync.CLIPBOARD_CHANGED").apply {
                putExtra("content_hash", contentHash)
                putExtra("is_sensitive", isSensitive)
                putExtra("length", text.length)
            }
            sendBroadcast(syncIntent)
        } catch (e: Exception) {
            android.util.Log.e("ClipboardSyncService", "Error handling clipboard change: ${e.message}", e)
        }
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, ClipSyncApp.SYNC_CHANNEL_ID)
            .setContentTitle("ClipSync Active")
            .setContentText("Monitoring clipboard for seamless sync with paired devices")
            .setSmallIcon(android.R.drawable.ic_menu_share)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (::clipboardManager.isInitialized) {
                clipboardManager.removePrimaryClipChangedListener(clipListener)
            }
        } catch (e: Exception) {
            android.util.Log.e("ClipboardSyncService", "Failed to remove clipListener: ${e.message}", e)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
