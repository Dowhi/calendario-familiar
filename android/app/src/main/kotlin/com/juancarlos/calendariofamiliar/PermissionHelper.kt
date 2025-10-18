package com.juancarlos.calendariofamiliar

import android.app.Activity
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

object PermissionHelper {
    private const val TAG = "PermissionHelper"
    
    fun checkAndRequestCriticalPermissions(activity: Activity) {
        Log.d(TAG, "🔍 Verificando permisos críticos para alarmas...")
        
        // 1. Verificar permisos de alarmas exactas
        checkExactAlarmPermission(activity)
        
        // 2. Verificar optimización de batería
        BatteryOptimizationHelper.requestBatteryOptimizationExclusion(activity)
        
        // 3. Verificar permisos de notificaciones
        checkNotificationPermission(activity)
        
        // 4. Verificar permisos de ventana sobre otras apps
        checkOverlayPermission(activity)
    }
    
    private fun checkExactAlarmPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val canScheduleExactAlarms = alarmManager.canScheduleExactAlarms()
            
            Log.d(TAG, "📅 Permisos de alarmas exactas: $canScheduleExactAlarms")
            
            if (!canScheduleExactAlarms) {
                Log.w(TAG, "⚠️ Solicitando permisos de alarmas exactas...")
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    activity.startActivity(intent)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error abriendo configuración de alarmas: ${e.message}")
                }
            }
        }
    }
    
    private fun checkNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Para Android 13+ se necesita permiso explícito
            Log.d(TAG, "📱 Verificando permisos de notificaciones para Android 13+")
            // Este permiso se maneja automáticamente por Flutter
        }
    }
    
    private fun checkOverlayPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(activity)) {
                Log.w(TAG, "⚠️ Solicitando permisos de ventana sobre otras apps...")
                try {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}")
                    )
                    activity.startActivity(intent)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error abriendo configuración de overlay: ${e.message}")
                }
            } else {
                Log.d(TAG, "✅ Permisos de overlay ya concedidos")
            }
        }
    }
}
