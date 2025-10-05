import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/gemini_service.dart';
import '../widgets/profile_avatar_menu.dart'; // Agregar al inicio del archivo

class HomeContent extends StatefulWidget {
  final String userName;

  const HomeContent({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _currentNewsIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, String>> _noticias = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _lanzamientos = [];
  bool _isLoadingLaunches = true;

  Timer? _countdownTimer;
  Timer? _autoScrollTimer;

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _fetchNASANews();
    _fetchUpcomingLaunches();
    _startCountdownTimer();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_noticias.isNotEmpty && _pageController.hasClients) {
        final nextPage = (_currentNewsIndex + 1) % _noticias.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showGeminiAnalysis(Map<String, dynamic> launch) async {
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
              'Analizando con Gemini AI...',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );

    try {
      final analysis = await _geminiService.analyzeSpaceLaunch(launch);

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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis Gemini AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Análisis detallado de la misión',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      analysis,
                      style: TextStyle(
                        color: Colors.grey[300],
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

  Future<void> _fetchNASANews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('https://www.nasa.gov/news-release/feed/'),
      );

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        final List<Map<String, String>> newsData = [];

        for (var item in items.take(5)) {
          final title = item.findElements('title').first.innerText;
          final description = item.findElements('description').first.innerText;
          final link = item.findElements('link').first.innerText;

          String imageUrl = '';
          try {
            final content =
                item.findElements('content:encoded').first.innerText;
            final imgMatch =
                RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(content);
            if (imgMatch != null) {
              imageUrl = imgMatch.group(1) ?? '';
            }
          } catch (e) {
            imageUrl =
                'https://images.unsplash.com/photo-1614732414444-096e5f1122d5?w=800&h=400&fit=crop';
          }

          String cleanDescription = description
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&#8230;', '...')
              .trim();

          if (cleanDescription.length > 150) {
            cleanDescription = cleanDescription.substring(0, 150) + '...';
          }

          newsData.add({
            'titulo': title,
            'texto': cleanDescription,
            'imagen': imageUrl,
            'link': link,
          });
        }

        setState(() {
          _noticias = newsData;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar noticias: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar noticias de NASA: $e';
        _noticias = [
          {
            'titulo': 'Error al cargar noticias',
            'texto':
                'No se pudieron cargar las noticias de NASA. Verifica tu conexión.',
            'imagen':
                'https://images.unsplash.com/photo-1614732414444-096e5f1122d5?w=800&h=400&fit=crop',
            'link': '',
          },
        ];
      });
    }
  }

  Future<void> _fetchUpcomingLaunches() async {
    try {
      setState(() {
        _isLoadingLaunches = true;
      });

      final response = await http.get(
        Uri.parse(
            'https://ll.thespacedevs.com/2.0.0/launch/upcoming/?limit=20'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        final List<Map<String, dynamic>> launchesData = [];

        final exoplanetLaunches = results.where((launch) {
          final missionName =
              (launch['mission']?['name'] ?? '').toString().toLowerCase();
          final missionDescription = (launch['mission']?['description'] ?? '')
              .toString()
              .toLowerCase();
          final launchName = (launch['name'] ?? '').toString().toLowerCase();

          return missionName.contains('exoplanet') ||
              missionName.contains('tess') ||
              missionName.contains('jwst') ||
              missionName.contains('james webb') ||
              missionDescription.contains('exoplanet') ||
              launchName.contains('exoplanet');
        }).toList();

        final otherLaunches = results.where((launch) {
          final missionName =
              (launch['mission']?['name'] ?? '').toString().toLowerCase();
          final missionDescription = (launch['mission']?['description'] ?? '')
              .toString()
              .toLowerCase();
          final launchName = (launch['name'] ?? '').toString().toLowerCase();

          return !(missionName.contains('exoplanet') ||
              missionName.contains('tess') ||
              missionName.contains('jwst') ||
              missionName.contains('james webb') ||
              missionDescription.contains('exoplanet') ||
              launchName.contains('exoplanet'));
        }).toList();

        final prioritizedLaunches = [...exoplanetLaunches, ...otherLaunches];

        for (var launch in prioritizedLaunches.take(2)) {
          final nombre = launch['name'] ?? 'Lanzamiento desconocido';
          final status = launch['status']?['name'] ?? 'Desconocido';
          final statusId = launch['status']?['id'] ?? 0;
          final net = launch['net'] ?? '';
          final missionType = launch['mission']?['type'] ?? 'N/A';
          final provider = launch['launch_service_provider']?['name'] ?? 'N/A';
          final missionName = launch['mission']?['name'] ?? '';
          final missionDescription = launch['mission']?['description'] ?? '';
          final probability = launch['probability'] ?? -1;

          final isExoplanet = missionName.toLowerCase().contains('exoplanet') ||
              missionDescription.toLowerCase().contains('exoplanet') ||
              nombre.toLowerCase().contains('exoplanet') ||
              missionName.toLowerCase().contains('tess') ||
              missionName.toLowerCase().contains('jwst');

          bool completada = statusId == 3;
          bool enProceso = statusId == 1 || statusId == 2;
          bool fallida = statusId == 4 || statusId == 7;
          bool enLanzamiento = statusId == 6;

          launchesData.add({
            'nombre': nombre,
            'status': status,
            'statusId': statusId,
            'completada': completada,
            'enProceso': enProceso,
            'fallida': fallida,
            'enLanzamiento': enLanzamiento,
            'fecha': net,
            'tipoMision': missionType,
            'proveedor': provider,
            'missionName': missionName,
            'missionDescription': missionDescription,
            'probability': probability,
            'isExoplanet': isExoplanet,
          });
        }

        setState(() {
          _lanzamientos = launchesData;
          _isLoadingLaunches = false;
        });
      } else {
        throw Exception('Error al cargar lanzamientos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingLaunches = false;
        _lanzamientos = [];
      });
    }
  }

  String _getCountdown(String dateString) {
    try {
      final launchDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = launchDate.difference(now);

      if (difference.isNegative) {
        return 'Lanzado';
      }

      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      if (days > 0) {
        return '${days}d ${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h ${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      } else {
        return '${seconds}s';
      }
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  double _getProgress(String dateString) {
    try {
      final launchDate = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = launchDate.difference(now);

      final maxDays = 30;
      final daysRemaining = difference.inDays;

      if (daysRemaining <= 0) return 1.0;
      if (daysRemaining >= maxDays) return 0.0;

      return 1 - (daysRemaining / maxDays);
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _openNewsLink(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countdownTimer?.cancel();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _handlePrev() {
    _autoScrollTimer?.cancel();
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
    _startAutoScroll();
  }

  void _handleNext() {
    _autoScrollTimer?.cancel();
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
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return SafeArea(
      child: Container(
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
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Cargando noticias de NASA...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _fetchNASANews();
                  await _fetchUpcomingLaunches();
                },
                color: Colors.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NASA News',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Toca para recargar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (size.width <= 768)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF60A5FA),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF60A5FA)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF1E293B),
                                child: FirebaseAuth
                                            .instance.currentUser?.photoURL !=
                                        null
                                    ? ClipOval(
                                        child: Image.network(
                                          FirebaseAuth
                                              .instance.currentUser!.photoURL!,
                                          fit: BoxFit.cover,
                                          width: 48,
                                          height: 48,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 28,
                                              color: Color(0xFF60A5FA),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Color(0xFF60A5FA),
                                      ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_noticias.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            if (_currentNewsIndex < _noticias.length) {
                              _openNewsLink(
                                  _noticias[_currentNewsIndex]['link'] ?? '');
                            }
                          },
                          child: Container(
                            height: isTablet ? 400 : 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E293B),
                                  Color(0xFF0F172A),
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
                                          Image.network(
                                            noticia['imagen']!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xFF1E293B),
                                                child: const Icon(
                                                  Icons.rocket_launch,
                                                  size: 64,
                                                  color: Color(0xFF475569),
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                color: const Color(0xFF1E293B),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.blue,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  const Color(0xFF0F172A)
                                                      .withOpacity(0.6),
                                                  const Color(0xFF0F172A),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    noticia['titulo']!,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    noticia['texto']!,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[300],
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.touch_app,
                                                        size: 16,
                                                        color: Colors.blue[300],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Toca para leer más',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.blue[300],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (_noticias.length > 1) ...[
                                    Positioned(
                                      left: 16,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
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
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: _handleNext,
                                            icon: const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                            _noticias.length, (index) {
                                          return GestureDetector(
                                            onTap: () {
                                              _autoScrollTimer?.cancel();
                                              _pageController.animateToPage(
                                                index,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                              _startAutoScroll();
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              width: _currentNewsIndex == index
                                                  ? 32
                                                  : 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    _currentNewsIndex == index
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.rocket_launch,
                                        color: Color(0xFF60A5FA)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Próximos Lanzamientos',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isLoadingLaunches)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_isLoadingLaunches)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'Cargando lanzamientos...',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else if (_lanzamientos.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'No hay lanzamientos próximos',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_lanzamientos.length, (index) {
                                final lanzamiento = _lanzamientos[index];
                                final enLanzamiento =
                                    lanzamiento['enLanzamiento'] == true;
                                final enProceso =
                                    lanzamiento['enProceso'] == true;
                                final isExoplanet =
                                    lanzamiento['isExoplanet'] == true;
                                final countdown =
                                    _getCountdown(lanzamiento['fecha']);
                                final progress =
                                    _getProgress(lanzamiento['fecha']);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: enLanzamiento
                                        ? const Color(0xFF60A5FA)
                                            .withOpacity(0.1)
                                        : isExoplanet
                                            ? const Color(0xFF8B5CF6)
                                                .withOpacity(0.1)
                                            : const Color(0xFF334155)
                                                .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: enLanzamiento
                                          ? const Color(0xFF60A5FA)
                                          : isExoplanet
                                              ? const Color(0xFF8B5CF6)
                                              : const Color(0xFF475569),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (isExoplanet)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF8B5CF6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'MISIÓN EXOPLANETA',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                Text(
                                                  lanzamiento['nombre'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: enLanzamiento
                                                  ? const Color(0xFF60A5FA)
                                                  : enProceso
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF64748B),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              lanzamiento['status'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      if (enProceso || enLanzamiento)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: enLanzamiento
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFF10B981),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    enLanzamiento
                                                        ? Icons.flash_on
                                                        : Icons.access_time,
                                                    color: enLanzamiento
                                                        ? const Color(
                                                            0xFF60A5FA)
                                                        : const Color(
                                                            0xFF10B981),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    enLanzamiento
                                                        ? '¡EN VUELO!'
                                                        : 'CUENTA REGRESIVA',
                                                    style: TextStyle(
                                                      color: enLanzamiento
                                                          ? const Color(
                                                              0xFF60A5FA)
                                                          : const Color(
                                                              0xFF10B981),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                countdown,
                                                style: TextStyle(
                                                  color: enLanzamiento
                                                      ? const Color(0xFF60A5FA)
                                                      : Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (enProceso && !enLanzamiento)
                                        Column(
                                          children: [
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Progreso al lanzamiento',
                                                  style: TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${(progress * 100).toInt()}%',
                                                  style: const TextStyle(
                                                    color: Color(0xFF10B981),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor:
                                                    const Color(0xFF334155),
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFF10B981),
                                                ),
                                                minHeight: 8,
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 16),

                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildInfoRow(
                                              Icons.business,
                                              'Proveedor',
                                              lanzamiento['proveedor'],
                                            ),
                                            if (lanzamiento['missionName'] !=
                                                '')
                                              _buildInfoRow(
                                                Icons.flag,
                                                'Misión',
                                                lanzamiento['missionName'],
                                              ),
                                            if (lanzamiento['probability'] !=
                                                -1)
                                              _buildInfoRow(
                                                Icons.percent,
                                                'Probabilidad',
                                                '${lanzamiento['probability']}%',
                                              ),
                                          ],
                                        ),
                                      ),

                                      if (lanzamiento['missionDescription'] !=
                                              '' &&
                                          lanzamiento['missionDescription'] !=
                                              'N/A')
                                        Column(
                                          children: [
                                            const SizedBox(height: 12),
                                            Text(
                                              lanzamiento['missionDescription'],
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 12,
                                                height: 1.5,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 16),

                                      // BOTÓN DE GEMINI
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _showGeminiAnalysis(lanzamiento),
                                          icon: const Icon(Icons.auto_awesome,
                                              size: 20),
                                          label: const Text(
                                            'Analizar con Gemini AI',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF60A5FA),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 4,
                                            shadowColor: const Color(0xFF60A5FA)
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
