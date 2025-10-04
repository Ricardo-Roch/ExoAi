import 'package:flutter/material.dart';

class DatosScreen extends StatefulWidget {
  const DatosScreen({Key? key}) : super(key: key);

  @override
  State<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends State<DatosScreen> {
  // Ejemplo de datos que podrías cargar
  final List<Map<String, dynamic>> _datasets = [
    {
      'title': 'Dataset de Entrenamiento',
      'size': '2.4 GB',
      'items': '15,234 registros',
      'lastUpdate': 'Hace 2 horas',
      'icon': Icons.storage,
      'color': Colors.blue,
    },
    {
      'title': 'Datos de Usuarios',
      'size': '156 MB',
      'items': '1,043 usuarios',
      'lastUpdate': 'Hace 5 minutos',
      'icon': Icons.people,
      'color': Colors.green,
    },
    {
      'title': 'Logs del Sistema',
      'size': '89 MB',
      'items': '45,678 eventos',
      'lastUpdate': 'Hace 1 hora',
      'icon': Icons.description,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Datos',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona tus datasets y bases de datos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Estadísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '2.6 GB',
                    Icons.cloud_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Archivos',
                    '3',
                    Icons.folder_outlined,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lista de datasets
            Expanded(
              child: ListView.builder(
                itemCount: _datasets.length,
                itemBuilder: (context, index) {
                  final dataset = _datasets[index];
                  return _buildDatasetCard(
                    title: dataset['title'],
                    size: dataset['size'],
                    items: dataset['items'],
                    lastUpdate: dataset['lastUpdate'],
                    icon: dataset['icon'],
                    color: dataset['color'],
                  );
                },
              ),
            ),

            // Botón para agregar datos
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para subir datos
                  _showUploadDialog();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir Nuevo Dataset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetCard({
    required String title,
    required String size,
    required String items,
    required String lastUpdate,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$size • $items',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastUpdate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir Dataset'),
        content:
            const Text('Esta función permite cargar nuevos datos al sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
            child: const Text('Subir'),
          ),
        ],
      ),
    );
  }
}
