import 'package:flutter/material.dart';

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
  });

  // Convierte el color hex a Color de Flutter (fallback)
  Color get color {
    final hexColor = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  // Color PREDICTIVO basado en física real
  Color get predictiveColor {
    return _calculatePredictiveColor(temperatureK, type, radiusEarth);
  }

  static Color _calculatePredictiveColor(
      int temperature, String type, double radius) {
    // Planetas muy fríos (< 150K): Hielo de metano, nitrógeno
    if (temperature < 150) {
      return Color.lerp(
          Color(0xFF2C3E50), Color(0xFF34495E), 0.5)!; // Gris azulado oscuro
    }

    // Fríos con hielo de agua (150-273K)
    if (temperature < 273) {
      if (type.contains("Rocky")) {
        return Color.lerp(
            Color(0xFF7F8C8D), Color(0xFFBDC3C7), 0.6)!; // Gris plateado
      }
      return Color.lerp(
          Color(0xFF3498DB), Color(0xFFECF0F1), 0.7)!; // Azul hielo
    }

    // Zona habitable con agua líquida (273-373K)
    if (temperature >= 273 && temperature < 373) {
      if (type == "Ocean world") {
        return Color(0xFF1E90FF); // Azul océano profundo
      }
      if (type == "Earth-like") {
        return Color.lerp(
            Color(0xFF27AE60), Color(0xFF3498DB), 0.5)!; // Verde-azul
      }
      if (type.contains("Rocky")) {
        return Color.lerp(
            Color(0xFF8B4513), Color(0xFFCD853F), 0.5)!; // Marrón rocoso
      }
    }

    // Caliente (373-600K)
    if (temperature >= 373 && temperature < 600) {
      if (type.contains("Neptune")) {
        return Color.lerp(Color(0xFF9B59B6), Color(0xFF3498DB),
            0.6)!; // Púrpura-azul (metano)
      }
      return Color.lerp(
          Color(0xFFE67E22), Color(0xFFF39C12), 0.5)!; // Naranja cálido
    }

    // Muy caliente (600-1000K)
    if (temperature >= 600 && temperature < 1000) {
      if (type.contains("Neptune") || type.contains("Mini")) {
        return Color.lerp(
            Color(0xFF8E44AD), Color(0xFFE74C3C), 0.4)!; // Violeta-rojo
      }
      return Color.lerp(
          Color(0xFFE74C3C), Color(0xFFF39C12), 0.6)!; // Rojo-naranja
    }

    // Extremadamente caliente (1000-1500K) - Hot Jupiters
    if (temperature >= 1000 && temperature < 1500) {
      if (type.contains("Jupiter") && radius > 10) {
        // Hot Jupiters son azul profundo por dispersión de sodio
        return Color(0xFF0047AB); // Azul cobalto intenso
      }
      return Color.lerp(
          Color(0xFFFF4500), Color(0xFFFF6347), 0.5)!; // Rojo brillante
    }

    // Ultra caliente (> 1500K)
    if (temperature >= 1500) {
      return Color.lerp(Color(0xFFFFFFFF), Color(0xFFFFD700),
          0.3)!; // Blanco-amarillo brillante
    }

    // Fallback por tipo
    if (type.contains("Gas") || type.contains("Jupiter")) {
      return Color(0xFF4169E1); // Azul real
    }

    return Color(0xFF95A5A6); // Gris por defecto
  }
}

class VisualizacionesScreen extends StatefulWidget {
  const VisualizacionesScreen({Key? key}) : super(key: key);

  @override
  State<VisualizacionesScreen> createState() => _VisualizacionesScreenState();
}

class _VisualizacionesScreenState extends State<VisualizacionesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Lista de exoplanetas con tus datos
  final List<Exoplanet> exoplanets = [
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi Explorer,',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Which exoplanet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'would you like to explore?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        height: 1.2,
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
                        icon: Icon(Icons.chevron_left,
                            color: Colors.white, size: 32),
                        onPressed: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      right: 20,
                      child: IconButton(
                        icon: Icon(Icons.chevron_right,
                            color: Colors.white, size: 32),
                        onPressed: () {
                          if (_currentPage < exoplanets.length - 1) {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
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
                      margin: EdgeInsets.symmetric(horizontal: 4),
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

              SizedBox(height: 10),
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
          SizedBox(height: 20),

          // Orbital animation container
          Container(
            width: 350,
            height: 350,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbits
                CustomPaint(
                  size: Size(350, 350),
                  painter: OrbitPainter(),
                ),

                // Planet Image con gradiente radial
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        planet.color.withOpacity(0.8),
                        planet.color.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: [0.5, 0.8, 1.0],
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: planet.color.withOpacity(0.6),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: PlanetPainter(planet: planet),
                        ),
                      ),
                    ),
                  ),
                ),

                // Orbital dots
                Positioned(
                  top: 45,
                  right: 100,
                  child: _buildOrbitDot(),
                ),
                Positioned(
                  bottom: 70,
                  left: 90,
                  child: _buildOrbitDot(),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Planet Info Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(24),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),

                // Planet Type
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: planet.color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    planet.type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Description
                Text(
                  planet.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 20),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Radius',
                        '${planet.radiusEarth}x Earth',
                        Icons.radio_button_unchecked,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Temp',
                        '${planet.temperatureK}K',
                        Icons.thermostat,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Distance',
                        '${planet.distanceLy} ly',
                        Icons.straighten,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Star Type',
                        planet.starType,
                        Icons.wb_sunny,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
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
                size: 14,
                color: Colors.white60,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitDot() {
    return Container(
      width: 14,
      height: 14,
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

    // Draw multiple elliptical orbits
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

    // El radio del planeta afecta su tamaño visual (más grande = más radio)
    final radiusScale = (planet.radiusEarth * 0.3 + 0.7).clamp(0.6, 1.0);
    final radius = baseRadius * radiusScale;

    // Temperatura afecta los colores (más caliente = más brillante/rojizo)
    final tempFactor = (planet.temperatureK / 1500).clamp(0.0, 1.0);
    final coolFactor = 1.0 - tempFactor;

    // Ajustar color base según temperatura
    Color adjustedColor =
        _adjustColorByTemperature(planet.color, planet.temperatureK);

    // Base del planeta con gradiente afectado por temperatura
    final planetPaint = Paint()
      ..shader = RadialGradient(
        colors: tempFactor > 0.6
            ? [
                // Planetas calientes: centro brillante
                adjustedColor.withOpacity(1.0),
                adjustedColor,
                adjustedColor.withOpacity(0.6),
              ]
            : [
                // Planetas fríos: más uniformes
                adjustedColor.withOpacity(0.85),
                adjustedColor,
                adjustedColor.withOpacity(0.8),
              ],
        stops: tempFactor > 0.6 ? [0.0, 0.5, 1.0] : [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, planetPaint);

    // Características según el tipo de planeta
    if (planet.type == "Earth-like" || planet.type == "Rocky") {
      _drawRockyFeatures(canvas, center, radius, planet.temperatureK);
    } else if (planet.type == "Ocean world") {
      _drawOceanFeatures(canvas, center, radius, planet.temperatureK);
    } else if (planet.type.contains("Neptune") ||
        planet.type.contains("Jupiter")) {
      _drawGasGiantFeatures(
          canvas, center, radius, planet.temperatureK, planet.radiusEarth);
    }

    // Brillo atmosférico más intenso en planetas grandes y calientes
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

    // Emisión de calor en planetas muy calientes
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

    // Sombra (terminador) - más pronunciada en planetas fríos
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

    // Capa de hielo en planetas muy fríos
    if (planet.temperatureK < 280) {
      _drawIceLayer(canvas, center, radius, planet.temperatureK);
    }
  }

  Color _adjustColorByTemperature(Color baseColor, int temperature) {
    if (temperature > 800) {
      // Planetas muy calientes: añadir tonos rojos/naranjas
      return Color.lerp(baseColor, Colors.orange, 0.3)!;
    } else if (temperature > 500) {
      // Calientes: añadir amarillo
      return Color.lerp(baseColor, Colors.yellow.shade700, 0.2)!;
    } else if (temperature < 280) {
      // Muy fríos: añadir azul/blanco
      return Color.lerp(baseColor, Colors.blue.shade100, 0.3)!;
    }
    return baseColor;
  }

  void _drawIceLayer(
      Canvas canvas, Offset center, double radius, int temperature) {
    final iceCoverage = ((280 - temperature) / 100).clamp(0.0, 0.7);

    final icePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * iceCoverage)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    // Capas polares
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

    // Cristales de hielo
    final crystalPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < (iceCoverage * 15).toInt(); i++) {
      final angle = i * 0.4;
      final dist = radius * 0.7;
      canvas.drawCircle(
        Offset(
          center.dx + dist * 0.5 * (i % 3 - 1),
          center.dy - radius * 0.5 + (i * radius * 0.1),
        ),
        2,
        crystalPaint,
      );
    }
  }

  void _drawRockyFeatures(
      Canvas canvas, Offset center, double radius, int temperature) {
    // Más cráteres en planetas fríos (menos actividad geológica)
    final craterCount = temperature < 300 ? 5 : 3;

    // Cráteres más visibles en planetas fríos
    final craterOpacity = temperature < 300 ? 0.3 : 0.2;

    final craterPaint = Paint()
      ..color = Colors.black.withOpacity(craterOpacity)
      ..style = PaintingStyle.fill;

    // Dibujar cráteres de diferentes tamaños
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

    // Actividad volcánica en planetas calientes
    if (temperature > 400) {
      final lavaPaint = Paint()
        ..color = Colors.orange.withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy + radius * 0.2),
        radius * 0.15,
        lavaPaint,
      );
    }
  }

  void _drawOceanFeatures(
      Canvas canvas, Offset center, double radius, int temperature) {
    // Temperatura afecta el estado del agua
    final isLiquid = temperature > 273 && temperature < 373;
    final isFrozen = temperature <= 273;

    if (isFrozen) {
      // Océano congelado
      final icePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;

      // Placas de hielo
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.3, center.dy),
          width: radius * 0.6,
          height: radius * 0.4,
        ),
        icePaint,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.4, center.dy + radius * 0.3),
          width: radius * 0.5,
          height: radius * 0.35,
        ),
        icePaint,
      );
    } else if (isLiquid) {
      // Agua líquida con olas
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

      // Brillo de agua más intenso en temperaturas templadas
      final waterGlowPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
        Offset(center.dx + radius * 0.2, center.dy - radius * 0.3),
        radius * 0.3,
        waterGlowPaint,
      );
    } else {
      // Vapor de agua (muy caliente)
      final vaporPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(center, radius * 0.8, vaporPaint);
    }
  }

  void _drawGasGiantFeatures(Canvas canvas, Offset center, double radius,
      int temperature, double radiusEarth) {
    // Más bandas en planetas más grandes
    final bandCount = (3 + radiusEarth * 0.5).toInt().clamp(3, 8);

    final bandPaint = Paint()..style = PaintingStyle.fill;

    // Dibujar bandas atmosféricas
    for (int i = 0; i < bandCount; i++) {
      final bandY = center.dy - radius * 0.7 + (i * radius * 1.4 / bandCount);
      final bandHeight = radius * 0.28;

      // Bandas más activas en planetas calientes
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

    // Tormentas más grandes e intensas en planetas grandes y calientes
    if (planet.type.contains("Jupiter") || temperature > 800) {
      final stormSize = radius * (0.3 + radiusEarth * 0.05);
      final stormIntensity = (temperature / 1500).clamp(0.3, 0.7);

      final stormPaint = Paint()
        ..color = temperature > 1000
            ? Colors.orange.withOpacity(stormIntensity)
            : Colors.red.withOpacity(stormIntensity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.3, center.dy + radius * 0.2),
          width: stormSize,
          height: stormSize * 0.7,
        ),
        stormPaint,
      );

      // Tormenta secundaria en planetas muy grandes
      if (radiusEarth > 10) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - radius * 0.4, center.dy - radius * 0.3),
            width: stormSize * 0.6,
            height: stormSize * 0.4,
          ),
          stormPaint,
        );
      }
    }

    // Remolinos más numerosos en planetas grandes
    final swirlCount = (radiusEarth * 0.3).toInt().clamp(1, 3);

    final swirlPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < swirlCount; i++) {
      canvas.drawCircle(
        Offset(
          center.dx - radius * 0.4 + (i * radius * 0.4),
          center.dy - radius * 0.3 + (i * radius * 0.2),
        ),
        radius * 0.12,
        swirlPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
