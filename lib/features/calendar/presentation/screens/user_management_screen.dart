import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/models/local_user.dart';
import 'package:calendario_familiar/core/providers/current_user_provider.dart';
import 'package:calendario_familiar/core/services/user_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<LocalUser> _users = List.from(localUsers);
  final List<TextEditingController> _nameControllers = [];
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameControllers.clear();
    for (final user in _users) {
      _nameControllers.add(TextEditingController(text: user.name));
    }
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<LocalUser> loadedUsers = [];
    
    for (int i = 0; i < 5; i++) {
      final name = prefs.getString('user_${i + 1}_name') ?? 'Usuario ${i + 1}';
      final colorValue = prefs.getInt('user_${i + 1}_color') ?? _availableColors[i].value;
      final color = Color(colorValue);
      
      loadedUsers.add(LocalUser(
        id: i + 1,
        name: name,
        color: color,
      ));
    }
    
    setState(() {
      _users = loadedUsers;
    });
    _initializeControllers();
  }

  Future<void> _saveUsers() async {
    try {
      // Guardar en SharedPreferences (local)
      final prefs = await SharedPreferences.getInstance();
      
      for (int i = 0; i < _users.length; i++) {
        await prefs.setString('user_${i + 1}_name', _users[i].name);
        await prefs.setInt('user_${i + 1}_color', _users[i].color.value);
      }
      
      // Actualizar la lista global de usuarios
      localUsers.clear();
      localUsers.addAll(_users);
      
      // 🔹 Sincronizar con Firebase
      await UserSyncService.syncLocalUsersWithFirebase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuarios guardados y sincronizados con Firebase'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error guardando usuarios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateUserName(int index, String name) {
    setState(() {
      _users[index] = LocalUser(
        id: _users[index].id,
        name: name,
        color: _users[index].color,
      );
    });
  }

  void _updateUserColor(int index, Color color) {
    setState(() {
      _users[index] = LocalUser(
        id: _users[index].id,
        name: _users[index].name,
        color: color,
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUsers,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personaliza los nombres y colores de los usuarios:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Círculo de color
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: user.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Campo de nombre
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Nombre del Usuario ${index + 1}',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) => _updateUserName(index, value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Selector de colores
                          const Text(
                            'Color:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableColors.map((color) {
                              final isSelected = user.color == color;
                              return GestureDetector(
                                onTap: () => _updateUserColor(index, color),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.grey[300]!,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Botón de guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveUsers,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
