import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/core/models/family.dart' as family_model; // Usar alias
import 'package:calendario_familiar/core/services/firestore_service.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';

class FamilyManagementScreen extends ConsumerStatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  ConsumerState<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends ConsumerState<FamilyManagementScreen> {
  final _createFamilyFormKey = GlobalKey<FormState>();
  final _joinFamilyFormKey = GlobalKey<FormState>();
  final TextEditingController _newFamilyNameController = TextEditingController();
  final TextEditingController _joinFamilyCodeController = TextEditingController();
  
  // Estado para manejar la contraseña de la familia
  String? _familyPassword;
  bool _isLoadingPassword = false;

  @override
  void dispose() {
    _newFamilyNameController.dispose();
    _joinFamilyCodeController.dispose();
    super.dispose();
  }

  // Cargar contraseña de la familia (solo para administradores)
  Future<void> _loadFamilyPassword(String familyId, String userId) async {
    if (_familyPassword != null) return; // Ya cargada
    
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

  Future<void> _createFamily() async {
    print('🔧 _createFamily iniciado');
    
    final authController = ref.read(authControllerProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    print('🔧 authController: $authController');
    print('🔧 firestoreService: $firestoreService');
    
    if (authController == null) {
      print('❌ Usuario no autenticado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No estás autenticado. Por favor, inicia sesión primero.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('🔧 Usuario autenticado: ${authController.uid}');
    print('🔧 Nombre de familia a crear: ${_newFamilyNameController.text.trim()}');
    
    try {
      final result = await firestoreService.createFamily(
        _newFamilyNameController.text.trim(),
        authController.uid,
      );
      
      print('🔧 Resultado de createFamily: $result');
      
      if (mounted) {
        if (result != null) {
          print('🔧 Familia creada exitosamente, actualizando familyId del usuario...');
          
          // Actualizar el usuario local con el nuevo familyId
          await ref.read(authControllerProvider.notifier).updateUserFamilyId(result.id);
          
          print('🔧 FamilyId actualizado, verificando estado...');
          
          // Verificar que el usuario se actualizó correctamente
          final updatedUser = ref.read(authControllerProvider);
          print('🔧 Usuario actualizado: $updatedUser');
          print('🔧 Nuevo familyId: ${updatedUser?.familyId}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Familia "${result.name}" creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Limpiar el formulario
          _newFamilyNameController.clear();
          
          // Forzar reconstrucción de la UI
          setState(() {});
          
          print('🔧 UI reconstruida, debería mostrar los datos de la nueva familia');
          
          // No cerrar la pantalla, dejar que se actualice automáticamente
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se pudo crear la familia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _createFamily: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear familia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinFamily() async {
    print('🔧 _joinFamily iniciado');
    
    final authController = ref.read(authControllerProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    print('🔧 authController: $authController');
    print('🔧 firestoreService: $firestoreService');
    
    if (authController == null) {
      print('❌ Usuario no autenticado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No estás autenticado. Por favor, inicia sesión primero.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('🔧 Usuario autenticado: ${authController.uid}');
    print('🔧 Código de familia a unirse: ${_joinFamilyCodeController.text.trim()}');
    
    try {
      final result = await firestoreService.joinFamily(
        _joinFamilyCodeController.text.trim(),
        authController.uid,
      );
      
      print('🔧 Resultado de joinFamily: $result');
      
      if (mounted) {
        if (result != null) {
          print('🔧 Familia encontrada, actualizando familyId del usuario...');
          
          // Actualizar el usuario local con el nuevo familyId
          await ref.read(authControllerProvider.notifier).updateUserFamilyId(result.id);
          
          print('🔧 FamilyId actualizado, verificando estado...');
          
          // Verificar que el usuario se actualizó correctamente
          final updatedUser = ref.read(authControllerProvider);
          print('🔧 Usuario actualizado: $updatedUser');
          print('🔧 Nuevo familyId: ${updatedUser?.familyId}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Te has unido exitosamente a la familia "${result.name}"'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Limpiar el formulario
          _joinFamilyCodeController.clear();
          
          // Forzar reconstrucción de la UI
          setState(() {});
          
          print('🔧 UI reconstruida, debería mostrar los datos de la familia unida');
          
          // No cerrar la pantalla, dejar que se actualice automáticamente
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se pudo unir a la familia. Verifica el código.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _joinFamily: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al unirse a familia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    print('🔧 _signInWithGoogle iniciado');
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Intentar iniciar sesión con Google
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Verificar si el login fue exitoso
        final currentUser = ref.read(authControllerProvider);
        if (currentUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Bienvenido, ${currentUser.displayName ?? 'Usuario'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al iniciar sesión'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _signInWithGoogle: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveFamily() async {
    print('🔧 _leaveFamily iniciado');
    
    final authController = ref.read(authControllerProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    
    if (authController == null || authController.familyId == null) {
      print('❌ Usuario no autenticado o sin familia');
      return;
    }
    
    print('🔧 Usuario: ${authController.uid}');
    print('🔧 Familia actual: ${authController.familyId}');
    
    try {
      // Mostrar diálogo de confirmación
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Salir de la Familia'),
          content: const Text('¿Estás seguro de que quieres salir de esta familia? Perderás acceso a todos los datos compartidos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Salir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (shouldLeave != true) {
        print('🔧 Usuario canceló la operación');
        return;
      }
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Remover al usuario de la familia
      await firestoreService.removeUserFromFamily(authController.familyId!, authController.uid);
      
      // Actualizar el usuario local (quitar familyId)
      await ref.read(authControllerProvider.notifier).updateUserFamilyId(null);
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Has salido de la familia exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('🔧 Usuario salió de la familia exitosamente');
      
    } catch (e) {
      print('❌ Error en _leaveFamily: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al salir de la familia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    print('🔧 _signOut iniciado');
    
    try {
      // Mostrar diálogo de confirmación
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión? Tendrás que volver a iniciar sesión para acceder a tus datos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (shouldSignOut != true) {
        print('🔧 Usuario canceló la operación');
        return;
      }
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Cerrar sesión
      await ref.read(authControllerProvider.notifier).signOut();
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesión cerrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('🔧 Sesión cerrada exitosamente');
      
    } catch (e) {
      print('❌ Error en _signOut: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 FamilyManagementScreen: Iniciando build...');
    
    final currentUser = ref.watch(authControllerProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final currentFamilyId = currentUser?.familyId;

    print('🔧 build - currentUser: $currentUser');
    print('🔧 build - currentFamilyId: $currentFamilyId');

    print('🔧 FamilyManagementScreen: Construyendo Scaffold...');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Familiar'),
        actions: [
          // Indicador de estado de autenticación para debugging
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              currentUser != null ? Icons.person : Icons.person_off,
              color: currentUser != null ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: currentUser == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'No estás autenticado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para gestionar tu familia, necesitas iniciar sesión',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navegar a la pantalla de login
                          context.go('/login');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // Intentar iniciar sesión directamente con Google
                        _signInWithGoogle();
                      },
                      child: const Text('¿Ya tienes cuenta? Inicia sesión con Google'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: currentFamilyId == null
                  ? _buildNoFamilyView(context)
                  : _buildFamilyDetailView(context, currentFamilyId),
            ),
    );
  }

  Widget _buildNoFamilyView(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _createFamilyFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'No eres miembro de ninguna familia.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear Nueva Familia',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newFamilyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la nueva familia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        validator: (value) {
                          print('🔧 Validando nombre de familia: "$value"');
                          if (value == null) {
                            print('❌ Valor es null');
                            return 'Por favor ingrese un nombre para la familia';
                          }
                          if (value.trim().isEmpty) {
                            print('❌ Valor está vacío después de trim');
                            return 'Por favor ingrese un nombre para la familia';
                          }
                          print('✅ Validación exitosa');
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Validar el formulario primero
                          if (!_createFamilyFormKey.currentState!.validate()) {
                            print('❌ Validación del formulario falló');
                            return;
                          }
                          
                          // Mostrar indicador de carga
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          
                          await _createFamily();
                          
                          // Ocultar indicador de carga
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Nueva Familia'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('O', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _joinFamilyFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Unirse a Familia Existente',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _joinFamilyCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Código de invitación',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group_add),
                          ),
                          validator: (value) {
                            print('🔧 Validando código de invitación: "$value"');
                            if (value == null) {
                              print('❌ Valor es null');
                              return 'Por favor ingrese un código de invitación';
                            }
                            if (value.trim().isEmpty) {
                              print('❌ Valor está vacío después de trim');
                              return 'Por favor ingrese un código de invitación';
                            }
                            print('✅ Validación exitosa');
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Validar el formulario primero
                            if (!_joinFamilyFormKey.currentState!.validate()) {
                              print('❌ Validación del formulario falló');
                              return;
                            }
                            
                            // Mostrar indicador de carga
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            await _joinFamily();
                            
                            // Ocultar indicador de carga
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Unirse a Familia'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyDetailView(BuildContext context, String familyId) {
    final authController = ref.watch(authControllerProvider);
    final currentUser = authController; // authController es el AppUser directamente
    final firestoreService = ref.watch(firestoreServiceProvider);

    return StreamBuilder<family_model.Family?>(
      stream: firestoreService.getFamilyById(familyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final family = snapshot.data;
        if (family == null) {
          return const Text('No se encontró información de la familia.');
        }

        final String userRole = family.roles[currentUser?.uid ?? ''] ?? family_model.FamilyRole.member.toString().split('.').last;
        final bool isAdmin = userRole == 'admin';

        // Cargar contraseña si es administrador
        if (isAdmin && currentUser?.uid != null) {
          _loadFamilyPassword(family.id, currentUser!.uid);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la familia
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Familia actual: ${family.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Código de invitación: ${family.code}',
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu rol: ${userRole.toUpperCase()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      
                      // Mostrar contraseña solo para administradores
                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.lock, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Contraseña de la familia:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _familyPassword!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () async {
                                    // Copiar contraseña al portapapeles
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
                          )
                        else
                          const Text(
                            'No se pudo cargar la contraseña',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botones de acción
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Acciones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Botón para continuar a la app
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navegar al calendario principal
                          context.go('/');
                        },
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: const Text('Continuar a la App', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Botón para configuración de familia
                      OutlinedButton.icon(
                        onPressed: () {
                          // Navegar a la configuración de familia
                          context.go('/family-settings');
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configuración de Familia'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Botón para salir de la familia
                      ElevatedButton.icon(
                        onPressed: _leaveFamily,
                        icon: const Icon(Icons.exit_to_app, color: Colors.white),
                        label: const Text('Salir de la Familia', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Botón para cerrar sesión
                      ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Lista de miembros
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Miembros de la familia:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: firestoreService.getFamilyMembers(familyId),
                        builder: (context, membersSnapshot) {
                          if (membersSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (membersSnapshot.hasError) {
                            return Text('Error al cargar miembros: ${membersSnapshot.error}');
                          }
                          final members = membersSnapshot.data ?? [];
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final String memberUid = member['uid'];
                              final String memberName = member['displayName'] ?? 'Usuario desconocido';
                              final String memberRole = member['role'] ?? family_model.FamilyRole.member.toString().split('.').last;
                              return ListTile(
                                title: Text(memberName),
                                subtitle: Text('Rol: ${memberRole.toUpperCase()}'),
                                trailing: (userRole == family_model.FamilyRole.admin.toString().split('.').last && memberUid != currentUser?.uid)
                                    ? DropdownButton<family_model.FamilyRole>(
                                        value: family_model.FamilyRole.values.firstWhere(
                                          (e) => e.toString().split('.').last == memberRole,
                                          orElse: () => family_model.FamilyRole.member,
                                        ),
                                        onChanged: (family_model.FamilyRole? newRole) async {
                                          if (newRole != null) {
                                            await firestoreService.updateFamilyMemberRole(familyId, memberUid, newRole);
                                          }
                                        },
                                        items: family_model.FamilyRole.values.map((family_model.FamilyRole role) {
                                          return DropdownMenuItem<family_model.FamilyRole>(
                                            value: role,
                                            child: Text(role.toString().split('.').last.toUpperCase()),
                                          );
                                        }).toList(),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
