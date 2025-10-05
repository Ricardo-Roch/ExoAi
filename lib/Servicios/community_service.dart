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

    final batch = _firestore.batch();

    // Crear el post
    final postRef = _firestore.collection('posts').doc();
    batch.set(postRef, {
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario',
      'userPhoto': user.photoURL,
      'content': content,
      'imageUrl': imageUrl,
      'likedBy': [], // CAMBIADO de 'likes' a 'likedBy'
      'likesCount': 0,
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Incrementar contador de posts del usuario
    final userRef = _firestore.collection('users').doc(user.uid);
    batch.update(userRef, {
      'postsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

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

    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((postsSnapshot) async {
      // Obtener la lista de usuarios que sigue
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final following = List<String>.from(userDoc.data()?['following'] ?? []);

      // Agregar el propio usuario
      following.add(user.uid);

      if (following.isEmpty) return <Post>[];

      // Filtrar posts en memoria
      final posts = postsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => following.contains(post.userId))
          .toList();

      return posts;
    });
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

  // Dar like a un post - CORREGIDO
  Future<void> toggleLike(String postId) async {
    final user = currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return;

      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);

      if (likedBy.contains(user.uid)) {
        // Quitar like
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Agregar like
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Eliminar post
  Future<void> deletePost(String postId) async {
    final user = currentUser;
    if (user == null) return;

    final postDoc = await _firestore.collection('posts').doc(postId).get();

    // Verificar que el usuario sea el dueño del post
    if (postDoc.data()?['userId'] == user.uid) {
      final batch = _firestore.batch();

      // Eliminar comentarios del post
      final comments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (var comment in comments.docs) {
        batch.delete(comment.reference);
      }

      // Eliminar el post
      batch.delete(_firestore.collection('posts').doc(postId));

      // Decrementar contador de posts del usuario
      batch.update(_firestore.collection('users').doc(user.uid), {
        'postsCount': FieldValue.increment(-1),
      });

      await batch.commit();
    }
  }

  // COMENTARIOS

  // Agregar comentario
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final batch = _firestore.batch();

    // Agregar comentario
    final commentRef = _firestore.collection('comments').doc();
    batch.set(commentRef, {
      'postId': postId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario',
      'userPhoto': user.photoURL,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Incrementar contador de comentarios en el post
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Obtener comentarios de un post
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

  // Eliminar comentario
  Future<void> deleteComment(String commentId, String postId) async {
    final user = currentUser;
    if (user == null) return;

    final commentDoc =
        await _firestore.collection('comments').doc(commentId).get();

    // Verificar que el usuario sea el dueño del comentario
    if (commentDoc.data()?['userId'] == user.uid) {
      final batch = _firestore.batch();

      batch.delete(_firestore.collection('comments').doc(commentId));

      // Decrementar contador de comentarios en el post
      batch.update(_firestore.collection('posts').doc(postId), {
        'commentsCount': FieldValue.increment(-1),
      });

      await batch.commit();
    }
  }

  // USUARIOS

  // Guardar/actualizar información del usuario
  Future<void> saveUserData() async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? 'Usuario',
      'email': user.email ?? '',
      'photoURL': user.photoURL,
      'bio': '',
      'followers': [],
      'following': [],
      'postsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
