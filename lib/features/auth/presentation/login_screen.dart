import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
import 'package:calendario_familiar/features/auth/data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isSignUpMode = false;
  
  // Controllers para el formulario de email
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔧 Iniciando sesión con Google...');
      
      // Usar AuthController para iniciar sesión con Google
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      print('🔧 Google Sign-In completado');
      
      // NAVEGACIÓN INMEDIATA - sin verificaciones complejas
      if (mounted) {
        print('🔧 Navegando inmediatamente a /family-management');
        context.go('/family-management');
      }
      
    } catch (e) {
      print('❌ Error en _signInWithGoogle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔧 Iniciando sesión con email...');
      
      final user = await ref.read(authControllerProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        print('✅ Inicio de sesión exitoso: ${user.displayName}');
        
        // Verificar si el usuario tiene familia
        final hasFamily = await ref.read(authControllerProvider.notifier).currentUserHasFamily();
        
        if (mounted) {
          if (hasFamily) {
            // Si tiene familia, ir al calendario principal
            print('✅ Usuario tiene familia, redirigiendo al calendario...');
            context.go('/');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bienvenido, ${user.displayName ?? 'Usuario'}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Si no tiene familia, ir a la pantalla de gestión familiar
            print('⚠️ Usuario no tiene familia, redirigiendo a gestión familiar...');
            context.go('/family-management');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bienvenido. Ahora necesitas crear o unirte a una familia.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: Credenciales incorrectas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _signInWithEmail: $e');
      if (mounted) {
        String errorMessage = 'Error al iniciar sesión';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Usuario no encontrado';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Contraseña incorrecta';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Correo electrónico inválido';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔧 Iniciando registro con email...');
      
      final user = await ref.read(authControllerProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );

      if (user != null) {
        print('✅ Registro exitoso: ${user.displayName}');
        
        // Verificar si el usuario tiene familia
        final hasFamily = await ref.read(authControllerProvider.notifier).currentUserHasFamily();
        
        if (mounted) {
          if (hasFamily) {
            // Si tiene familia, ir al calendario principal
            print('✅ Usuario tiene familia, redirigiendo al calendario...');
            context.go('/');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bienvenido, ${user.displayName ?? 'Usuario'}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Si no tiene familia, ir a la pantalla de gestión familiar
            print('⚠️ Usuario no tiene familia, redirigiendo a gestión familiar...');
            context.go('/family-management');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Registro exitoso. Ahora necesitas crear o unirte a una familia.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se pudo completar el registro'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _signUpWithEmail: $e');
      if (mounted) {
        String errorMessage = 'Error al registrar usuario';
        
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Este correo electrónico ya está registrado';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'La contraseña es demasiado débil';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Correo electrónico inválido';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo y título
                  Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: Colors.white,
                  ),
                  Text(
                    'Organiza tu vida familiar',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Formulario de email (condicional)
                  if (_isSignUpMode || !_isSignUpMode) ...[
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSignUpMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Campo de nombre (solo para registro)
                              if (_isSignUpMode) ...[
                                TextFormField(
                                  controller: _displayNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre completo',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (_isSignUpMode) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Por favor ingresa tu nombre';
                                      }
                                      if (value.trim().length < 2) {
                                        return 'El nombre debe tener al menos 2 caracteres';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // Campo de email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Por favor ingresa tu correo electrónico';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Por favor ingresa un correo electrónico válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Campo de contraseña
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa una contraseña';
                                  }
                                  if (_isSignUpMode && value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Campo de confirmar contraseña (solo para registro)
                              if (_isSignUpMode) ...[
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (_isSignUpMode) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor confirma tu contraseña';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Las contraseñas no coinciden';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // Botón de acción
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : (_isSignUpMode ? _signUpWithEmail : _signInWithEmail),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isSignUpMode ? 'Crear Cuenta' : 'Iniciar Sesión',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Enlace para cambiar modo
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    // Limpiar formulario
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _displayNameController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: Text(_isSignUpMode 
                                    ? '¿Ya tienes cuenta? Inicia sesión' 
                                    : '¿No tienes cuenta? Regístrate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Separador
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white70)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'O',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Botón de Google
                  _buildLoginButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          Icons.sync,
                          'Sincronización en tiempo real',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.notifications,
                          'Notificaciones inteligentes',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.group,
                          'Compartido con la familia',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: Image.network(
          'https://developers.google.com/identity/images/g-logo.png',
          height: 24,
        ),
        label: const Text(
          'Continuar con Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

