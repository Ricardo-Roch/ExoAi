// lib/Servicios/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // POSTS

  // Crear una publicación
  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // PRIMERO: Asegurar que el documento del usuario existe
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      // Crear el documento del usuario si no existe
      await userRef.set({
        'displayName': user.displayName ?? 'Usuario',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'bio': '',
        'followers': [],
        'following': [],
        'postsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final batch = _firestore.batch();

    // Crear el post
    final postRef = _firestore.collection('posts').doc();
    batch.set(postRef, {
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario',
      'userPhoto': user.photoURL,
      'content': content,
      'imageUrl': imageUrl,
      'likes': [],
      'likesCount': 0,
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Incrementar contador de posts del usuario
    batch.update(userRef, {
      'postsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ... resto del código igual

  // Obtener posts (stream en tiempo real)
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Obtener posts de usuarios que sigue (feed personalizado)
  Stream<List<Post>> getFollowingPosts() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap(
      (userDoc) async {
        if (!userDoc.exists) return <Post>[];

        final following = List<String>.from(userDoc.data()?['following'] ?? []);

        // Siempre incluir posts del propio usuario
        final userIds = [...following, user.uid];

        if (userIds.isEmpty) return <Post>[];

        final postsSnapshot = await _firestore
            .collection('posts')
            .where('userId', whereIn: userIds)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        return postsSnapshot.docs
            .map((doc) => Post.fromFirestore(doc))
            .toList();
      },
    );
  }

  // Obtener posts de un usuario específico
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Dar like a un post
  Future<void> toggleLike(String postId) async {
    final user = currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final likes = List<String>.from(postDoc.data()?['likes'] ?? []);

    if (likes.contains(user.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  // Eliminar post
  Future<void> deletePost(String postId) async {
    final user = currentUser;
    if (user == null) return;

    final postDoc = await _firestore.collection('posts').doc(postId).get();

    if (postDoc.data()?['userId'] == user.uid) {
      final batch = _firestore.batch();

      final comments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (var comment in comments.docs) {
        batch.delete(comment.reference);
      }

      batch.delete(_firestore.collection('posts').doc(postId));

      final userRef = _firestore.collection('users').doc(user.uid);
      batch.update(userRef, {
        'postsCount': FieldValue.increment(-1),
      });

      await batch.commit();
    }
  }

  // COMENTARIOS

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final batch = _firestore.batch();

    final commentRef = _firestore.collection('comments').doc();
    batch.set(commentRef, {
      'postId': postId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario',
      'userPhoto': user.photoURL,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteComment(String commentId, String postId) async {
    final user = currentUser;
    if (user == null) return;

    final commentDoc =
        await _firestore.collection('comments').doc(commentId).get();

    if (commentDoc.data()?['userId'] == user.uid) {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('comments').doc(commentId));
      batch.update(_firestore.collection('posts').doc(postId), {
        'commentsCount': FieldValue.increment(-1),
      });
      await batch.commit();
    }
  }

  Future<void> saveUserData() async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? 'Usuario',
      'email': user.email ?? '',
      'photoURL': user.photoURL,
      'followers': [],
      'following': [],
      'postsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
