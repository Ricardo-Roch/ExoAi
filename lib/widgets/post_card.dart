import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../Servicios/community_service.dart';
import '../Screens/comments_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final currentUserId = communityService.currentUser?.uid;
    final isOwner = currentUserId == post.userId;
    final isLiked = post.isLikedBy(currentUserId ?? '');

    // Configurar timeago en español (opcional)
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con info del usuario
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.userPhoto != null
                      ? NetworkImage(post.userPhoto!)
                      : null,
                  child: post.userPhoto == null
                      ? Text(post.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt, locale: 'es'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, post.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido del post
            Text(
              post.content,
              style: const TextStyle(fontSize: 15),
            ),

            // Imagen si existe
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botones de interacción
            Row(
              children: [
                // Like
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: () {
                    communityService.toggleLike(post.id);
                  },
                ),
                Text('${post.likesCount}'),
                const SizedBox(width: 16),

                // Comentarios
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(post: post),
                      ),
                    );
                  },
                ),
                Text('${post.commentsCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar publicación'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar'),
                      content: const Text(
                        '¿Estás seguro de eliminar esta publicación?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await CommunityService().deletePost(postId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}