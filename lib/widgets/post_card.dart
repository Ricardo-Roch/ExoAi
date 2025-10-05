import 'package:exo_ai/Screens/comments_screen.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../Servicios/community_service.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../Screens/user_profile_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late final CommunityService _communityService;
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _communityService = CommunityService();
    final currentUserId = _communityService.currentUser?.uid ?? '';
    _isLiked = widget.post.isLikedBy(currentUserId);
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;

    // Configurar timeago en español una sola vez
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await _communityService.toggleLike(widget.post.id);
    } catch (e) {
      // Revertir cambios si falla
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el like'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _communityService.currentUser?.uid;
    final isOwner = currentUserId == widget.post.userId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con info del usuario
            _buildHeader(context, isOwner),
            const SizedBox(height: 16),

            // Contenido del post
            Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),

            // Imagen si existe
            if (widget.post.imageUrl != null) ...[
              const SizedBox(height: 16),
              _buildImage(),
            ],

            const SizedBox(height: 16),

            // Separador
            _buildDivider(),

            const SizedBox(height: 12),

            // Botones de interacción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOwner) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(context),
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
              radius: 22,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: widget.post.userPhoto != null
                  ? NetworkImage(widget.post.userPhoto!)
                  : null,
              child: widget.post.userPhoto == null
                  ? Text(
                      widget.post.userName.isNotEmpty
                          ? widget.post.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
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
          child: GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(widget.post.createdAt, locale: 'es'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOwner)
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF94A3B8),
            ),
            onPressed: () => _showOptions(context, widget.post.id),
          ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        widget.post.imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF60A5FA),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF334155).withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Like
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _handleLike,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_likesCount',
                      style: TextStyle(
                        color: _isLiked ? Colors.red : const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Separador vertical
        Container(
          width: 1,
          height: 24,
          color: const Color(0xFF334155),
        ),

        // Comentarios
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCommentsBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_commentsCount',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: widget.post.userId),
      ),
    );
  }

  Future<void> _showCommentsBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    );

    // Actualizar contador de comentarios si cambió
    if (result != null && result is int) {
      setState(() {
        _commentsCount = result;
      });
    }
  }

  void _showOptions(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: Colors.red[400]),
                ),
                title: const Text(
                  'Eliminar publicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Esta acción no se puede deshacer',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                onTap: () => _confirmDelete(context, postId),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String postId) async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta publicación?',
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

    if (confirm == true && mounted) {
      try {
        await _communityService.deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la publicación'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
