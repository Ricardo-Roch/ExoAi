import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../Servicios/community_service.dart';
import '../Servicios/gemini_service.dart';
import '../Screens/comments_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  Future<void> _analyzePostWithGemini(BuildContext context) async {
    final geminiService = GeminiService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF60A5FA)),
            const SizedBox(height: 16),
            Text(
              'Analizando publicación con Gemini AI...',
              style: TextStyle(color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final prompt = '''
Eres un experto en astronomía y exploración espacial. Analiza esta publicación de la comunidad ExoAI:

Autor: ${post.userName}
Contenido: "${post.content}"

Proporciona un análisis breve y constructivo (máximo 100 palabras) que incluya:
1. ¿Qué aspectos científicos o interesantes menciona?
2. ¿Es relevante para la exploración espacial o exoplanetas?
3. Sugerencias de temas relacionados para profundizar
4. Comentario educativo o dato curioso relacionado

Sé amigable, educativo y motiva la curiosidad científica.
''';

      final analysis = await geminiService.analyzeSpaceLaunch({
        'nombre': 'Post Analysis',
        'proveedor': post.userName,
        'missionName': 'Community Post',
        'missionDescription': prompt,
        'status': 'Analyzed',
      });

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF60A5FA),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF60A5FA).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF60A5FA),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis Gemini AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Perspectiva científica',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF60A5FA).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: post.userPhoto != null
                                    ? NetworkImage(post.userPhoto!)
                                    : null,
                                child: post.userPhoto == null
                                    ? Text(post.userName[0].toUpperCase())
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"${post.content}"',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          analysis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 15,
                            height: 1.8,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();
    final currentUserId = communityService.currentUser?.uid;
    final isOwner = currentUserId == post.userId;
    final isLiked = post.isLikedBy(currentUserId ?? '');

    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con info del usuario
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF60A5FA),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF0F172A),
                    backgroundImage: post.userPhoto != null
                        ? NetworkImage(post.userPhoto!)
                        : null,
                    child: post.userPhoto == null
                        ? Text(
                            post.userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt, locale: 'es'),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                    onPressed: () => _showOptions(context, post.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenido del post
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.5,
              ),
            ),

            // Imagen si existe
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Separador
            Container(
              height: 1,
              color: const Color(0xFF334155),
            ),

            const SizedBox(height: 12),

            // Botones de interacción
            Row(
              children: [
                // Like
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likesCount}',
                  color: isLiked ? Colors.red : const Color(0xFF94A3B8),
                  onPressed: () {
                    communityService.toggleLike(post.id);
                  },
                ),

                const SizedBox(width: 12),

                // Comentarios
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '${post.commentsCount}',
                  color: const Color(0xFF94A3B8),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(post: post),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Botón de Gemini AI
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF60A5FA).withOpacity(0.2),
                        const Color(0xFF8B5CF6).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withOpacity(0.5),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _analyzePostWithGemini(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Color(0xFF60A5FA),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Analizar',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 13,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar publicación',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        '¿Estás seguro de eliminar esta publicación?',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
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
