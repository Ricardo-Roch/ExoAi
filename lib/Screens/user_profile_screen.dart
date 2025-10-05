// lib/Screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import '../Servicios/user_service.dart';
import '../Servicios/community_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  final _communityService = CommunityService();
  int _selectedTab = 0;

  Future<void> _toggleFollow(UserModel userModel) async {
    final currentUserId = _userService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (userModel.isFollowedBy(currentUserId)) {
        await _userService.unfollowUser(widget.userId);
      } else {
        await _userService.followUser(widget.userId);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userService.currentUser?.uid;

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Text(
                'Usuario no encontrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final userModel = snapshot.data!;
        final isOwnProfile = currentUserId == widget.userId;
        final isFollowing = userModel.isFollowedBy(currentUserId ?? '');

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: CustomScrollView(
            slivers: [
              // AppBar con banner
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
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
                          backgroundImage: userModel.photoURL != null
                              ? NetworkImage(userModel.photoURL!)
                              : null,
                          child: userModel.photoURL == null
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
                        userModel.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Email
                      Text(
                        userModel.email,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),

                      if (userModel.bio != null &&
                          userModel.bio!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            userModel.bio!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

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
                              '${userModel.postsCount}',
                              Icons.article,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF334155),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showFollowersList(context, widget.userId),
                              child: _buildStatColumn(
                                'Seguidores',
                                '${userModel.followersCount}',
                                Icons.people,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF334155),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showFollowingList(context, widget.userId),
                              child: _buildStatColumn(
                                'Siguiendo',
                                '${userModel.followingCount}',
                                Icons.person_add,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botón de seguir/dejar de seguir
                      if (!isOwnProfile)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleFollow(userModel),
                              icon: Icon(
                                isFollowing
                                    ? Icons.person_remove
                                    : Icons.person_add,
                              ),
                              label: Text(
                                isFollowing ? 'Dejar de seguir' : 'Seguir',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? const Color(0xFF334155)
                                    : const Color(0xFF60A5FA),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildTab('Posts', 0),
                            _buildTab('Media', 1),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Contenido según tab seleccionado
              _selectedTab == 0 ? _buildPostsList() : _buildMediaGrid(),
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<List<Post>>(
      stream: _communityService.getUserPosts(widget.userId),
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
                      'No hay publicaciones aún',
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

  Widget _buildMediaGrid() {
    return StreamBuilder<List<Post>>(
      stream: _communityService.getUserPosts(widget.userId),
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
        final postsWithImages = posts.where((p) => p.imageUrl != null).toList();

        if (postsWithImages.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay media aún',
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

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    postsWithImages[index].imageUrl!,
                    fit: BoxFit.cover,
                  ),
                );
              },
              childCount: postsWithImages.length,
            ),
          ),
        );
      },
    );
  }

  void _showFollowersList(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListScreen(
          userId: userId,
          title: 'Seguidores',
        ),
      ),
    );
  }

  void _showFollowingList(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingListScreen(
          userId: userId,
          title: 'Siguiendo',
        ),
      ),
    );
  }
}
