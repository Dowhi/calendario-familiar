package com.juancarlos.calendariofamiliar

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

object BatteryOptimizationHelper {
    
    fun isBatteryOptimizationDisabled(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true // En versiones anteriores no hay optimización de batería
        }
    }
    
    fun requestBatteryOptimizationExclusion(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!isBatteryOptimizationDisabled(context)) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:${context.packageName}")
                    }
                    context.startActivity(intent)
                    Log.d("BatteryOptimizationHelper", "✅ Solicitando exclusión de optimización de batería")
                } catch (e: Exception) {
                    Log.e("BatteryOptimizationHelper", "❌ Error solicitando exclusión: ${e.message}")
                    // Fallback: abrir configuración general de batería
                    try {
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        context.startActivity(fallbackIntent)
                    } catch (e2: Exception) {
                        Log.e("BatteryOptimizationHelper", "❌ Error con fallback: ${e2.message}")
                    }
                }
            } else {
                Log.d("BatteryOptimizationHelper", "✅ La app ya está excluida de la optimización de batería")
            }
        }
    }
    
    fun openBatterySettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            context.startActivity(intent)
            Log.d("BatteryOptimizationHelper", "✅ Abriendo configuración de batería")
        } catch (e: Exception) {
            Log.e("BatteryOptimizationHelper", "❌ Error abriendo configuración de batería: ${e.message}")
        }
    }
}
