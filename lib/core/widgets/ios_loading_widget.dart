import 'package:flutter/material.dart';

/// Widget de carga optimizado para iOS
/// Evita problemas de rendering que causan requestAnimationFrame violations
class IOSLoadingWidget extends StatefulWidget {
  final String message;
  final Duration timeout;
  final VoidCallback? onTimeout;

  const IOSLoadingWidget({
    super.key,
    this.message = 'Cargando...',
    this.timeout = const Duration(seconds: 8),
    this.onTimeout,
  });

  @override
  State<IOSLoadingWidget> createState() => _IOSLoadingWidgetState();
}

class _IOSLoadingWidgetState extends State<IOSLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    
    // Usar un AnimationController más simple para iOS
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
    
    // Timeout para iOS
    Future.delayed(widget.timeout, () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
        widget.onTimeout?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B5E20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner simple para iOS
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(_animation.value * 0.8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1B5E20),
                    size: 30,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Mensaje de carga
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Mensaje de timeout si aplica
            if (_hasTimedOut) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⚠️ Carga lenta detectada',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Si la aplicación no carga, recarga la página o verifica tu conexión.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Recargar la página
                        if (context.mounted) {
                          // En web, recargar la página
                          // ignore: avoid_web_libraries_in_flutter
                          // html.window.location.reload();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Recargar'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
