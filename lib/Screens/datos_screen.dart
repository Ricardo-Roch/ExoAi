import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExoplanetScreen extends StatefulWidget {
  const ExoplanetScreen({Key? key}) : super(key: key);

  @override
  State<ExoplanetScreen> createState() => _ExoplanetScreenState();
}

class _ExoplanetScreenState extends State<ExoplanetScreen> {
  Map<String, List<ExoplanetData>> _groupedExoplanets = {};
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _storageInfo;

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
      // 1. Primero llamar a /cloud/storage/list
      final storageResponse = await http.get(
        Uri.parse('https://back-exoai.onrender.com/cloud/storage/list'),
      );

      if (storageResponse.statusCode == 200) {
        _storageInfo = jsonDecode(storageResponse.body);
      }

      // 2. Luego obtener preview de exoplanetas
      final previewResponse = await http.get(
        Uri.parse('https://back-exoai.onrender.com/datasets/preview?n=2'),
      );

      if (previewResponse.statusCode == 200) {
        final previewData = jsonDecode(previewResponse.body);

        // 3. Parsear y agrupar exoplanetas por nombre
        _groupedExoplanets = _parseAndGroupExoplanets(previewData);

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Error al cargar preview: ${previewResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<ExoplanetData>> _parseAndGroupExoplanets(
      Map<String, dynamic> data) {
    Map<String, List<ExoplanetData>> grouped = {};

    // Procesar cada dataset
    data.forEach((datasetName, datasetContent) {
      if (datasetContent is Map && datasetContent.containsKey('head')) {
        final items = datasetContent['head'] as List;

        for (var item in items) {
          // Determinar el nombre del exoplaneta según el dataset
          String? planetName;

          if (datasetName == 'cumulative') {
            planetName = item['kepler_name'] ?? item['kepoi_name'];
          } else if (datasetName == 'TOI') {
            planetName = item['toipfxstr'] ?? 'TOI-${item['toipfx']}';
          } else if (datasetName == 'k2pandc') {
            planetName = item['k2_name'] ?? item['pl_name'];
          }

          if (planetName != null) {
            final exoplanet = ExoplanetData(
              name: planetName,
              period: _parseDouble(item['koi_period'] ?? item['pl_orbper']),
              duration:
                  _parseDouble(item['koi_duration'] ?? item['pl_trandur']),
              depth: _parseDouble(item['koi_depth'] ?? item['pl_trandep']),
              radius: _parseDouble(item['koi_prad'] ?? item['pl_rade']),
              insolation: _parseDouble(item['koi_insol'] ?? item['pl_insol']),
              teff: _parseDouble(item['koi_steff'] ?? item['st_teff']),
              srad: _parseDouble(item['koi_srad'] ?? item['st_rad']),
              dataset: datasetName,
              disposition:
                  item['koi_disposition'] ?? item['disposition'] ?? 'N/A',
            );

            // Agrupar por nombre base (sin letras de planeta)
            String baseName = _getBaseName(planetName);

            if (!grouped.containsKey(baseName)) {
              grouped[baseName] = [];
            }
            grouped[baseName]!.add(exoplanet);
          }
        }
      }
    });

    return grouped;
  }

  String _getBaseName(String fullName) {
    // Extraer nombre base sin letras de planetas (b, c, d, etc.)
    final patterns = [
      RegExp(r'^(Kepler-\d+)'),
      RegExp(r'^(K2-\d+)'),
      RegExp(r'^(TOI-\d+)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(fullName);
      if (match != null) {
        return match.group(1)!;
      }
    }

    return fullName;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
    final totalPlanets = _groupedExoplanets.values
        .fold<int>(0, (sum, list) => sum + list.length);

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
                          'Sistemas',
                          '${_groupedExoplanets.length}',
                          Icons.star,
                        ),
                        _buildStatItem(
                          'Planetas',
                          '$totalPlanets',
                          Icons.public,
                        ),
                        _buildStatItem(
                          'Storage',
                          _storageInfo != null ? 'OK' : 'N/A',
                          Icons.cloud,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de sistemas agrupados
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final systemName = _groupedExoplanets.keys.elementAt(index);
                  final planets = _groupedExoplanets[systemName]!;
                  return _buildSystemCard(systemName, planets);
                },
                childCount: _groupedExoplanets.length,
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

  Widget _buildSystemCard(String systemName, List<ExoplanetData> planets) {
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
          systemName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${planets.length} planeta${planets.length > 1 ? 's' : ''}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.star,
            color: Color(0xFF60A5FA),
          ),
        ),
        iconColor: const Color(0xFF60A5FA),
        collapsedIconColor: const Color(0xFF60A5FA),
        children: planets.map((planet) => _buildPlanetItem(planet)).toList(),
      ),
    );
  }

  Widget _buildPlanetItem(ExoplanetData planet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF475569),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDispositionColor(planet.disposition),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  planet.disposition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataRow(
              'Período', '${planet.period?.toStringAsFixed(2) ?? 'N/A'} días'),
          _buildDataRow(
              'Radio', '${planet.radius?.toStringAsFixed(2) ?? 'N/A'} R⊕'),
          _buildDataRow(
              'Temp. Estelar', '${planet.teff?.toStringAsFixed(0) ?? 'N/A'} K'),
          _buildDataRow('Dataset', planet.dataset),
        ],
      ),
    );
  }

  Color _getDispositionColor(String disposition) {
    switch (disposition.toUpperCase()) {
      case 'CONFIRMED':
        return Colors.green;
      case 'CANDIDATE':
        return Colors.orange;
      case 'FALSE POSITIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class ExoplanetData {
  final String name;
  final double? period;
  final double? duration;
  final double? depth;
  final double? radius;
  final double? insolation;
  final double? teff;
  final double? srad;
  final String dataset;
  final String disposition;

  ExoplanetData({
    required this.name,
    this.period,
    this.duration,
    this.depth,
    this.radius,
    this.insolation,
    this.teff,
    this.srad,
    required this.dataset,
    required this.disposition,
  });
}
