// lib/Servicios/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Crear o actualizar perfil de usuario
  Future<void> saveUserProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      // Actualizar usuario existente
      await userRef.update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        if (bio != null) 'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Crear nuevo usuario
      await userRef.set({
        'displayName': displayName ?? user.displayName ?? 'Usuario',
        'email': user.email ?? '',
        'photoURL': photoURL ?? user.photoURL,
        'bio': bio ?? '',
        'followers': [],
        'following': [],
        'postsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Obtener perfil de usuario
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream del perfil de usuario
  Stream<UserModel?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Seguir a un usuario
  Future<void> followUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    if (user.uid == targetUserId)
      throw Exception('No puedes seguirte a ti mismo');

    final batch = _firestore.batch();

    // Agregar a la lista de following del usuario actual
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'following': FieldValue.arrayUnion([targetUserId]),
    });

    // Agregar a la lista de followers del usuario objetivo
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followers': FieldValue.arrayUnion([user.uid]),
    });

    await batch.commit();
  }

  // Dejar de seguir a un usuario
  Future<void> unfollowUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final batch = _firestore.batch();

    // Remover de la lista de following del usuario actual
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    batch.update(currentUserRef, {
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    // Remover de la lista de followers del usuario objetivo
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followers': FieldValue.arrayRemove([user.uid]),
    });

    await batch.commit();
  }

  // Obtener seguidores de un usuario
  Stream<List<UserModel>> getFollowers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];

      final followers = List<String>.from(doc.data()?['followers'] ?? []);
      if (followers.isEmpty) return [];

      final followerDocs = await Future.wait(
        followers.map((id) => _firestore.collection('users').doc(id).get()),
      );

      return followerDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  // Obtener usuarios que sigue
  Stream<List<UserModel>> getFollowing(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];

      final following = List<String>.from(doc.data()?['following'] ?? []);
      if (following.isEmpty) return [];

      final followingDocs = await Future.wait(
        following.map((id) => _firestore.collection('users').doc(id).get()),
      );

      return followingDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  // Buscar usuarios
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // Obtener usuarios sugeridos (no seguidos)
  Future<List<UserModel>> getSuggestedUsers() async {
    final user = currentUser;
    if (user == null) return [];

    final currentUserDoc =
        await _firestore.collection('users').doc(user.uid).get();
    final following =
        List<String>.from(currentUserDoc.data()?['following'] ?? []);

    final snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereNotIn: [...following, user.uid])
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
