package com.juancarlos.calendariofamiliar

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class AlarmActivity : AppCompatActivity() {
    
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private lateinit var title: String
    private lateinit var notes: String
    private lateinit var dateKey: String
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("AlarmActivity", "🚨🚨🚨 ALARMACTIVITY LANZADA DESDE SISTEMA 🚨🚨🚨")
        Log.d("AlarmActivity", "✅ AlarmActivity creada - MOSTRANDO UI NATIVA")
        Log.d("AlarmActivity", "🔍 Intent extras: ${intent.extras}")
        Log.d("AlarmActivity", "🔍 Task ID: ${taskId}")
        Log.d("AlarmActivity", "🔍 Activity: ${this}")
        Log.d("AlarmActivity", "🔍 Package name: ${packageName}")
        Log.d("AlarmActivity", "🔍 Component name: ${componentName}")
        
        // Configurar la ventana para que se muestre sobre la pantalla de bloqueo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        
        // Asegurar que la actividad se muestre sobre todo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        
        // MOSTRAR UI NATIVA INMEDIATAMENTE
        Log.d("AlarmActivity", "🎨 Configurando layout...")
        setContentView(R.layout.activity_alarm)
        Log.d("AlarmActivity", "✅ Layout configurado exitosamente")
        
        // Obtener datos del intent
        title = intent.getStringExtra("title") ?: "Alarma"
        notes = intent.getStringExtra("notes") ?: ""
        dateKey = intent.getStringExtra("dateKey") ?: ""
        val fromAlarm = intent.getBooleanExtra("from_alarm", false)
        
        Log.d("AlarmActivity", "  - title: $title")
        Log.d("AlarmActivity", "  - notes: $notes")
        Log.d("AlarmActivity", "  - dateKey: $dateKey")
        Log.d("AlarmActivity", "  - from_alarm: $fromAlarm")
        
        // Si viene de alarma, asegurar que se mantenga en primer plano
        if (fromAlarm) {
            Log.d("AlarmActivity", "🔔 Viene de alarma - configurando para mantenerse en primer plano")
            // Asegurar que la actividad se mantenga visible
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        
        // Forzar que la actividad se mantenga visible
        Log.d("AlarmActivity", "🔧 Forzando visibilidad de la actividad...")
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Configurar UI
        Log.d("AlarmActivity", "🎨 Configurando elementos de UI...")
        findViewById<TextView>(R.id.alarmTitle).text = title
        val notesView = findViewById<TextView>(R.id.alarmNotes)
        if (notes.isNotEmpty()) {
            notesView.text = notes
            notesView.visibility = View.VISIBLE
        } else {
            notesView.visibility = View.GONE
        }
        
        // Configurar botones
        findViewById<Button>(R.id.btnSnooze).setOnClickListener {
            Log.d("AlarmActivity", "Snooze presionado")
            stopAlarm()
            // TODO: Programar alarma en 5 minutos
            finish()
        }
        
        findViewById<Button>(R.id.btnDismiss).setOnClickListener {
            Log.d("AlarmActivity", "Dismiss presionado")
            stopAlarm()
            finish()
        }
        
        Log.d("AlarmActivity", "✅ Elementos de UI configurados")
        
        // Iniciar sonido y vibración
        startAlarm()
        
        Log.d("AlarmActivity", "✅ UI nativa mostrada exitosamente")
        Log.d("AlarmActivity", "🔍 Activity visible: ${isFinishing}")
        Log.d("AlarmActivity", "🔍 Activity destroyed: ${isDestroyed}")
        Log.d("AlarmActivity", "🔍 Window flags: ${window.attributes.flags}")
        Log.d("AlarmActivity", "🔍 Activity state: ${lifecycle.currentState}")
    }
    
    private fun startAlarm() {
        try {
            // Reproducir sonido
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alarmUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
            
            Log.d("AlarmActivity", "🔊 Sonido de alarma iniciado")
            
            // Vibrar
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 1000, 1000),
                        0
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 1000, 1000), 0)
            }
            
            Log.d("AlarmActivity", "📳 Vibración iniciada")
        } catch (e: Exception) {
            Log.e("AlarmActivity", "❌ Error iniciando alarma: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun stopAlarm() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
            
            vibrator?.cancel()
            vibrator = null
            
            Log.d("AlarmActivity", "🔇 Alarma detenida")
        } catch (e: Exception) {
            Log.e("AlarmActivity", "❌ Error deteniendo alarma: ${e.message}")
        }
    }
    
    override fun onResume() {
        super.onResume()
        Log.d("AlarmActivity", "🔄 onResume() - Asegurando que la actividad esté visible")
        
        // Asegurar que la actividad se mantenga visible
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        Log.d("AlarmActivity", "✅ Flags de ventana reconfigurados en onResume")
    }
    
    override fun onBackPressed() {
        // NO permitir cerrar con el botón atrás
        Log.d("AlarmActivity", "⚠️ Botón atrás presionado - IGNORANDO para mantener alarma activa")
        // No llamar super.onBackPressed()
    }
    
    override fun onPause() {
        super.onPause()
        Log.d("AlarmActivity", "⚠️ onPause() - La alarma sigue activa")
        // NO detener la alarma en onPause
    }
    
    override fun onStop() {
        super.onStop()
        Log.d("AlarmActivity", "⚠️ onStop() - La alarma sigue activa")
        // NO detener la alarma en onStop
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("AlarmActivity", "💀 onDestroy() - Deteniendo alarma")
        stopAlarm()
    }
}

