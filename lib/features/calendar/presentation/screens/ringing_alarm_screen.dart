import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Pantalla de alarma inspirada en la captura proporcionada.
/// - Muestra hora/fecha actual.
/// - Botón deslizante para silenciar y salir.
/// - Reproduce sonido en loop hasta silenciar.
class RingingAlarmScreen extends StatefulWidget {
  final String title;
  final String notes;
  final String dateText;

  const RingingAlarmScreen({
    super.key,
    required this.title,
    required this.notes,
    required this.dateText,
  });

  @override
  State<RingingAlarmScreen> createState() => _RingingAlarmScreenState();
}

class _RingingAlarmScreenState extends State<RingingAlarmScreen> {
  late final AudioPlayer _player;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _silenced = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _startRinging();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      
      // En Android, usar el sonido de alarma del sistema
      // Esto es más confiable que URLs externas
      try {
        await _player.play(
          DeviceFileSource('system/media/audio/alarms/Argon.ogg'),
          volume: 1.0,
        );
        print('🔊 Sonido de alarma del sistema iniciado');
      } catch (_) {
        // Si el sonido específico no está disponible, intentar otro
        try {
          await _player.play(
            DeviceFileSource('system/media/audio/alarms/Barium.ogg'),
            volume: 1.0,
          );
          print('🔊 Sonido de alarma alternativo iniciado');
        } catch (_) {
          // Si todo falla, continuar sin sonido
          print('⚠️ No se pudo reproducir sonido de alarma, continuando sin sonido');
        }
      }
    } catch (e) {
      print('❌ Error reproduciendo sonido: $e');
      print('⚠️ Continuando sin sonido de alarma');
    }
  }

  Future<void> _stopRinging() async {
    if (_silenced) return;
    _silenced = true;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = '${_two(_now.hour)}:${_two(_now.minute)}';
    final dateText = widget.dateText.isNotEmpty
        ? widget.dateText
        : '${_two(_now.day)}/${_two(_now.month)}/${_now.year % 100}';

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFF455A64),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    '${widget.title}:',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'NOTIFICACIÓN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 96, color: Colors.black54),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black87, width: 1),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HOY: $dateText', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              Text(timeText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _SwipeButton(
                      icon: Icons.notifications_off,
                      label: 'Deslizar para silenciar alarma >>>',
                      color: Colors.black87,
                      onComplete: () async {
                        await _stopRinging();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SwipeButton(
                      icon: Icons.close,
                      label: 'Deslizar para salir >>>',
                      color: Colors.black87,
                      onComplete: () async {
                        await _stopRinging();
                        if (mounted) Navigator.of(context).maybePop();
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF455A64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Text(
                        'Notas del día de la alarma',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black38),
                      ),
                      child: Text(
                        widget.notes.isEmpty ? 'Sin notas' : widget.notes,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _SwipeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function() onComplete;

  const _SwipeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<_SwipeButton> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          _progress = (_progress + d.primaryDelta! / 200).clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (_) async {
        if (_progress > 0.8) {
          await widget.onComplete();
        }
        if (mounted) setState(() => _progress = 0);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              width: 56 + 220 * _progress,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ],
                border: Border.all(color: Colors.black87),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Icon(widget.icon, color: Colors.black87),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


