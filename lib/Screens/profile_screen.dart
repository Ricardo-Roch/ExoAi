// lib/Screens/profile_screen.dart (ACTUALIZADO - Sin Media, edición directa de bio)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/firebase_auth_service.dart';
import '../Servicios/user_service.dart';
import '../Servicios/community_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'login_screen.dart';
import 'search_users_screen.dart';
import 'followers_following_screens.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();
  final CommunityService _communityService = CommunityService();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  bool _isSavingBio = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _saveBio() async {
    setState(() => _isSavingBio = true);

    try {
      await _userService.saveUserProfile(bio: _bioController.text.trim());
      setState(() => _isEditingBio = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biografía actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBio = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        final userModel = snapshot.data;

        // Inicializar el controlador de bio solo una vez cuando los datos estén disponibles
        if (userModel != null &&
            _bioController.text.isEmpty &&
            !_isEditingBio) {
          _bioController.text = userModel.bio ?? '';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: CustomScrollView(
            slivers: [
              // AppBar con banner
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                actions: [
                  // Logo en la esquina superior derecha
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Image.asset(
                      'assets/images/Logo-02.png',
                      height: 40,
                      width: 40,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchUsersScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _handleLogout,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF60A5FA).withOpacity(0.3),
                          const Color(0xFF1E293B),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido del perfil
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      // Foto de perfil
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF60A5FA),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF60A5FA).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF60A5FA),
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nombre
                      Text(
                        userModel?.displayName ?? widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Email
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bio editable
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _isEditingBio
                            ? Column(
                                children: [
                                  TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    maxLength: 200,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Escribe tu biografía...',
                                      hintStyle: const TextStyle(
                                          color: Color(0xFF64748B)),
                                      filled: true,
                                      fillColor: const Color(0xFF1E293B),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF334155)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF60A5FA), width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditingBio = false;
                                            _bioController.text =
                                                userModel?.bio ?? '';
                                          });
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed:
                                            _isSavingBio ? null : _saveBio,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF60A5FA),
                                        ),
                                        child: _isSavingBio
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Text('Guardar'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () {
                                  setState(() => _isEditingBio = true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF334155),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userModel?.bio != null &&
                                                  userModel!.bio!.isNotEmpty
                                              ? userModel.bio!
                                              : 'Toca para agregar biografía',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: userModel?.bio != null &&
                                                    userModel!.bio!.isNotEmpty
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                            fontSize: 14,
                                            height: 1.5,
                                            fontStyle: userModel?.bio != null &&
                                                    userModel!.bio!.isNotEmpty
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Color(0xFF60A5FA),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Estadísticas
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E293B),
                              Color(0xFF0F172A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Posts',
                              '${userModel?.postsCount ?? 0}',
                              Icons.article,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF334155),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersListScreen(
                                      userId: user.uid,
                                      title: 'Seguidores',
                                    ),
                                  ),
                                );
                              },
                              child: _buildStatColumn(
                                'Seguidores',
                                '${userModel?.followersCount ?? 0}',
                                Icons.people,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF334155),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowingListScreen(
                                      userId: user.uid,
                                      title: 'Siguiendo',
                                    ),
                                  ),
                                );
                              },
                              child: _buildStatColumn(
                                'Siguiendo',
                                '${userModel?.followingCount ?? 0}',
                                Icons.person_add,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Posts del usuario
              _buildMyPosts(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMyPosts() {
    final user = _authService.currentUser;
    if (user == null) return const SliverToBoxAdapter(child: SizedBox());

    return StreamBuilder<List<Post>>(
      stream: _communityService.getUserPosts(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No has publicado nada aún',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PostCard(post: posts[index]),
            childCount: posts.length,
          ),
        );
      },
    );
  }
}
