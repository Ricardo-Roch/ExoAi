import 'package:flutter/material.dart';

class VisualizacionesScreen extends StatefulWidget {
  const VisualizacionesScreen({Key? key}) : super(key: key);

  @override
  State<VisualizacionesScreen> createState() => _VisualizacionesScreenState();
}

class _VisualizacionesScreenState extends State<VisualizacionesScreen> {
  String _selectedCategory = 'Todas';
  final List<String> _categories = [
    'Todas',
    'Gráficos',
    'Dashboards',
    'Reportes',
  ];

  final List<Map<String, dynamic>> _visualizations = [
    {
      'title': 'Análisis de Ventas',
      'type': 'Dashboard',
      'icon': Icons.bar_chart,
      'color': Colors.blue,
      'description': 'Métricas de ventas trimestrales',
      'lastUpdate': 'Hace 1 hora',
      'views': '1.2k',
    },
    {
      'title': 'Tendencias de Usuario',
      'type': 'Gráfico',
      'icon': Icons.show_chart,
      'color': Colors.green,
      'description': 'Crecimiento de usuarios activos',
      'lastUpdate': 'Hace 3 horas',
      'views': '856',
    },
    {
      'title': 'Mapa de Calor',
      'type': 'Dashboard',
      'icon': Icons.map,
      'color': Colors.orange,
      'description': 'Distribución geográfica de clientes',
      'lastUpdate': 'Hace 5 horas',
      'views': '623',
    },
    {
      'title': 'Reporte Financiero',
      'type': 'Reporte',
      'icon': Icons.assessment,
      'color': Colors.purple,
      'description': 'Estado financiero mensual',
      'lastUpdate': 'Hace 1 día',
      'views': '2.1k',
    },
    {
      'title': 'Satisfacción del Cliente',
      'type': 'Gráfico',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.pink,
      'description': 'NPS y métricas de satisfacción',
      'lastUpdate': 'Hace 2 días',
      'views': '945',
    },
    {
      'title': 'Análisis de Inventario',
      'type': 'Dashboard',
      'icon': Icons.inventory,
      'color': Colors.teal,
      'description': 'Stock y movimientos de inventario',
      'lastUpdate': 'Hace 6 horas',
      'views': '734',
    },
  ];

  List<Map<String, dynamic>> get _filteredVisualizations {
    if (_selectedCategory == 'Todas') {
      return _visualizations;
    }
    return _visualizations
        .where((viz) => viz['type'] == _selectedCategory.replaceAll('s', ''))
        .toList();
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
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visualizaciones',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Explora tus datos de forma visual',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.blue[600]),
                        onPressed: () {
                          _showCreateVisualizationDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filtros por categoría
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.blue[700]
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue[300]!
                                : Colors.grey[300]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Estadísticas rápidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${_visualizations.length}',
                    Icons.dashboard_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Vistas',
                    '8.4k',
                    Icons.visibility_outlined,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grid de visualizaciones
          Expanded(
            child: _filteredVisualizations.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredVisualizations.length,
                    itemBuilder: (context, index) {
                      final viz = _filteredVisualizations[index];
                      return _buildVisualizationCard(
                        title: viz['title'],
                        type: viz['type'],
                        icon: viz['icon'],
                        color: viz['color'],
                        description: viz['description'],
                        lastUpdate: viz['lastUpdate'],
                        views: viz['views'],
                      );
                    },
                  ),
          ),
        ],
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }

  Widget _buildVisualizationCard({
    required String title,
    required String type,
    required IconData icon,
    required Color color,
    required String description,
    required String lastUpdate,
    required String views,
  }) {
    return InkWell(
      onTap: () {
        _showVisualizationDetail(title, type, description);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono y tipo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lastUpdate,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          views,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay visualizaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera visualización\npara comenzar',
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

  void _showVisualizationDetail(String title, String type, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad en desarrollo'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ver Visualización Completa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVisualizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Visualización'),
        content: const Text(
            'Esta función permite crear nuevas visualizaciones de datos.'),
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
