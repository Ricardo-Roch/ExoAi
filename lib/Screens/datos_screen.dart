import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExoplanetScreen extends StatefulWidget {
  const ExoplanetScreen({Key? key}) : super(key: key);

  @override
  State<ExoplanetScreen> createState() => _ExoplanetScreenState();
}

class _ExoplanetScreenState extends State<ExoplanetScreen> {
  List<ExoplanetData> _exoplanets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _rawJson; // Para debug

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
      final response = await http.get(
        Uri.parse('https://back-exoai.onrender.com/datasets/preview?n=50'),
      );

      if (response.statusCode == 200) {
        _rawJson = response.body; // Guarda el JSON crudo para debug
        final jsonData = jsonDecode(response.body);

        print('JSON Structure: ${jsonData.keys}'); // Debug

        _exoplanets = _parseExoplanets(jsonData);

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error completo: $e'); // Debug
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ExoplanetData> _parseExoplanets(Map<String, dynamic> jsonData) {
    List<ExoplanetData> exoplanets = [];

    // Verifica si tiene la estructura de "datasets"
    if (jsonData.containsKey('datasets')) {
      final datasets = jsonData['datasets'] as Map<String, dynamic>;

      datasets.forEach((datasetName, datasetContent) {
        if (datasetContent is Map && datasetContent.containsKey('head')) {
          final items = datasetContent['head'] as List;
          print('Dataset $datasetName tiene ${items.length} items'); // Debug

          for (var item in items) {
            String? planetName = _extractPlanetName(item, datasetName);

            if (planetName != null) {
              exoplanets.add(ExoplanetData(
                name: planetName,
                dataset: datasetName,
                allFields: Map<String, dynamic>.from(item),
              ));
            }
          }
        }
      });
    } else {
      // Si no tiene "datasets", intenta parsear directamente
      jsonData.forEach((datasetName, datasetContent) {
        if (datasetContent is Map && datasetContent.containsKey('head')) {
          final items = datasetContent['head'] as List;

          for (var item in items) {
            String? planetName = _extractPlanetName(item, datasetName);

            if (planetName != null) {
              exoplanets.add(ExoplanetData(
                name: planetName,
                dataset: datasetName,
                allFields: Map<String, dynamic>.from(item),
              ));
            }
          }
        }
      });
    }

    print('Total planetas parseados: ${exoplanets.length}'); // Debug
    exoplanets.sort((a, b) => a.name.compareTo(b.name));
    return exoplanets;
  }

  String? _extractPlanetName(Map<String, dynamic> item, String datasetName) {
    // Intenta múltiples campos según el dataset
    if (datasetName == 'cumulative') {
      return item['kepler_name'] ?? item['kepoi_name'];
    } else if (datasetName == 'TOI') {
      return item['toipfxstr'] ?? item['tidstr'] ?? 'TOI-${item['toipfx']}';
    } else if (datasetName == 'k2pandc') {
      return item['k2_name'] ?? item['pl_name'];
    }

    // Fallback: busca cualquier campo con "name"
    return item['pl_name'] ??
        item['kepler_name'] ??
        item['k2_name'] ??
        item['name'];
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
            if (_rawJson != null) ...[
              const SizedBox(height: 16),
              const Text(
                'JSON recibido:',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _rawJson!.substring(
                      0, _rawJson!.length > 500 ? 500 : _rawJson!.length),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_exoplanets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Color(0xFF60A5FA)),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron exoplanetas',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

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
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  child: Icon(Icons.public, size: 80, color: Color(0xFF60A5FA)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        'Total', '${_exoplanets.length}', Icons.public),
                    _buildStatItem(
                        'Datasets', _getUniqueDatasets(), Icons.dataset),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPlanetCard(_exoplanets[index]),
                childCount: _exoplanets.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  String _getUniqueDatasets() {
    final datasets = _exoplanets.map((e) => e.dataset).toSet();
    return '${datasets.length}';
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
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPlanetCard(ExoplanetData planet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          planet.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Dataset: ${planet.dataset}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.public, color: Color(0xFF60A5FA)),
        ),
        iconColor: const Color(0xFF60A5FA),
        collapsedIconColor: const Color(0xFF60A5FA),
        children: [_buildAllFields(planet.allFields)],
      ),
    );
  }

  Widget _buildAllFields(Map<String, dynamic> fields) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF475569), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total de campos: ${fields.length}',
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Divider(color: Color(0xFF475569), height: 24),
          ...fields.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatValue(entry.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is double) {
      return value.toStringAsFixed(6);
    }
    if (value is int) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }
}

class ExoplanetData {
  final String name;
  final String dataset;
  final Map<String, dynamic> allFields;

  ExoplanetData({
    required this.name,
    required this.dataset,
    required this.allFields,
  });
}
