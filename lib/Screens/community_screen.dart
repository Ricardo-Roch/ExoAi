import 'package:flutter/material.dart';
import '../Servicios/community_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';
import 'search_users_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: isLargeScreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Color(0xFF60A5FA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Comunidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF60A5FA)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchUsersScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Header con búsqueda (solo para pantallas grandes)
            if (isLargeScreen)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(0xFF60A5FA),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comunidad ExoAI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Conecta con otros exploradores espaciales',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchUsersScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Buscar usuarios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tabs
            Container(
              margin: EdgeInsets.fromLTRB(
                isMobile ? 12 : 24,
                16,
                isMobile ? 12 : 24,
                8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTab('Para Ti', 0, isMobile),
                  _buildTab('Siguiendo', 1, isMobile),
                  _buildTab('Todos', 2, isMobile),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 800 : double.infinity,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24 : 0,
                ),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showCreatePostDialog(context),
              backgroundColor: const Color(0xFF60A5FA),
              foregroundColor: Colors.white,
              elevation: 8,
              child: const Icon(Icons.add, size: 28),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showCreatePostDialog(context),
              icon: const Icon(Icons.add),
              label: const Text(
                'Nueva Publicación',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF60A5FA),
              foregroundColor: Colors.white,
              elevation: 8,
            ),
    );
  }

  Widget _buildTab(String label, int index, bool isMobile) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF60A5FA),
                      Color(0xFF3B82F6),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isMobile || index == _selectedTab)
                Icon(
                  _getTabIcon(index),
                  size: isMobile ? 16 : 18,
                  color: Colors.white,
                ),
              if (!isMobile || index == _selectedTab) const SizedBox(width: 6),
              Text(
                isMobile ? _getTabShortLabel(label) : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.auto_awesome;
      case 1:
        return Icons.people;
      case 2:
        return Icons.public;
      default:
        return Icons.forum;
    }
  }

  String _getTabShortLabel(String label) {
    if (label == 'Para Ti') return 'Ti';
    if (label == 'Siguiendo') return 'Sig';
    return label;
  }

  Widget _buildContent() {
    Stream<List<Post>> postsStream;

    switch (_selectedTab) {
      case 0:
      case 1:
        postsStream = _communityService.getFollowingPosts();
        break;
      case 2:
      default:
        postsStream = _communityService.getPosts();
        break;
    }

    return StreamBuilder<List<Post>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF60A5FA),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando publicaciones...',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red[600]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error al cargar publicaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF60A5FA).withOpacity(0.1),
                          const Color(0xFF60A5FA).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _selectedTab == 2
                          ? Icons.forum_outlined
                          : Icons.people_outline,
                      size: 80,
                      color: const Color(0xFF60A5FA).withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedTab == 2
                        ? 'No hay publicaciones aún'
                        : 'Sigue a usuarios para ver su contenido',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedTab == 2
                        ? '¡Sé el primero en publicar algo increíble!'
                        : 'Descubre usuarios interesantes en la comunidad',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_selectedTab != 2)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchUsersScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text(
                        'Buscar Usuarios',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _showCreatePostDialog(context),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'Crear Publicación',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: const Color(0xFF60A5FA),
          backgroundColor: const Color(0xFF1E293B),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          ),
        );
      },
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );
  }
}
