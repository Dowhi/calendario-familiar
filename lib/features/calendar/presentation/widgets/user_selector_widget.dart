import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/models/local_user.dart';
import 'package:calendario_familiar/core/providers/current_user_provider.dart';

/// 🎨 Widget selector de usuario - versión independiente y reutilizable
class UserSelectorWidget extends ConsumerWidget {
  final bool compact;
  final Function(LocalUser)? onUserSelected;
  
  const UserSelectorWidget({
    super.key,
    this.compact = true,
    this.onUserSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 12,
        vertical: compact ? 3 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: compact ? 2 : 4,
            offset: Offset(0, compact ? 1 : 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: localUsers.map((user) {
          final isSelected = user.id == currentUserId;
          return Expanded(
            child: _buildUserButton(
              context,
              ref,
              user,
              isSelected,
              compact,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildUserButton(
    BuildContext context,
    WidgetRef ref,
    LocalUser user,
    bool isSelected,
    bool compact,
  ) {
    return GestureDetector(
      onTap: () {
        print('🎯 UserSelector: Tocado ${user.name} (ID: ${user.id})');
        
        // Actualizar usuario activo
        ref.read(currentUserIdProvider.notifier).setCurrentUser(user.id);
        
        print('✅ UserSelector: Usuario actualizado a ${user.name}');
        
        // Callback opcional
        onUserSelected?.call(user);
        
        // Feedback visual
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario activo: ${user.name}'),
            duration: const Duration(seconds: 1),
            backgroundColor: user.color,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
        padding: EdgeInsets.symmetric(
          vertical: compact ? 4 : 8,
          horizontal: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? user.color.withOpacity(0.2) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? user.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Círculo de color
            Container(
              width: compact ? 12 : 20,
              height: compact ? 12 : 20,
              decoration: BoxDecoration(
                color: user.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: compact ? 8 : 14,
                    )
                  : null,
            ),
            SizedBox(width: compact ? 3 : 6),
            // Nombre del usuario
            Flexible(
              child: Text(
                user.name,
                style: TextStyle(
                  fontSize: compact ? 9 : 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? user.color : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

