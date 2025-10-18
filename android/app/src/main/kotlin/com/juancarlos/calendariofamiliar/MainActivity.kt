package com.juancarlos.calendariofamiliar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.juancarlos.calendariofamiliar/alarm"
    private val EVENT_CHANNEL = "com.juancarlos.calendariofamiliar/alarm_events"
    private val FOREGROUND_SERVICE_CHANNEL = "com.juancarlos.calendariofamiliar/foreground_service"
    private var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        
        // Solo verificar permisos críticos sin solicitar automáticamente
        // PermissionHelper.checkAndRequestCriticalPermissions(this)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        val route = intent.getStringExtra("route")
        if (route == "/alarm") {
            val title = intent.getStringExtra("title") ?: "Alarma"
            val notes = intent.getStringExtra("notes") ?: ""
            val dateKey = intent.getStringExtra("dateKey") ?: ""
            
            Log.d("MainActivity", "🔔 Recibido intent de alarma: $title")
            
            // Si Flutter ya está listo, enviar evento inmediatamente
            eventSink?.let { sink ->
                val data = mapOf(
                    "title" to title,
                    "notes" to notes,
                    "dateKey" to dateKey
                )
                sink.success(data)
                Log.d("MainActivity", "✅ Evento de alarma enviado a Flutter vía EventChannel")
            } ?: run {
                // Si no, guardar para después
                intent.putExtra("alarm_title", title)
                intent.putExtra("alarm_notes", notes)
                intent.putExtra("alarm_dateKey", dateKey)
                Log.d("MainActivity", "⚠️ EventChannel no listo, guardando datos para después")
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configurar EventChannel para eventos de alarma en tiempo real
        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    eventSink = events
                    Log.d("MainActivity", "✅ EventChannel conectado, enviando datos pendientes si existen")
                    
                    // Si hay datos pendientes del intent, enviarlos ahora
                    val title = intent.getStringExtra("alarm_title")
                    if (title != null) {
                        val data = mapOf(
                            "title" to title,
                            "notes" to (intent.getStringExtra("alarm_notes") ?: ""),
                            "dateKey" to (intent.getStringExtra("alarm_dateKey") ?: "")
                        )
                        events?.success(data)
                        Log.d("MainActivity", "✅ Datos pendientes enviados vía EventChannel")
                        
                        // Limpiar
                        intent.removeExtra("alarm_title")
                        intent.removeExtra("alarm_notes")
                        intent.removeExtra("alarm_dateKey")
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d("MainActivity", "❌ EventChannel desconectado")
                }
            }
        )
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarmData" -> {
                    val title = intent.getStringExtra("alarm_title")
                    val notes = intent.getStringExtra("alarm_notes")
                    val dateKey = intent.getStringExtra("alarm_dateKey")
                    
                    if (title != null) {
                        val data = mapOf(
                            "title" to title,
                            "notes" to (notes ?: ""),
                            "dateKey" to (dateKey ?: "")
                        )
                        result.success(data)
                        
                        // Limpiar los datos después de enviarlos
                        intent.removeExtra("alarm_title")
                        intent.removeExtra("alarm_notes")
                        intent.removeExtra("alarm_dateKey")
                    } else {
                        result.success(null)
                    }
                }
                "scheduleDirectAlarm" -> {
                    val triggerTimeMillis = call.argument<Long>("triggerTimeMillis")
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val notes = call.argument<String>("notes")
                    val dateKey = call.argument<String>("dateKey")
                    
                    if (triggerTimeMillis != null && id != null && title != null) {
                        scheduleDirectAlarm(triggerTimeMillis, id, title, notes ?: "", dateKey ?: "")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    AlarmForegroundService.start(this)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    AlarmForegroundService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun scheduleDirectAlarm(
        triggerTimeMillis: Long,
        id: Int,
        title: String,
        notes: String,
        dateKey: String
    ) {
        Log.d("MainActivity", "🚨 scheduleDirectAlarm llamado:")
        Log.d("MainActivity", "  - triggerTime: ${java.util.Date(triggerTimeMillis)}")
        Log.d("MainActivity", "  - id: $id")
        Log.d("MainActivity", "  - title: $title")
        
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Verificar si el dispositivo puede programar alarmas exactas
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val canScheduleExactAlarms = alarmManager.canScheduleExactAlarms()
            Log.d("MainActivity", "  - canScheduleExactAlarms: $canScheduleExactAlarms")
            
            if (!canScheduleExactAlarms) {
                Log.e("MainActivity", "❌ No se tienen permisos para programar alarmas exactas!")
                Log.e("MainActivity", "❌ El usuario DEBE ir a Configuración > Alarmas y recordatorios y activar permisos")
                // Intentar abrir la configuración
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    startActivity(intent)
                } catch (e: Exception) {
                    Log.e("MainActivity", "❌ Error abriendo configuración de alarmas: ${e.message}")
                }
            }
        }
        
        // Intent directo a AlarmActivity (sin BroadcastReceiver)
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                   Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                   Intent.FLAG_ACTIVITY_NO_HISTORY or
                   Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("title", title)
            putExtra("notes", notes)
            putExtra("dateKey", dateKey)
        }
        
        Log.d("MainActivity", "  - Intent directo a AlarmActivity creado")
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        Log.d("MainActivity", "  - PendingIntent (Activity) creado (id=$id)")
        
        try {
            // MÉTODO 1: Intentar con setExactAndAllowWhileIdle (más confiable)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
                Log.d("MainActivity", "✅ Alarma Activity programada con setExactAndAllowWhileIdle (id=$id)")
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
                Log.d("MainActivity", "✅ Alarma Activity programada con setExact (id=$id)")
            }
            
            // MÉTODO 2: También programar con setAlarmClock (más visible para el usuario)
            val alarmClockInfo = AlarmManager.AlarmClockInfo(
                triggerTimeMillis,
                PendingIntent.getActivity(
                    this,
                    id + 2000,
                    Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.d("MainActivity", "✅ Alarma Clock programada como respaldo (id=${id + 2000})")
            
            // MÉTODO 3: BroadcastReceiver como último respaldo
            val broadcastIntent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("title", title)
                putExtra("notes", notes)
                putExtra("dateKey", dateKey)
            }
            
            val broadcastPendingIntent = PendingIntent.getBroadcast(
                this,
                id + 3000,
                broadcastIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                broadcastPendingIntent
            )
            
            Log.d("MainActivity", "✅ Alarma BroadcastReceiver programada como último respaldo (id=${id + 3000})")
            Log.d("MainActivity", "🚨 TRIPLE PROGRAMACIÓN: Activity + Clock + BroadcastReceiver")
            
        } catch (e: SecurityException) {
            Log.e("MainActivity", "❌ SecurityException programando alarma: ${e.message}")
            Log.e("MainActivity", "❌ Verifica que los permisos SCHEDULE_EXACT_ALARM y USE_EXACT_ALARM estén en el Manifest")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error programando alarma: ${e.message}")
            e.printStackTrace()
        }
    }
}


