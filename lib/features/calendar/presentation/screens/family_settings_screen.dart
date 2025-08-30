import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/core/models/family.dart' as family_model;
import 'package:calendario_familiar/core/services/firestore_service.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';

class FamilySettingsScreen extends ConsumerStatefulWidget {
  const FamilySettingsScreen({super.key});

  @override
  ConsumerState<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends ConsumerState<FamilySettingsScreen> {
  String? _familyPassword;
  bool _isLoadingPassword = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authControllerProvider);
    final currentUser = authController;
    final firestoreService = ref.watch(firestoreServiceProvider);

    if (currentUser?.familyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Familia'),
        ),
        body: const Center(
          child: Text('No perteneces a ninguna familia'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Familia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<family_model.Family?>(
        stream: firestoreService.getFamilyById(currentUser!.familyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final family = snapshot.data;
          if (family == null) {
            return const Center(
              child: Text('No se encontró información de la familia'),
            );
          }

          final String userRole = family.roles[currentUser.uid] ?? 
              family_model.FamilyRole.member.toString().split('.').last;
          final bool isAdmin = userRole == 'admin';

          // Cargar contraseña si es administrador
          if (isAdmin && _familyPassword == null && !_isLoadingPassword) {
            _loadFamilyPassword(family.id, currentUser.uid);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica de la familia
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.family_restroom, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                family.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Código de invitación
                        _buildInfoRow(
                          icon: Icons.qr_code,
                          label: 'Código de invitación',
                          value: family.code,
                          canCopy: true,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Rol del usuario
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Tu rol',
                          value: userRole.toUpperCase(),
                          canCopy: false,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Fecha de creación
                        if (family.createdAt != null)
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Creada el',
                            value: _formatDate(family.createdAt!),
                            canCopy: false,
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Sección de administrador (solo para admins)
                if (isAdmin) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings, size: 24, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Panel de Administrador',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Contraseña de la familia
                          Row(
                            children: [
                              const Icon(Icons.lock, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Contraseña de la familia:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          if (_isLoadingPassword)
                            const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Cargando contraseña...', style: TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            )
                          else if (_familyPassword != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _showPassword ? _familyPassword! : '••••••••',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _showPassword ? Icons.visibility_off : Icons.visibility,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: _familyPassword!));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Contraseña copiada al portapapeles'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              'No se pudo cargar la contraseña',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Información adicional para administradores
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información para Administradores:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• La contraseña se genera automáticamente al crear la familia\n'
                                  '• Solo los administradores pueden ver esta información\n'
                                  '• Guarda esta contraseña en un lugar seguro\n'
                                  '• Puedes copiarla al portapapeles con el botón de copiar',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Acciones
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Acciones',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        ElevatedButton.icon(
                          onPressed: () {
                            context.go('/');
                          },
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          label: const Text('Volver al Calendario', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implementar gestión de miembros
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gestión de miembros próximamente'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('Gestionar Miembros'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool canCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Cargar contraseña de la familia (solo para administradores)
  Future<void> _loadFamilyPassword(String familyId, String userId) async {
    setState(() {
      _isLoadingPassword = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final password = await firestoreService.getFamilyPassword(familyId, userId);
      
      if (mounted) {
        setState(() {
          _familyPassword = password;
          _isLoadingPassword = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando contraseña de familia: $e');
      if (mounted) {
        setState(() {
          _isLoadingPassword = false;
        });
      }
    }
  }
}

