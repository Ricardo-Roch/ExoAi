// lib/widgets/profile_avatar_menu.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/user_service.dart';
import '../Servicios/firebase_auth_service.dart';
import '../models/user_model.dart';
import '../Screens/profile_screen.dart';
import '../Screens/edit_profile_screen.dart';
import '../Screens/login_screen.dart';

class ProfileAvatarMenu extends StatelessWidget {
  const ProfileAvatarMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<UserModel?>(
      stream: UserService().getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        final userModel = snapshot.data;

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          color: const Color(0xFF1E293B),
          itemBuilder: (context) => [
            // Header con info del usuario
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF60A5FA),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF60A5FA),
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userModel?.displayName ??
                                  user.displayName ??
                                  'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (userModel?.bio != null && userModel!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFF60A5FA),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userModel.bio!,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Estadísticas mini
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(
                        'Posts',
                        '${userModel?.postsCount ?? 0}',
                        Icons.article,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFF334155),
                      ),
                      _buildMiniStat(
                        'Seguidores',
                        '${userModel?.followersCount ?? 0}',
                        Icons.people,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFF334155),
                      ),
                      _buildMiniStat(
                        'Siguiendo',
                        '${userModel?.followingCount ?? 0}',
                        Icons.person_add,
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),
                ],
              ),
            ),
            // Ver perfil
            PopupMenuItem<String>(
              value: 'profile',
              child: const Row(
                children: [
                  Icon(Icons.person, color: Color(0xFF60A5FA), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Ver mi perfil',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Editar perfil
            PopupMenuItem<String>(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF60A5FA), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Editar perfil',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Cerrar sesión
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red[400], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userName: userModel?.displayName ??
                          user.displayName ??
                          'Usuario',
                    ),
                  ),
                );
                break;
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                break;
              case 'logout':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          const BorderSide(color: Color(0xFF334155), width: 1),
                    ),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Color(0xFF60A5FA)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await FirebaseAuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
                break;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF60A5FA),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF60A5FA),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
