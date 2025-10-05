import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/firebase_auth_service.dart';
import 'home_screen.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _starsController;
  late AnimationController _planetController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _checkCurrentUser();

    // Animación principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animación de estrellas
    _starsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Animación de planeta flotante
    _planetController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  void _checkCurrentUser() {
    if (_authService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starsController.dispose();
    _planetController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const HomeScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Inicio de sesión cancelado'),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Estrellas animadas
            AnimatedBuilder(
              animation: _starsController,
              builder: (context, child) {
                return CustomPaint(
                  painter: StarsPainter(_starsController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Planeta flotante
            Positioned(
              top: size.height * 0.1,
              right: -size.width * 0.3,
              child: AnimatedBuilder(
                animation: _planetController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      math.sin(_planetController.value * 2 * math.pi) * 20,
                    ),
                    child: Opacity(
                      opacity: 0.15,
                      child: Container(
                        width: size.width * 0.8,
                        height: size.width * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF60A5FA).withOpacity(0.3),
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo animado
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF60A5FA)
                                            .withOpacity(0.5),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/Logo-02.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Título animado
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF60A5FA),
                                          Color(0xFF3B82F6),
                                          Color(0xFF2563EB),
                                        ],
                                      ).createShader(bounds),
                                      child: const Text(
                                        'ExoAI',
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Descubre el Universo',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF60A5FA)
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '🚀 Exploración • 🌍 Exoplanetas • 🤖 IA',
                                        style: TextStyle(
                                          color: Color(0xFF60A5FA),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            // Botones animados
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    // Botón de Google principal
                                    Container(
                                      width: double.infinity,
                                      constraints:
                                          const BoxConstraints(maxWidth: 400),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _loginWithGoogle,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF1a1a2e),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                          shadowColor:
                                              Colors.black.withOpacity(0.3),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF1a1a2e),
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/google_logo.png',
                                                    height: 24,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return const Icon(
                                                        Icons.login,
                                                        size: 24,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Continuar con Google',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withOpacity(0.3),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            'o explora con',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Botones secundarios
                                    Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 400),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildSecondaryButton(
                                              'NASA',
                                              Icons.rocket_launch,
                                              const Color(0xFF3B82F6),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildSecondaryButton(
                                              'Institucional',
                                              Icons.school,
                                              const Color(0xFF8B5CF6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Al continuar, aceptas nuestros Términos y Condiciones',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                size: 14,
                                color: const Color(0xFF60A5FA).withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Conexión segura',
                                style: TextStyle(
                                  color:
                                      const Color(0xFF60A5FA).withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, Color color) {
    return OutlinedButton(
      onPressed: () {
        // Funcionalidad futura
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para las estrellas animadas
class StarsPainter extends CustomPainter {
  final double animation;

  StarsPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = math.sin((animation + i / 100) * 2 * math.pi);
      final opacity = (0.3 + offset * 0.4).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(opacity);

      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}
