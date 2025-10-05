import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/BackendExoplanetService.dart';
import '../Servicios/gemini_service.dart';

// [Incluir aquí toda la clase Exoplanet y código anterior hasta VisualizacionesScreenState]

class _VisualizacionesScreenState extends State<VisualizacionesScreen> {
  final PageController _pageController = PageController();
  final BackendExoplanetService _service = BackendExoplanetService();
  final GeminiService _geminiService = GeminiService();

  int _currentPage = 0;
  List<Exoplanet> exoplanets = [];
  bool _isLoading = true;

  // [Código de _fallbackExoplanets, initState, _loadExoplanets, etc.]

  Future<void> _createCustomPlanet(
    String name,
    double radius,
    int temperature,
    int distance,
  ) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF60A5FA)),
      ),
    );

    try {
      // Generar descripción con Gemini
      final prompt = '''
Eres un experto en exoplanetas. Genera una descripción fascinante y científicamente plausible para este exoplaneta personalizado:

Nombre: $name
Radio: ${radius.toStringAsFixed(2)} radios terrestres
Temperatura: $temperature K
Distancia: $distance años luz

En máximo 60 palabras, describe:
1. El tipo de planeta que es (rocoso, gaseoso, oceánico, etc.)
2. Sus características atmosféricas
3. Posible habitabilidad
4. Algo único o interesante
''';

      final description = await _geminiService.analyzeSpaceLaunch({
        'nombre': name,
        'proveedor': 'Custom Creation',
        'missionName': 'Exoplanet Design',
        'missionDescription': prompt,
        'status': 'Created',
      });

      // Clasificar el planeta
      final type = _classifyByParams(radius, temperature);
      final starType = _classifyStarType(temperature * 3.0);

      // Crear el exoplaneta
      final newPlanet = Exoplanet(
        name: name,
        radiusEarth: radius,
        temperatureK: temperature,
        distanceLy: distance,
        type: type,
        starType: starType,
        description: description,
        colorHex: "#60A5FA",
        imageHint: "",
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      setState(() {
        exoplanets.insert(0, newPlanet);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('¡$name creado exitosamente!')),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _classifyByParams(double radius, int temperature) {
    if (radius < 1.25) {
      if (temperature >= 273 && temperature <= 373) return "Earth-like";
      if (temperature < 273) return "Frozen World";
      return "Rocky";
    } else if (radius < 2.0) {
      return "Super-Earth";
    } else if (radius < 4.0) {
      if (temperature > 500) return "Mini-Neptune";
      return "Ice Giant";
    } else {
      if (temperature > 1000) return "Hot Jupiter";
      return "Gas Giant";
    }
  }

  Widget _buildCreateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIcon: Icon(icon, color: const Color(0xFF60A5FA)),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _analyzeWithGemini(Exoplanet planet) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF60A5FA)),
      ),
    );

    try {
      final prompt = '''
Eres un astrofísico experto. Analiza este exoplaneta en detalle:

Nombre: ${planet.name}
Radio: ${planet.radiusEarth} radios terrestres
Temperatura: ${planet.temperatureK} K
Tipo: ${planet.type}
Distancia: ${planet.distanceLy} años luz

Proporciona un análisis fascinante (máximo 120 palabras) que incluya:
1. Comparación con planetas conocidos del sistema solar
2. Posibilidades de vida o habitabilidad
3. Características únicas de su atmósfera o superficie
4. Qué hace especial a este planeta
5. Curiosidades científicas
''';

      final analysis = await _geminiService.analyzeSpaceLaunch({
        'nombre': planet.name,
        'proveedor': 'Gemini Analysis',
        'missionName': 'Deep Exoplanet Analysis',
        'missionDescription': prompt,
        'status': 'Analyzed',
      });

      if (!mounted) return;
      Navigator.pop(context);

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
              border: Border.all(color: const Color(0xFF60A5FA), width: 2),
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
                              planet.name,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      analysis,
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
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlanetDialog,
        icon: const Icon(Icons.add),
        label: const Text('Crear Planeta'),
        backgroundColor: const Color(0xFF60A5FA),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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

  // [Incluir aquí _buildPlanetCard con botón de Gemini]
  Widget _buildPlanetCard(Exoplanet planet) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ... código del planeta visual ...

          const SizedBox(height: 20),

          // Planet Info Card con botón Gemini
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
                // ... info del planeta ...

                const SizedBox(height: 16),

                // Botón de Gemini
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _analyzeWithGemini(planet),
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text(
                      'Analizar con Gemini AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
