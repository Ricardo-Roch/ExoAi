import 'package:flutter/material.dart';
import 'dart:convert';
import '../Servicios/BackendExoplanetService.dart';

// Importa tu servicio
// import 'backend_exoplanet_service.dart';

class ExoplanetScreen extends StatefulWidget {
  const ExoplanetScreen({Key? key}) : super(key: key);

  @override
  State<ExoplanetScreen> createState() => _ExoplanetScreenState();
}

class _ExoplanetScreenState extends State<ExoplanetScreen> {
  final BackendExoplanetService _service = BackendExoplanetService();

  List<ExoplanetData> _exoplanets = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _backendStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Verificar estado del backend
      final health = await _service.checkHealth();
      setState(() => _backendStatus = health);

      // 2. Verificar si hay datos
      final status = await _service.getTrainStatus();

      // 3. Si no hay datos, descargarlos
      if (status['data_available'] == false) {
        await _service.fetchDatasets();
      }

      // 4. Obtener preview de exoplanetas
      final preview = await _service.getDatasetPreview(n: 100);

      // 5. Parsear exoplanetas
      final exoplanets = _service.parseExoplanetsFromPreview(preview);

      setState(() {
        _exoplanets = exoplanets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF172554),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF60A5FA)),
                      SizedBox(height: 16),
                      Text(
                        'Cargando exoplanetas...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF60A5FA),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Exoplanetas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF60A5FA).withOpacity(0.3),
                      const Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.public,
                    size: 80,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ),
            ),
          ),

          // Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total',
                          '${_exoplanets.length}',
                          Icons.explore,
                        ),
                        _buildStatItem(
                          'Backend',
                          _backendStatus?['status'] == 'healthy'
                              ? 'OK'
                              : 'Error',
                          Icons.cloud,
                        ),
                        _buildStatItem(
                          'Modelo',
                          _backendStatus?['model_ready'] == true
                              ? 'Listo'
                              : 'No',
                          Icons.memory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de exoplanetas
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exoplanet = _exoplanets[index];
                  return _buildExoplanetCard(exoplanet);
                },
                childCount: _exoplanets.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExoplanetCard(ExoplanetData exoplanet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          exoplanet.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Radio: ${exoplanet.radius?.toStringAsFixed(2) ?? 'N/A'} R⊕',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.public,
            color: Color(0xFF60A5FA),
          ),
        ),
        iconColor: const Color(0xFF60A5FA),
        collapsedIconColor: const Color(0xFF60A5FA),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                _buildDataRow('Período Orbital',
                    '${exoplanet.period?.toStringAsFixed(2) ?? 'N/A'} días'),
                _buildDataRow('Duración Tránsito',
                    '${exoplanet.duration?.toStringAsFixed(2) ?? 'N/A'} h'),
                _buildDataRow('Profundidad',
                    '${exoplanet.depth?.toStringAsFixed(4) ?? 'N/A'}'),
                _buildDataRow('Insolación',
                    '${exoplanet.insolation?.toStringAsFixed(2) ?? 'N/A'} S⊕'),
                _buildDataRow('Temp. Estelar',
                    '${exoplanet.teff?.toStringAsFixed(0) ?? 'N/A'} K'),
                _buildDataRow('Radio Estelar',
                    '${exoplanet.srad?.toStringAsFixed(2) ?? 'N/A'} R☉'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
