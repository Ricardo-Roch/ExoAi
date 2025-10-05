// lib/Servicios/community_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityService {
  // Singleton pattern para evitar múltiples instancias
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

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
      'likedBy': [], // Cambiado de 'likes' a 'likedBy' para consistencia
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
      try {
        // Obtener la lista de usuarios que sigue
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
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
      } catch (e) {
        print('Error en getFollowingPosts: $e');
        return <Post>[];
      }
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

  // Dar like a un post - OPTIMIZADO CON TRANSACTION
  Future<void> toggleLike(String postId) async {
    final user = currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    try {
// En toggleLike, cambia todas las referencias de 'likedBy' a 'likes'
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post no existe');
        }

        final data = postDoc.data()!;
        final likes = List<String>.from(data['likes'] ?? []); // Cambio aquí
        final likesCount = (data['likesCount'] ?? 0) as int;

        if (likes.contains(user.uid)) {
          transaction.update(postRef, {
            'likes': FieldValue.arrayRemove([user.uid]), // Cambio aquí
            'likesCount': likesCount > 0 ? likesCount - 1 : 0,
          });
        } else {
          transaction.update(postRef, {
            'likes': FieldValue.arrayUnion([user.uid]), // Cambio aquí
            'likesCount': likesCount + 1,
          });
        }
      });
    } catch (e) {
      print('Error en toggleLike: $e');
      rethrow;
    }
  }

  // Eliminar post
  Future<void> deletePost(String postId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      // Verificar que el usuario sea el dueño del post
      if (postDoc.data()?['userId'] != user.uid) {
        throw Exception('No tienes permiso para eliminar este post');
      }

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
    } catch (e) {
      print('Error en deletePost: $e');
      rethrow;
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

    try {
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
    } catch (e) {
      print('Error en addComment: $e');
      rethrow;
    }
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
    }).handleError((error) {
      print('Error en getComments: $error');
      return <Comment>[];
    });
  }

  // Eliminar comentario
  Future<void> deleteComment(String commentId, String postId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();

      // Verificar que el usuario sea el dueño del comentario
      if (commentDoc.data()?['userId'] != user.uid) {
        throw Exception('No tienes permiso para eliminar este comentario');
      }

      final batch = _firestore.batch();

      batch.delete(_firestore.collection('comments').doc(commentId));

      // Decrementar contador de comentarios en el post
      batch.update(_firestore.collection('posts').doc(postId), {
        'commentsCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Error en deleteComment: $e');
      rethrow;
    }
  }

  // USUARIOS

  // Guardar/actualizar información del usuario
  Future<void> saveUserData() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Si el usuario ya existe, solo actualizar campos específicos
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': user.displayName ?? 'Usuario',
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Si es un usuario nuevo, crear el documento completo
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'photoURL': user.photoURL,
          'followers': [],
          'following': [],
          'postsCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error en saveUserData: $e');
      rethrow;
    }
  }

  // Obtener datos de un usuario
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data();
    } catch (e) {
      print('Error en getUserData: $e');
      return null;
    }
  }

  // Seguir/dejar de seguir usuario
  Future<void> toggleFollow(String targetUserId) async {
    final user = currentUser;
    if (user == null) return;
    if (user.uid == targetUserId) return; // No puedes seguirte a ti mismo

    try {
      final currentUserRef = _firestore.collection('users').doc(user.uid);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((transaction) async {
        final currentUserDoc = await transaction.get(currentUserRef);

        if (!currentUserDoc.exists) return;

        final following =
            List<String>.from(currentUserDoc.data()?['following'] ?? []);

        if (following.contains(targetUserId)) {
          // Dejar de seguir
          transaction.update(currentUserRef, {
            'following': FieldValue.arrayRemove([targetUserId]),
          });
          transaction.update(targetUserRef, {
            'followers': FieldValue.arrayRemove([user.uid]),
          });
        } else {
          // Seguir
          transaction.update(currentUserRef, {
            'following': FieldValue.arrayUnion([targetUserId]),
          });
          transaction.update(targetUserRef, {
            'followers': FieldValue.arrayUnion([user.uid]),
          });
        }
      });
    } catch (e) {
      print('Error en toggleFollow: $e');
      rethrow;
    }
  }

  // Dispose para limpiar recursos si es necesario
  void dispose() {
    // Aquí puedes cancelar listeners si los tienes
  }
}
