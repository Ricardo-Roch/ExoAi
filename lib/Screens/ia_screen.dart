import 'package:flutter/material.dart';

class IAScreen extends StatefulWidget {
  const IAScreen({Key? key}) : super(key: key);

  @override
  State<IAScreen> createState() => _IAScreenState();
}

class _IAScreenState extends State<IAScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _conversations = [];
  bool _isProcessing = false;

  // Modelos de IA disponibles
  final List<Map<String, dynamic>> _aiModels = [
    {
      'name': 'GPT-4',
      'description': 'Modelo avanzado de lenguaje',
      'icon': Icons.psychology,
      'color': Colors.purple,
      'status': 'Activo',
    },
    {
      'name': 'Claude 3',
      'description': 'Asistente conversacional',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.orange,
      'status': 'Activo',
    },
    {
      'name': 'Gemini Pro',
      'description': 'Análisis multimodal',
      'icon': Icons.auto_awesome,
      'color': Colors.blue,
      'status': 'Activo',
    },
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _sendQuery() {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _conversations.add({
        'type': 'user',
        'message': _queryController.text,
        'timestamp': DateTime.now(),
      });
      _isProcessing = true;
    });

    final query = _queryController.text;
    _queryController.clear();

    // Simular respuesta de IA
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _conversations.add({
            'type': 'ai',
            'message':
                'Esta es una respuesta simulada a tu consulta: "$query". En la versión completa, aquí se mostraría la respuesta real del modelo de IA.',
            'timestamp': DateTime.now(),
          });
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inteligencia Artificial',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Interactúa con modelos de IA avanzados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Modelos disponibles (carousel horizontal)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _aiModels.length,
              itemBuilder: (context, index) {
                final model = _aiModels[index];
                return _buildModelCard(
                  name: model['name'],
                  description: model['description'],
                  icon: model['icon'],
                  color: model['color'],
                  status: model['status'],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Área de conversación
          Expanded(
            child: _conversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationList(),
          ),

          // Input de consulta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta aquí...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.blue[600]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isProcessing ? null : _sendQuery,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Inicia una conversación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe tu consulta y obtén respuestas\nimpulsadas por IA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final message = _conversations[index];
        final isUser = message['type'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[600] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message['message'],
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        );
      },
    );
  }
}
