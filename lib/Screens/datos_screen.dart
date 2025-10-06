import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/BackendExoplanetService.dart';
import '../Servicios/gemini_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;

class ExoplanetScreen extends StatefulWidget {
  const ExoplanetScreen({Key? key}) : super(key: key);

  @override
  State<ExoplanetScreen> createState() => _ExoplanetScreenState();
}

class _ExoplanetScreenState extends State<ExoplanetScreen> {
  final BackendExoplanetService _service = BackendExoplanetService();
  final GeminiService _geminiService = GeminiService();

  List<ExoplanetData> _exoplanets = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _backendStatus;

  final List<ExoplanetData> _fallbackExoplanets = [
    ExoplanetData(
      name: 'Kepler-452b',
      period: 384.84,
      duration: 10.5,
      depth: 0.0014,
      radius: 1.63,
      insolation: 1.11,
      teff: 5757,
      srad: 1.11,
    ),
    ExoplanetData(
      name: 'TRAPPIST-1e',
      period: 6.10,
      duration: 0.54,
      depth: 0.0066,
      radius: 0.92,
      insolation: 0.66,
      teff: 2559,
      srad: 0.12,
    ),
    ExoplanetData(
      name: 'Kepler-22b',
      period: 289.86,
      duration: 6.8,
      depth: 0.0018,
      radius: 2.4,
      insolation: 1.11,
      teff: 5518,
      srad: 0.98,
    ),
    ExoplanetData(
      name: 'Proxima Centauri b',
      period: 11.19,
      duration: 1.2,
      depth: 0.0008,
      radius: 1.17,
      insolation: 0.65,
      teff: 3042,
      srad: 0.15,
    ),
    ExoplanetData(
      name: 'GJ 1214b',
      period: 1.58,
      duration: 0.95,
      depth: 0.014,
      radius: 2.7,
      insolation: 16.3,
      teff: 3250,
      srad: 0.21,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (kIsWeb) {
      _registerIframeView();
    }
  }

  void _registerIframeView() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'nasa-eyes-iframe',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://eyes.nasa.gov/apps/solar-system/#/home'
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%';
        return iframe;
      },
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final health = await _service.checkHealth();
      setState(() => _backendStatus = health);

      final status = await _service.getTrainStatus();

      if (status['data_available'] == false) {
        await _service.fetchDatasets();
      }

      final preview = await _service.getDatasetPreview(n: 100);
      final exoplanets = _service.parseExoplanetsFromPreview(preview);

      setState(() {
        _exoplanets = exoplanets.isNotEmpty ? exoplanets : _fallbackExoplanets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _exoplanets = _fallbackExoplanets;
        _isLoading = false;
      });
    }
  }

  void _showNasaEyes() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
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
                        Icons.public,
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
                            'NASA Eyes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Solar System Explorer',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  child: const HtmlElementView(
                    viewType: 'nasa-eyes-iframe',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeExoplanet(ExoplanetData exoplanet) async {
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
              'Analizando ${exoplanet.name} con Gemini AI...',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final prompt = '''
Eres un experto en exoplanetas. Analiza este exoplaneta y destaca lo más interesante:

Nombre: ${exoplanet.name}
Radio: ${exoplanet.radius?.toStringAsFixed(2) ?? 'N/A'} R⊕ (radios terrestres)
Período orbital: ${exoplanet.period?.toStringAsFixed(2) ?? 'N/A'} días
Temperatura estelar: ${exoplanet.teff?.toStringAsFixed(0) ?? 'N/A'} K
Insolación: ${exoplanet.insolation?.toStringAsFixed(2) ?? 'N/A'} S⊕
Radio estelar: ${exoplanet.srad?.toStringAsFixed(2) ?? 'N/A'} R☉

Proporciona un análisis breve (máximo 80 palabras) en español que destaque:
1. Lo más notable de este exoplaneta
2. Su potencial para albergar vida (si aplica)
3. Comparación con la Tierra
4. Características únicas o interesantes
''';

      final response = await _geminiService.analyzeSpaceLaunch({
        'nombre': exoplanet.name,
        'proveedor': 'Kepler/TESS Mission',
        'missionName': 'Exoplanet Discovery',
        'missionDescription': prompt,
        'status': 'Discovered',
      });

      if (!mounted) return;
      Navigator.of(context).pop();

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Análisis Gemini AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              exoplanet.name,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      response,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

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
    final user = FirebaseAuth.instance.currentUser;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/Logo-02.png',
                      height: 40,
                      width: 40,
                    ),
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF60A5FA),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.public,
                              color: Color(0xFF60A5FA),
                              size: 24,
                            ),
                            onPressed: _showNasaEyes,
                            tooltip: 'NASA Eyes on Solar System',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
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
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Color(0xFF60A5FA),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
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
                    : _buildContent(),
              ),
            ],
          ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Base de Datos de Exoplanetas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total',
                            '${_exoplanets.length}',
                            Icons.explore,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Backend',
                            _backendStatus?['status'] == 'healthy'
                                ? 'OK'
                                : 'Local',
                            Icons.cloud,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Modelo',
                            _backendStatus?['model_ready'] == true
                                ? 'Listo'
                                : 'No',
                            Icons.memory,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF60A5FA), size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            exoplanet.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Radio: ${exoplanet.radius?.toStringAsFixed(2) ?? 'N/A'} R⊕',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.public,
              color: Color(0xFF60A5FA),
              size: 20,
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _analyzeExoplanet(exoplanet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF60A5FA).withOpacity(0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Analizar con Gemini AI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
