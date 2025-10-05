import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  final String userName;

  const HomeContent({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _currentNewsIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _noticias = [
    {
      'titulo': 'Nueva Tecnología de IA Revoluciona el Mercado',
      'texto':
          'Investigadores presentan un avance significativo en inteligencia artificial que promete transformar múltiples industrias.',
      'imagen':
          'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&h=400&fit=crop'
    },
    {
      'titulo': 'Récord en Energías Renovables',
      'texto':
          'Las energías limpias alcanzan el 40% de la generación eléctrica mundial, marcando un hito histórico en sostenibilidad.',
      'imagen':
          'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=800&h=400&fit=crop'
    },
    {
      'titulo': 'Descubrimiento Espacial Sorprende a Científicos',
      'texto':
          'Telescopio James Webb captura imágenes inéditas de galaxias formadas poco después del Big Bang.',
      'imagen':
          'https://images.unsplash.com/photo-1614732414444-096e5f1122d5?w=800&h=400&fit=crop'
    },
    {
      'titulo': 'Avance Médico Contra Enfermedades Raras',
      'texto':
          'Nueva terapia génica muestra resultados prometedores en ensayos clínicos para el tratamiento de enfermedades genéticas.',
      'imagen':
          'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=800&h=400&fit=crop'
    },
    {
      'titulo': 'Innovación en Movilidad Urbana Sostenible',
      'texto':
          'Ciudades implementan sistemas de transporte inteligente que reducen emisiones en un 35% y mejoran la calidad del aire.',
      'imagen':
          'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=400&fit=crop'
    },
  ];

  final List<Map<String, dynamic>> _misiones = [
    {'nombre': 'Configuración inicial', 'completada': true},
    {'nombre': 'Análisis de datos', 'completada': true},
    {'nombre': 'Implementación de modelo', 'enProceso': true},
    {'nombre': 'Validación de resultados', 'completada': false},
    {'nombre': 'Despliegue final', 'completada': false},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePrev() {
    if (_currentNewsIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        _noticias.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNext() {
    if (_currentNewsIndex < _noticias.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A), // slate-900
              const Color(0xFF172554), // blue-950
              const Color(0xFF0F172A), // slate-900
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón de datasets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Noticias',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.storage, size: 20),
                    label: const Text('Datasets',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Carrusel de noticias
              Container(
                height: isTablet ? 400 : 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // PageView para las noticias
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentNewsIndex = index;
                          });
                        },
                        itemCount: _noticias.length,
                        itemBuilder: (context, index) {
                          final noticia = _noticias[index];
                          return Stack(
                            children: [
                              // Imagen de fondo
                              Image.network(
                                noticia['imagen']!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF1E293B),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Color(0xFF475569),
                                    ),
                                  );
                                },
                              ),
                              // Gradiente sobre la imagen
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF0F172A).withOpacity(0.6),
                                      const Color(0xFF0F172A),
                                    ],
                                  ),
                                ),
                              ),
                              // Texto
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        noticia['titulo']!,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        noticia['texto']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Botones de navegación
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _handlePrev,
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _handleNext,
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),

                      // Indicadores
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_noticias.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentNewsIndex == index ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentNewsIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lista de noticias
              ...List.generate(_noticias.length, (index) {
                final noticia = _noticias[index];
                final isSelected = _currentNewsIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[600]
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            noticia['imagen']!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 96,
                                height: 96,
                                color: const Color(0xFF334155),
                                child: const Icon(Icons.image_not_supported,
                                    color: Color(0xFF64748B)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                noticia['titulo']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                noticia['texto']!,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Panel de misiones
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Color(0xFF60A5FA)),
                        SizedBox(width: 8),
                        Text(
                          'Panel de Misiones',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(_misiones.length, (index) {
                      final mision = _misiones[index];
                      final completada = mision['completada'] == true;
                      final enProceso = mision['enProceso'] == true;
                      final isLast = index == _misiones.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline vertical
                          Column(
                            children: [
                              if (completada)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF4ADE80), size: 24)
                              else if (enProceso)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.circle_outlined,
                                        color: Color(0xFF60A5FA), size: 24),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF60A5FA),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Icon(Icons.circle_outlined,
                                    color: Color(0xFF475569), size: 24),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 48,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  color: completada
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF334155),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Contenido
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mision['nombre'],
                                    style: TextStyle(
                                      color: completada
                                          ? const Color(0xFF4ADE80)
                                          : enProceso
                                              ? const Color(0xFF60A5FA)
                                              : const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    completada
                                        ? 'Completada'
                                        : enProceso
                                            ? 'En proceso...'
                                            : 'Pendiente',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
