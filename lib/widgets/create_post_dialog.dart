import 'package:flutter/material.dart';
import '../Servicios/community_service.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _contentController = TextEditingController();
  final _communityService = CommunityService();
  bool _isLoading = false;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        _characterCount = _contentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Escribe algo para publicar'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _communityService.createPost(
        content: _contentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Publicación creada exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;
    final user = _communityService.currentUser;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 100 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 600 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
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
            color: const Color(0xFF334155),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF60A5FA).withOpacity(0.2),
                    const Color(0xFF60A5FA).withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF334155), width: 1),
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
                      Icons.create,
                      color: Color(0xFF60A5FA),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva Publicación',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Comparte con la comunidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usuario info
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
                            backgroundColor: const Color(0xFF1E293B),
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF60A5FA),
                                    size: 24,
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
                                user?.displayName ?? 'Usuario',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Text(
                                'Publicación pública',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // TextField
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 8,
                        maxLength: 500,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '¿Qué estás pensando sobre el espacio?',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Contador de caracteres
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 16,
                              color: _characterCount > 450
                                  ? Colors.orange
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_characterCount / 500',
                              style: TextStyle(
                                color: _characterCount > 450
                                    ? Colors.orange
                                    : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: _characterCount > 450
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (_characterCount > 0)
                          Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (_characterCount / 500).clamp(0, 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _characterCount > 450
                                      ? Colors.orange
                                      : const Color(0xFF60A5FA),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF60A5FA).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF60A5FA),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sé respetuoso y comparte contenido relacionado con exploración espacial',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botón
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF60A5FA).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Publicar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
