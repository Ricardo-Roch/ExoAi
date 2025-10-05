// lib/Screens/followers_list_screen.dart
import 'package:flutter/material.dart';
import '../Servicios/user_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

class FollowersListScreen extends StatelessWidget {
  final String userId;
  final String title;

  const FollowersListScreen({
    Key? key,
    required this.userId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userService.getFollowers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay seguidores',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserListTile(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class FollowingListScreen extends StatelessWidget {
  final String userId;
  final String title;

  const FollowingListScreen({
    Key? key,
    required this.userId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userService.getFollowing(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sigue a nadie',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserListTile(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class UserListTile extends StatelessWidget {
  final UserModel user;

  const UserListTile({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final currentUserId = userService.currentUser?.uid;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: user.uid),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF1E293B),
        backgroundImage:
            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        child: user.photoURL == null
            ? Text(
                user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        user.bio ?? user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: currentUserId != user.uid
          ? StreamBuilder<UserModel?>(
              stream: userService.getUserProfileStream(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final userModel = snapshot.data!;
                final isFollowing = userModel.isFollowedBy(currentUserId ?? '');

                return TextButton(
                  onPressed: () async {
                    if (isFollowing) {
                      await userService.unfollowUser(user.uid);
                    } else {
                      await userService.followUser(user.uid);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isFollowing
                        ? const Color(0xFF334155)
                        : const Color(0xFF60A5FA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Siguiendo' : 'Seguir',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            )
          : null,
    );
  }
}
