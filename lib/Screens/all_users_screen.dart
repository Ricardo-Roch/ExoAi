// lib/Screens/all_users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../Servicios/user_service.dart';
import 'user_profile_screen.dart';

class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Usuarios Registrados'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    'No hay usuarios registrados',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _UserTile(user: users[index]);
            },
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final currentUserId = userService.currentUser?.uid;

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
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: user.uid),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF60A5FA),
              width: 2,
            ),
          ),
          child: CircleAvatar(
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
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${user.followersCount} seguidores · ${user.postsCount} posts',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: currentUserId != user.uid
            ? StreamBuilder<UserModel?>(
                stream: userService.getUserProfileStream(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      width: 80,
                      height: 32,
                    );
                  }

                  final userModel = snapshot.data!;
                  final isFollowing =
                      userModel.isFollowedBy(currentUserId ?? '');

                  return ElevatedButton(
                    onPressed: () async {
                      if (isFollowing) {
                        await userService.unfollowUser(user.uid);
                      } else {
                        await userService.followUser(user.uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? const Color(0xFF334155)
                          : const Color(0xFF60A5FA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Siguiendo' : 'Seguir',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tú',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
