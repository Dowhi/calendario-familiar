package com.juancarlos.calendariofamiliar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.juancarlos.calendariofamiliar/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    try {
                        val alarmTime = call.argument<Long>("alarmTime") ?: 0L
                        val eventText = call.argument<String>("eventText") ?: "Evento"
                        
                        AlarmService.scheduleAlarm(this, alarmTime, eventText)
                        result.success("Alarma programada exitosamente")
                        println("🔔 MethodChannel: Alarma programada para ${java.util.Date(alarmTime)}")
                    } catch (e: Exception) {
                        result.error("ERROR", "Error programando alarma: ${e.message}", null)
                        println("❌ MethodChannel Error: ${e.message}")
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
