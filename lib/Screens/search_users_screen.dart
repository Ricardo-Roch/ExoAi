import 'package:flutter/material.dart';
import '../Servicios/user_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key}) : super(key: key);

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  List<UserModel> _suggestedUsers = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final users = await _userService.getSuggestedUsers();
      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final users = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Buscar Usuarios',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
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
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF60A5FA)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Resultados
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF60A5FA),
        ),
      );
    }

    if (_searchController.text.isNotEmpty) {
      if (_searchResults.isEmpty) {
        return Center(
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
                  Icons.search_off,
                  size: 64,
                  color: const Color(0xFF60A5FA).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No se encontraron usuarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intenta con otro término de búsqueda',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return _buildUserTile(_searchResults[index]);
        },
      );
    }

    // Mostrar usuarios sugeridos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: Color(0xFF60A5FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Usuarios sugeridos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingSuggestions
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF60A5FA),
                  ),
                )
              : _suggestedUsers.isEmpty
                  ? Center(
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
                              Icons.people_outline,
                              size: 64,
                              color: const Color(0xFF60A5FA).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No hay usuarios sugeridos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Usa la búsqueda para encontrar usuarios',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _suggestedUsers.length,
                      itemBuilder: (context, index) {
                        return _buildUserTile(_suggestedUsers[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserModel user) {
    final currentUserId = _userService.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: user.uid),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                    radius: 28,
                    backgroundColor: const Color(0xFF1E293B),
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF60A5FA),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.followersCount} seguidores',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (currentUserId != user.uid)
                  StreamBuilder<UserModel?>(
                    stream: _userService.getUserProfileStream(user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox(
                          width: 90,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final userModel = snapshot.data!;
                      final isFollowing =
                          userModel.isFollowedBy(currentUserId ?? '');

                      return ElevatedButton(
                        onPressed: () async {
                          if (isFollowing) {
                            await _userService.unfollowUser(user.uid);
                          } else {
                            await _userService.followUser(user.uid);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? const Color(0xFF334155)
                              : const Color(0xFF60A5FA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          minimumSize: const Size(90, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFollowing ? 'Siguiendo' : 'Seguir',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF60A5FA),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Tú',
                      style: TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
