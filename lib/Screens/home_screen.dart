import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_content.dart';
import 'datos_screen.dart';
import 'ia_screen.dart';
import 'visualizaciones_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart'; // AGREGADO
import 'login_screen.dart';
import '../Servicios/firebase_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuthService _authService = FirebaseAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lista de pantallas que se mostrarán
  late final List<Widget> _screens;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF60A5FA)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Obtenemos el nombre del usuario de Firebase
    final user = _authService.currentUser;
    final userName = user?.displayName?.split(' ')[0] ?? 'Usuario';

    // Inicializamos la lista de pantallas con el nombre real del usuario
    _screens = [
      HomeContent(userName: userName),
      const ExoplanetScreen(),
      const IAScreen(),
      const VisualizacionesScreen(),
      const CommunityScreen(), // AGREGADO - Índice 4
      ProfileScreen(userName: userName), // Ahora es índice 5
    ];
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Cerrar el drawer después de seleccionar
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    final userEmail = user?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;

    // Determinar si es un dispositivo grande (tablet/web)
    final isLargeScreen = screenWidth > 768;

    if (isLargeScreen) {
      // Interfaz con Drawer lateral para pantallas grandes
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF60A5FA)),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAppBarIcon(),
                  color: const Color(0xFF60A5FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1E293B),
          child: Column(
            children: [
              // Header del drawer con información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF60A5FA),
                      Colors.blue[800]!,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: user?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoURL!,
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF60A5FA),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Items del menú
              Expanded(
                child: Container(
                  color: const Color(0xFF1E293B),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        title: 'Inicio',
                        index: 0,
                      ),
                      _buildDrawerItem(
                        icon: Icons.dataset_rounded,
                        title: 'Datos',
                        index: 1,
                      ),
                      _buildDrawerItem(
                        icon: Icons.psychology_rounded,
                        title: 'IA',
                        index: 2,
                      ),
                      _buildDrawerItem(
                        icon: Icons.visibility_rounded,
                        title: 'Visualizaciones',
                        index: 3,
                      ),
                      _buildDrawerItem(
                        icon: Icons.forum_rounded,
                        title: 'Comunidad',
                        index: 4,
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        title: 'Perfil',
                        index: 5,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con cerrar sesión
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red[400]),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _handleLogout,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        body: _screens[_selectedIndex],
      );
    } else {
      // Interfaz con BottomNavigationBar para móviles
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: null,
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF60A5FA),
            unselectedItemColor: const Color(0xFF64748B),
            selectedFontSize: 11,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showUnselectedLabels: true,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              _buildBottomNavItem(Icons.home_rounded, 'Inicio', 0),
              _buildBottomNavItem(Icons.dataset_rounded, 'Datos', 1),
              _buildBottomNavItem(Icons.psychology_rounded, 'IA', 2),
              _buildBottomNavItem(Icons.visibility_rounded, 'Visual', 3),
              _buildBottomNavItem(Icons.forum_rounded, 'Social', 4),
              _buildBottomNavItem(Icons.person_rounded, 'Perfil', 5),
            ],
          ),
        ),
      );
    }
  }

  BottomNavigationBarItem _buildBottomNavItem(
      IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF60A5FA).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
      label: label,
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: const Color(0xFF60A5FA).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Color(0xFF60A5FA), width: 1)
              : BorderSide.none,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF60A5FA).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isSelected ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () => _onDrawerItemTapped(index),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Datos';
      case 2:
        return 'IA';
      case 3:
        return 'Visualizaciones';
      case 4:
        return 'Comunidad';
      case 5:
        return 'Perfil';
      default:
        return 'ExoAi';
    }
  }

  IconData _getAppBarIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.dataset_rounded;
      case 2:
        return Icons.psychology_rounded;
      case 3:
        return Icons.visibility_rounded;
      case 4:
        return Icons.forum_rounded;
      case 5:
        return Icons.person_rounded;
      default:
        return Icons.apps;
    }
  }
}
