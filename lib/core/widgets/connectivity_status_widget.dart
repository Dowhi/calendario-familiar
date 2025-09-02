import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/services/connectivity_service.dart';

class ConnectivityStatusWidget extends ConsumerWidget {
  const ConnectivityStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getStatusColor(connectivityService.isOnline, connectivityService.isFirebaseConnected),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getBorderColor(connectivityService.isOnline, connectivityService.isFirebaseConnected),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(connectivityService.isOnline, connectivityService.isFirebaseConnected),
            color: Colors.white,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            _getStatusText(connectivityService.isOnline, connectivityService.isFirebaseConnected),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16.0),
            onPressed: () {
              ref.read(connectivityServiceProvider.notifier).forceConnectivityCheck();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24.0,
              minHeight: 24.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return Colors.red;
    if (!isFirebaseConnected) return Colors.orange;
    return Colors.green;
  }

  Color _getBorderColor(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return Colors.red.shade700;
    if (!isFirebaseConnected) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  IconData _getStatusIcon(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return Icons.wifi_off;
    if (!isFirebaseConnected) return Icons.cloud_off;
    return Icons.cloud_done;
  }

  String _getStatusText(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return 'Sin conexión';
    if (!isFirebaseConnected) return 'Firebase desconectado';
    return 'Conectado';
  }
}

class ConnectivityStatusDialog extends ConsumerWidget {
  const ConnectivityStatusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityService = ref.watch(connectivityServiceProvider);
    final status = connectivityService.getConnectivityStatus();
    
    return AlertDialog(
      title: const Text('Estado de Conectividad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Conexión a Internet', status['isOnline'] ?? false),
          const SizedBox(height: 8.0),
          _buildStatusRow('Conexión a Firebase', status['isFirebaseConnected'] ?? false),
          const SizedBox(height: 8.0),
          _buildStatusRow('Plataforma Web', status['isWeb'] ?? false),
          const SizedBox(height: 16.0),
          const Text(
            'Si experimentas problemas de sincronización:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          const Text('• Verifica tu conexión a internet'),
          const Text('• Recarga la página'),
          const Text('• Limpia el cache del navegador'),
          const Text('• Verifica que Firebase esté disponible'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(connectivityServiceProvider.notifier).forceConnectivityCheck();
          },
          child: const Text('Verificar Ahora'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.error,
          color: status ? Colors.green : Colors.red,
          size: 20.0,
        ),
        const SizedBox(width: 8.0),
        Text(label),
        const Spacer(),
        Text(
          status ? 'OK' : 'Error',
          style: TextStyle(
            color: status ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ConnectivityStatusBanner extends ConsumerWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    // Solo mostrar si hay problemas de conectividad
    if (connectivityService.isOnline && connectivityService.isFirebaseConnected) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      color: _getBannerColor(connectivityService.isOnline, connectivityService.isFirebaseConnected),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            _getBannerIcon(connectivityService.isOnline, connectivityService.isFirebaseConnected),
            color: Colors.white,
            size: 20.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              _getBannerMessage(connectivityService.isOnline, connectivityService.isFirebaseConnected),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ConnectivityStatusDialog(),
              );
            },
            child: const Text(
              'Detalles',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBannerColor(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return Colors.red.shade600;
    if (!isFirebaseConnected) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  IconData _getBannerIcon(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return Icons.wifi_off;
    if (!isFirebaseConnected) return Icons.cloud_off;
    return Icons.cloud_done;
  }

  String _getBannerMessage(bool isOnline, bool isFirebaseConnected) {
    if (!isOnline) return 'Sin conexión a internet. La sincronización está pausada.';
    if (!isFirebaseConnected) return 'Problemas con Firebase. Verificando conexión...';
    return 'Conectado y sincronizando';
  }
}
