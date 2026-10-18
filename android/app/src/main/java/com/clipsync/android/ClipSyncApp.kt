package com.clipsync.android

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class ClipSyncApp : Application() {

    companion object {
        const val SYNC_CHANNEL_ID = "clipsync_foreground_channel"
        const val ALERT_CHANNEL_ID = "clipsync_alerts_channel"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val syncChannel = NotificationChannel(
                    SYNC_CHANNEL_ID,
                    "ClipSync Active Service",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Maintains connection with paired ClipSync devices"
                }

                val alertChannel = NotificationChannel(
                    ALERT_CHANNEL_ID,
                    "ClipSync Alerts",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Notifications for incoming files and pairing requests"
                }

                val manager = getSystemService(NotificationManager::class.java)
                manager?.createNotificationChannel(syncChannel)
                manager?.createNotificationChannel(alertChannel)
            }
        } catch (e: Exception) {
            android.util.Log.e("ClipSyncApp", "Could not create notification channels: ${e.message}", e)
        }
    }
}
