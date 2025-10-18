package com.juancarlos.calendariofamiliar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d("BootReceiver", "🚀 Sistema reiniciado o app actualizada")
                Log.d("BootReceiver", "📱 Reprogramando alarmas...")
                
                // Aquí podrías reprogramar las alarmas desde una base de datos local
                // Por ahora solo logueamos que el sistema se reinició
                Log.d("BootReceiver", "✅ BootReceiver ejecutado correctamente")
            }
        }
    }
}
