package com.juancarlos.calendariofamiliar

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "alarm_service_channel"
        private const val NOTIFICATION_ID = 9999
        
        fun start(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d("AlarmForegroundService", "✅ Servicio iniciado")
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java)
            context.stopService(intent)
            Log.d("AlarmForegroundService", "⏹️ Servicio detenido")
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d("AlarmForegroundService", "🚀 onCreate()")
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AlarmForegroundService", "▶️ onStartCommand()")
        
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        Log.d("AlarmForegroundService", "✅ Servicio en foreground activo")
        
        // START_STICKY asegura que el servicio se reinicie si es matado
        // START_REDELIVER_INTENT asegura que los intents se redelivieren
        return START_STICKY
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d("AlarmForegroundService", "⚠️ onTaskRemoved() - App removida del recents")
        // No detener el servicio cuando la app se remueve del recents
        // Esto mantiene el servicio activo en background
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Servicio de Alarmas",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mantiene las alarmas activas"
                setShowBadge(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
            Log.d("AlarmForegroundService", "✅ Canal de notificación creado")
        }
    }
    
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🔔 Calendario Familiar - Alarmas Activas")
            .setContentText("Las alarmas están funcionando en segundo plano")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("AlarmForegroundService", "💀 onDestroy()")
    }
}

