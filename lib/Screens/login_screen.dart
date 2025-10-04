import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Servicios/firebase_auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Verificar si ya hay un usuario autenticado
    _checkCurrentUser();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  void _checkCurrentUser() {
    if (_authService.currentUser != null) {
      // Si hay usuario, navegar a home
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
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        // Navegación exitosa
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const HomeScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else if (mounted) {
        // El usuario canceló
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicio de sesión cancelado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    final isTablet = size.width > 600;
    final maxWidth = isTablet ? 400.0 : size.width * 0.9;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo minimalista
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(
                              isTablet ? 24 : 20,
                            ),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: isTablet ? 50 : 40,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 40 : 32),

                      // Título
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'ExoAi',
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey[900],
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              Text(
                                'Inicia sesión para continuar',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Botones de login
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: maxWidth,
                            child: Column(
                              children: [
                                // Apple - DESACTIVADO
                                _buildMinimalButton(
                                  icon: Icons.apple,
                                  label: 'Continuar con Apple',
                                  backgroundColor: Colors.grey[200]!,
                                  textColor: Colors.grey[400]!,
                                  isDisabled: true,
                                  onTap: () {},
                                ),

                                SizedBox(height: isTablet ? 16 : 12),

                                // Google - ACTIVO con Firebase
                                _buildMinimalButton(
                                  icon: Icons.g_mobiledata,
                                  label: _isLoading
                                      ? 'Conectando...'
                                      : 'Continuar con Google',
                                  backgroundColor: Colors.white,
                                  textColor: Colors.grey[800]!,
                                  hasBorder: true,
                                  isLoading: _isLoading,
                                  onTap: _isLoading ? () {} : _loginWithGoogle,
                                ),

                                SizedBox(height: isTablet ? 16 : 12),

                                // Facebook - DESACTIVADO
                                _buildMinimalButton(
                                  icon: Icons.facebook,
                                  label: 'Continuar con Facebook',
                                  backgroundColor: Colors.grey[200]!,
                                  textColor: Colors.grey[400]!,
                                  isDisabled: true,
                                  onTap: () {},
                                ),

                                SizedBox(height: isTablet ? 24 : 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'o',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: isTablet ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: isTablet ? 24 : 20),

                                // Invitado - DESACTIVADO
                                _buildMinimalButton(
                                  icon: Icons.person_outline,
                                  label: 'Continuar como invitado',
                                  backgroundColor: Colors.grey[200]!,
                                  textColor: Colors.grey[400]!,
                                  isDisabled: true,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Términos
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            'Al continuar, aceptas los Términos de Uso\ny Política de Privacidad',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    bool hasBorder = false,
    bool isDisabled = false,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      child: InkWell(
        onTap: isDisabled || isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Container(
          height: isTablet ? 60 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: hasBorder
                ? Border.all(color: Colors.grey[300]!, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: isTablet ? 24 : 22,
                  height: isTablet ? 24 : 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                Icon(icon, color: textColor, size: isTablet ? 24 : 22),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (isDisabled) ...[
                SizedBox(width: isTablet ? 12 : 8),
                Icon(
                  Icons.lock_outline,
                  color: textColor,
                  size: isTablet ? 20 : 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
