import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../Servicios/community_service.dart';
import '../Screens/user_profile_screen.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Post post;

  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.comment,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Comentarios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF334155), height: 1),

              // Lista de comentarios
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: _communityService.getComments(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF60A5FA),
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF60A5FA).withOpacity(0.1),
                                    const Color(0xFF60A5FA).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFF60A5FA).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: const Color(0xFF60A5FA).withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay comentarios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sé el primero en comentar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isOwner = comment.userId ==
                            _communityService.currentUser?.uid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                          userId: comment.userId),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF60A5FA),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF1E293B),
                                    backgroundImage: comment.userPhoto != null
                                        ? NetworkImage(comment.userPhoto!)
                                        : null,
                                    child: comment.userPhoto == null
                                        ? Text(
                                            comment.userName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF60A5FA),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            comment.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeago.format(comment.createdAt,
                                              locale: 'es'),
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onPressed: () => _deleteComment(comment),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Campo para escribir comentario
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Escribe un comentario...',
                              hintStyle: TextStyle(color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF60A5FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: _isPosting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isPosting ? null : _addComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        title: const Text(
          'Eliminar comentario',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de eliminar este comentario?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF60A5FA)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
