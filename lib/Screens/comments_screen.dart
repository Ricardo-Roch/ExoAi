import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../Servicios/community_service.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _communityService = CommunityService();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await _communityService.addComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Post original
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.post.userPhoto != null
                          ? NetworkImage(widget.post.userPhoto!)
                          : null,
                      child: widget.post.userPhoto == null
                          ? Text(widget.post.userName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeago.format(widget.post.createdAt, locale: 'es'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.post.content),
              ],
            ),
          ),

          // Lista de comentarios
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _communityService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay comentarios aún',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sé el primero en comentar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwner =
                        comment.userId == _communityService.currentUser?.uid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.userPhoto != null
                            ? NetworkImage(comment.userPhoto!)
                            : null,
                        child: comment.userPhoto == null
                            ? Text(comment.userName[0].toUpperCase())
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(comment.createdAt, locale: 'es'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(comment.content),
                      ),
                      trailing: isOwner
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteComment(comment),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Campo para escribir comentario
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isPosting ? null : _addComment,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Estás seguro de eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _communityService.deleteComment(comment.id, widget.post.id);
    }
  }
}
