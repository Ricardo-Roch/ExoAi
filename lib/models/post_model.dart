import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String content;
  final String? imageUrl;
  final List<String> likedBy; // CAMBIADO de 'likes' a 'likedBy'
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.content,
    this.imageUrl,
    required this.likedBy,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  // Convertir desde Firestore
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario',
      userPhoto: data['userPhoto'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likedBy: List<String>.from(data['likedBy'] ?? []), // CAMBIADO
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'content': content,
      'imageUrl': imageUrl,
      'likedBy': likedBy, // CAMBIADO
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Verificar si el usuario dio like
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}
