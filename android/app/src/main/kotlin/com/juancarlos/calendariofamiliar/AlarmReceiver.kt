package com.juancarlos.calendariofamiliar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "⏰⏰⏰ ALARMA RECIBIDA EN ALARMRECEIVER! ⏰⏰⏰")
        Log.d("AlarmReceiver", "Action: ${intent.action}")
        Log.d("AlarmReceiver", "Extras: ${intent.extras}")
        
        // Obtener los datos del intent
        val title = intent.getStringExtra("title") ?: "Alarma"
        val notes = intent.getStringExtra("notes") ?: ""
        val dateKey = intent.getStringExtra("dateKey") ?: ""
        
        Log.d("AlarmReceiver", "Título: $title")
        Log.d("AlarmReceiver", "Notas: $notes")
        Log.d("AlarmReceiver", "Fecha: $dateKey")
        
        // Asegurar que el dispositivo esté despierto
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        val wakeLock = powerManager.newWakeLock(
            android.os.PowerManager.PARTIAL_WAKE_LOCK or 
            android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP or
            android.os.PowerManager.ON_AFTER_RELEASE,
            "AlarmReceiver::WakeLock"
        )
        wakeLock.acquire(30000) // 30 segundos
        Log.d("AlarmReceiver", "🔋 WakeLock adquirido")
        
        try {
            // Crear un intent para abrir la AlarmActivity dedicada
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                       Intent.FLAG_ACTIVITY_NO_HISTORY or
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP or
                       Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT or
                       Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("title", title)
                putExtra("notes", notes)
                putExtra("dateKey", dateKey)
                putExtra("from_alarm", true) // Marcar que viene de alarma
            }
            
            Log.d("AlarmReceiver", "Intentando lanzar AlarmActivity...")
            Log.d("AlarmReceiver", "Intent flags: ${activityIntent.flags}")
            Log.d("AlarmReceiver", "Intent component: ${activityIntent.component}")
            Log.d("AlarmReceiver", "Intent extras: ${activityIntent.extras}")
            
            context.startActivity(activityIntent)
            Log.d("AlarmReceiver", "✅✅✅ AlarmActivity lanzada exitosamente ✅✅✅")
            
            // Detener el Foreground Service ya que la alarma ya se disparó
            AlarmForegroundService.stop(context)
            Log.d("AlarmReceiver", "🔇 Foreground Service detenido")
            
            // Liberar el WakeLock
            wakeLock.release()
            Log.d("AlarmReceiver", "🔋 WakeLock liberado")
            
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "❌❌❌ ERROR lanzando AlarmActivity: ${e.message}")
            e.printStackTrace()
            
            // NO lanzar MainActivity como fallback para evitar que se abra la app principal
            Log.d("AlarmReceiver", "⚠️ No se lanzará MainActivity como fallback para mantener la alarma independiente")
            
            // Asegurar que el WakeLock se libere
            if (wakeLock.isHeld) {
                wakeLock.release()
                Log.d("AlarmReceiver", "🔋 WakeLock liberado en finally")
            }
        }
    }
}

