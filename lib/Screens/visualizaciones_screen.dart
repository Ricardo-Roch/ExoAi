import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/BackendExoplanetService.dart';

// Modelo de datos para Exoplaneta
class Exoplanet {
  final String name;
  final double radiusEarth;
  final int temperatureK;
  final int distanceLy;
  final String type;
  final String starType;
  final String description;
  final String colorHex;
  final String imageHint;
  final ExoplanetData? data;

  Exoplanet({
    required this.name,
    required this.radiusEarth,
    required this.temperatureK,
    required this.distanceLy,
    required this.type,
    required this.starType,
    required this.description,
    required this.colorHex,
    required this.imageHint,
    this.data,
  });

  Color get color {
    final hexColor = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  Color get predictiveColor {
    return _calculatePredictiveColor(temperatureK, type, radiusEarth);
  }

  static Color _calculatePredictiveColor(
      int temperature, String type, double radius) {
    if (temperature < 150) {
      return Color.lerp(Color(0xFF2C3E50), Color(0xFF34495E), 0.5)!;
    }

    if (temperature < 273) {
      if (type.contains("Rocky")) {
        return Color.lerp(Color(0xFF7F8C8D), Color(0xFFBDC3C7), 0.6)!;
      }
      return Color.lerp(Color(0xFF3498DB), Color(0xFFECF0F1), 0.7)!;
    }

    if (temperature >= 273 && temperature < 373) {
      if (type == "Ocean world") {
        return Color(0xFF1E90FF);
      }
      if (type == "Earth-like") {
        return Color.lerp(Color(0xFF27AE60), Color(0xFF3498DB), 0.5)!;
      }
      if (type.contains("Rocky")) {
        return Color.lerp(Color(0xFF8B4513), Color(0xFFCD853F), 0.5)!;
      }
    }

    if (temperature >= 373 && temperature < 600) {
      if (type.contains("Neptune")) {
        return Color.lerp(Color(0xFF9B59B6), Color(0xFF3498DB), 0.6)!;
      }
      return Color.lerp(Color(0xFFE67E22), Color(0xFFF39C12), 0.5)!;
    }

    if (temperature >= 600 && temperature < 1000) {
      if (type.contains("Neptune") || type.contains("Mini")) {
        return Color.lerp(Color(0xFF8E44AD), Color(0xFFE74C3C), 0.4)!;
      }
      return Color.lerp(Color(0xFFE74C3C), Color(0xFFF39C12), 0.6)!;
    }

    if (temperature >= 1000 && temperature < 1500) {
      if (type.contains("Jupiter") && radius > 10) {
        return Color(0xFF0047AB);
      }
      return Color.lerp(Color(0xFFFF4500), Color(0xFFFF6347), 0.5)!;
    }

    if (temperature >= 1500) {
      return Color.lerp(Color(0xFFFFFFFF), Color(0xFFFFD700), 0.3)!;
    }

    if (type.contains("Gas") || type.contains("Jupiter")) {
      return Color(0xFF4169E1);
    }

    return Color(0xFF95A5A6);
  }
}

class VisualizacionesScreen extends StatefulWidget {
  const VisualizacionesScreen({Key? key}) : super(key: key);

  @override
  State<VisualizacionesScreen> createState() => _VisualizacionesScreenState();
}

class _VisualizacionesScreenState extends State<VisualizacionesScreen> {
  final PageController _pageController = PageController();
  final BackendExoplanetService _service = BackendExoplanetService();

  int _currentPage = 0;
  List<Exoplanet> exoplanets = [];
  bool _isLoading = true;

  // Datos de respaldo si falla la API
  final List<Exoplanet> _fallbackExoplanets = [
    Exoplanet(
      name: "Kepler-452b",
      radiusEarth: 1.63,
      temperatureK: 265,
      distanceLy: 1400,
      type: "Earth-like",
      starType: "G2",
      description: "Potentially habitable rocky planet with mild atmosphere.",
      colorHex: "#4A90E2",
      imageHint: "light blue planet with soft clouds",
    ),
    Exoplanet(
      name: "TRAPPIST-1e",
      radiusEarth: 0.92,
      temperatureK: 250,
      distanceLy: 39,
      type: "Rocky",
      starType: "M-dwarf",
      description: "Dark, rocky world possibly containing frozen water.",
      colorHex: "#7C6E64",
      imageHint: "brown planet under reddish light",
    ),
    Exoplanet(
      name: "Kepler-22b",
      radiusEarth: 2.4,
      temperatureK: 295,
      distanceLy: 620,
      type: "Ocean world",
      starType: "G5",
      description: "Likely covered by water with a humid atmosphere.",
      colorHex: "#1E90FF",
      imageHint: "turquoise blue planet with bright ocean glow",
    ),
    Exoplanet(
      name: "GJ 1214b",
      radiusEarth: 2.7,
      temperatureK: 550,
      distanceLy: 40,
      type: "Mini-Neptune",
      starType: "M-dwarf",
      description: "Dense atmosphere of mist and methane vapors.",
      colorHex: "#8A2BE2",
      imageHint: "violet planet with foggy glow",
    ),
    Exoplanet(
      name: "HD 189733b",
      radiusEarth: 13,
      temperatureK: 1200,
      distanceLy: 63,
      type: "Hot Jupiter",
      starType: "K",
      description: "Gas giant with violent storms and blue hues.",
      colorHex: "#0055FF",
      imageHint: "deep blue gas giant with luminous swirls",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadExoplanets();
  }

  Future<void> _loadExoplanets() async {
    setState(() => _isLoading = true);

    try {
      final status = await _service.getTrainStatus();

      if (status['data_available'] == false) {
        await _service.fetchDatasets();
      }

      final preview = await _service.getDatasetPreview(n: 20);
      final exoplanetsData = _service.parseExoplanetsFromPreview(preview);

      if (exoplanetsData.isNotEmpty) {
        // Convertir ExoplanetData a Exoplanet con clasificación
        List<Exoplanet> loadedExoplanets = [];
        for (var data in exoplanetsData.take(10)) {
          final type = _classifyExoplanet(data);
          final temp = _estimateTemperature(data);

          loadedExoplanets.add(Exoplanet(
            name: data.name,
            radiusEarth: data.radius ?? 1.0,
            temperatureK: temp,
            distanceLy: 100, // Distancia estimada
            type: type,
            starType: _classifyStarType(data.teff ?? 5778),
            description: _generateDescription(data, type),
            colorHex: "#4A90E2",
            imageHint: "",
            data: data,
          ));
        }

        setState(() {
          exoplanets = loadedExoplanets;
          _isLoading = false;
        });
      } else {
        throw Exception('No data available');
      }
    } catch (e) {
      print('Error loading exoplanets: $e');
      setState(() {
        exoplanets = _fallbackExoplanets;
        _isLoading = false;
      });
    }
  }

  String _classifyExoplanet(ExoplanetData data) {
    final radius = data.radius ?? 1.0;
    final temp = _estimateTemperature(data);

    if (radius < 1.25) {
      if (temp >= 273 && temp <= 373) {
        return "Earth-like";
      }
      return "Rocky";
    } else if (radius < 2.0) {
      return "Super-Earth";
    } else if (radius < 4.0) {
      if (temp > 500) {
        return "Mini-Neptune";
      }
      return "Neptune-like";
    } else {
      if (temp > 1000) {
        return "Hot Jupiter";
      }
      return "Gas Giant";
    }
  }

  int _estimateTemperature(ExoplanetData data) {
    final teff = data.teff ?? 5778;
    final insol = data.insolation ?? 1.0;

    // Estimación aproximada basada en insolación y temperatura estelar
    final tempEstimate = (teff * 0.1 * insol).round();
    return tempEstimate.clamp(100, 2000);
  }

  String _classifyStarType(double teff) {
    if (teff >= 7500) return "A";
    if (teff >= 6000) return "F";
    if (teff >= 5200) return "G";
    if (teff >= 3700) return "K";
    return "M";
  }

  String _generateDescription(ExoplanetData data, String type) {
    final radius = data.radius ?? 1.0;
    final temp = _estimateTemperature(data);

    if (type == "Earth-like") {
      return "Potentially habitable planet with Earth-like characteristics.";
    } else if (type == "Rocky") {
      return "Rocky planet with possible geological activity.";
    } else if (type.contains("Neptune")) {
      return "Gas planet with thick atmosphere and possible storms.";
    } else if (type.contains("Jupiter")) {
      return "Massive gas giant with extreme weather patterns.";
    }

    return "Exoplanet with unique characteristics.";
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          bottom: true,
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
              : Column(
                  children: [
                    // Header compacto
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/Logo-02.png',
                            height: 35,
                            width: 35,
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Explorador de Exoplanetas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                              radius: 16,
                              backgroundColor: const Color(0xFF1E293B),
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Color(0xFF60A5FA),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Planet Carousel
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemCount: exoplanets.length,
                            itemBuilder: (context, index) {
                              return _buildPlanetCard(exoplanets[index]);
                            },
                          ),

                          // Navigation Arrows
                          Positioned(
                            left: 20,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white, size: 32),
                              onPressed: () {
                                if (_currentPage > 0) {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                          Positioned(
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white, size: 32),
                              onPressed: () {
                                if (_currentPage < exoplanets.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Page Indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          exoplanets.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlanetCard(Exoplanet planet) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Orbital animation container
          Container(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbits
                CustomPaint(
                  size: const Size(320, 320),
                  painter: OrbitPainter(),
                ),

                // Planet Image con gradiente radial
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        planet.predictiveColor.withOpacity(0.8),
                        planet.predictiveColor.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.5, 0.8, 1.0],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(35),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: planet.predictiveColor.withOpacity(0.6),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(
                          painter: PlanetPainter(planet: planet),
                        ),
                      ),
                    ),
                  ),
                ),

                // Orbital dots
                Positioned(
                  top: 40,
                  right: 90,
                  child: _buildOrbitDot(),
                ),
                Positioned(
                  bottom: 60,
                  left: 80,
                  child: _buildOrbitDot(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Planet Info Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Planet Name
                Text(
                  planet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Planet Type
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: planet.predictiveColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    planet.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  planet.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Radius',
                        '${planet.radiusEarth.toStringAsFixed(2)}x Earth',
                        Icons.radio_button_unchecked,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'Temp',
                        '${planet.temperatureK}K',
                        Icons.thermostat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Distance',
                        '${planet.distanceLy} ly',
                        Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'Star Type',
                        planet.starType,
                        Icons.wb_sunny,
                      ),
                    ),
                  ],
                ),

                // Si hay datos adicionales, mostrarlos
                if (planet.data != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'Datos Adicionales:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (planet.data!.period != null)
                    _buildDataRow('Período:',
                        '${planet.data!.period!.toStringAsFixed(2)} días'),
                  if (planet.data!.insolation != null)
                    _buildDataRow('Insolación:',
                        '${planet.data!.insolation!.toStringAsFixed(2)} S⊕'),
                  if (planet.data!.teff != null)
                    _buildDataRow('Temp. Estelar:',
                        '${planet.data!.teff!.toStringAsFixed(0)} K'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: Colors.white60,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.85,
        height: size.height * 0.65,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.68,
        height: size.height * 0.82,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter para dibujar planetas procedurales
class PlanetPainter extends CustomPainter {
  final Exoplanet planet;

  PlanetPainter({required this.planet});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    final radiusScale = (planet.radiusEarth * 0.3 + 0.7).clamp(0.6, 1.0);
    final radius = baseRadius * radiusScale;

    final tempFactor = (planet.temperatureK / 1500).clamp(0.0, 1.0);
    final coolFactor = 1.0 - tempFactor;

    Color adjustedColor =
        _adjustColorByTemperature(planet.predictiveColor, planet.temperatureK);

    final planetPaint = Paint()
      ..shader = RadialGradient(
        colors: tempFactor > 0.6
            ? [
                adjustedColor.withOpacity(1.0),
                adjustedColor,
                adjustedColor.withOpacity(0.6),
              ]
            : [
                adjustedColor.withOpacity(0.85),
                adjustedColor,
                adjustedColor.withOpacity(0.8),
              ],
        stops: tempFactor > 0.6 ? [0.0, 0.5, 1.0] : [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, planetPaint);

    if (planet.type == "Earth-like" || planet.type == "Rocky") {
      _drawRockyFeatures(canvas, center, radius, planet.temperatureK);
    } else if (planet.type == "Ocean world") {
      _drawOceanFeatures(canvas, center, radius, planet.temperatureK);
    } else if (planet.type.contains("Neptune") ||
        planet.type.contains("Jupiter")) {
      _drawGasGiantFeatures(
          canvas, center, radius, planet.temperatureK, planet.radiusEarth);
    }

    final glowIntensity =
        (planet.radiusEarth * 0.15 + tempFactor * 0.3).clamp(0.2, 0.5);
    final glowSize = radius * (0.5 + planet.radiusEarth * 0.05);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(glowIntensity),
          Colors.white.withOpacity(glowIntensity * 0.3),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowSize));

    canvas.drawCircle(center, glowSize, glowPaint);

    if (planet.temperatureK > 800) {
      final heatGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.orange.withOpacity(0.4 * tempFactor),
            Colors.red.withOpacity(0.2 * tempFactor),
            Colors.transparent,
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2));

      canvas.drawCircle(center, radius * 1.2, heatGlowPaint);
    }

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final shadowIntensity = 0.3 + (coolFactor * 0.3);
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(shadowIntensity),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(shadowPath, shadowPaint);

    if (planet.temperatureK < 280) {
      _drawIceLayer(canvas, center, radius, planet.temperatureK);
    }
  }

  Color _adjustColorByTemperature(Color baseColor, int temperature) {
    if (temperature > 800) {
      return Color.lerp(baseColor, Colors.orange, 0.3)!;
    } else if (temperature > 500) {
      return Color.lerp(baseColor, Colors.yellow.shade700, 0.2)!;
    } else if (temperature < 280) {
      return Color.lerp(baseColor, Colors.blue.shade100, 0.3)!;
    }
    return baseColor;
  }

  void _drawIceLayer(
      Canvas canvas, Offset center, double radius, int temperature) {
    final iceCoverage = ((280 - temperature) / 100).clamp(0.0, 0.7);

    final icePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * iceCoverage)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.6),
      radius * 0.3,
      icePaint,
    );

    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.6),
      radius * 0.3,
      icePaint,
    );
  }

  void _drawRockyFeatures(
      Canvas canvas, Offset center, double radius, int temperature) {
    final craterCount = temperature < 300 ? 5 : 3;
    final craterOpacity = temperature < 300 ? 0.3 : 0.2;

    final craterPaint = Paint()
      ..color = Colors.black.withOpacity(craterOpacity)
      ..style = PaintingStyle.fill;

    final craterSizes = [0.15, 0.1, 0.12, 0.08, 0.11];
    final craterPositions = [
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.2),
      Offset(center.dx + radius * 0.4, center.dy + radius * 0.3),
      Offset(center.dx + radius * 0.1, center.dy - radius * 0.5),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.4),
      Offset(center.dx + radius * 0.2, center.dy + radius * 0.1),
    ];

    for (int i = 0; i < craterCount; i++) {
      canvas.drawCircle(
          craterPositions[i], radius * craterSizes[i], craterPaint);
    }

    if (temperature > 400) {
      final lavaPaint = Paint()
        ..color = Colors.orange.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy + radius * 0.2),
        radius * 0.15,
        lavaPaint,
      );
    }
  }

  void _drawOceanFeatures(
      Canvas canvas, Offset center, double radius, int temperature) {
    final isLiquid = temperature > 273 && temperature < 373;
    final isFrozen = temperature <= 273;

    if (isFrozen) {
      final icePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.3, center.dy),
          width: radius * 0.6,
          height: radius * 0.4,
        ),
        icePaint,
      );
    } else if (isLiquid) {
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < 4; i++) {
        final path = Path();
        final startY = center.dy - radius * 0.6 + (i * radius * 0.35);
        path.moveTo(center.dx - radius * 0.6, startY);

        for (double x = -radius * 0.6; x <= radius * 0.6; x += radius * 0.2) {
          path.quadraticBezierTo(
            center.dx + x + radius * 0.1,
            startY + (i % 2 == 0 ? -8 : 8),
            center.dx + x + radius * 0.2,
            startY,
          );
        }

        canvas.drawPath(path, wavePaint);
      }
    }
  }

  void _drawGasGiantFeatures(Canvas canvas, Offset center, double radius,
      int temperature, double radiusEarth) {
    final bandCount = (3 + radiusEarth * 0.5).toInt().clamp(3, 8);
    final bandPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < bandCount; i++) {
      final bandY = center.dy - radius * 0.7 + (i * radius * 1.4 / bandCount);
      final bandHeight = radius * 0.28;

      final opacity = temperature > 600 ? 0.15 : 0.1;

      bandPaint.color = i % 2 == 0
          ? Colors.white.withOpacity(opacity)
          : Colors.black.withOpacity(opacity * 1.2);

      final bandRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, bandY),
          width: radius * 1.9,
          height: bandHeight,
        ),
        Radius.circular(bandHeight / 2),
      );

      canvas.drawRRect(bandRect, bandPaint);
    }

    if (planet.type.contains("Jupiter") || temperature > 800) {
      final stormSize = radius * (0.3 + radiusEarth * 0.05);
      final stormIntensity = (temperature / 1500).clamp(0.3, 0.7);

      final stormPaint = Paint()
        ..color = temperature > 1000
            ? Colors.orange.withOpacity(stormIntensity)
            : Colors.red.withOpacity(stormIntensity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.3, center.dy + radius * 0.2),
          width: stormSize,
          height: stormSize * 0.7,
        ),
        stormPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
