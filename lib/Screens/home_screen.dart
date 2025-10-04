import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_content.dart';
import 'datos_screen.dart';
import 'ia_screen.dart';
import 'visualizaciones_screen.dart';
import 'profile_screen.dart';
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
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      const DatosScreen(),
      const IAScreen(),
      const VisualizacionesScreen(),
      ProfileScreen(userName: userName),
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.blue[600]),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            _getAppBarTitle(),
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              // Header del drawer con información del usuario
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue[600],
                        ),
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(userEmail),
              ),
              // Items del menú
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Inicio',
                      index: 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.dataset,
                      title: 'Datos',
                      index: 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.psychology,
                      title: 'IA',
                      index: 2,
                    ),
                    _buildDrawerItem(
                      icon: Icons.visibility,
                      title: 'Visualizaciones',
                      index: 3,
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Perfil',
                      index: 4,
                    ),
                  ],
                ),
              ),
              // Footer con cerrar sesión
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[400]),
                title: const Text('Cerrar sesión'),
                onTap: _handleLogout,
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
        backgroundColor: Colors.white,
        appBar: null,
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[400],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dataset),
              label: 'Datos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'IA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.visibility),
              label: 'Visualizaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[600] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue[600] : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _onDrawerItemTapped(index),
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
        return 'Perfil';
      default:
        return 'ExoAi';
    }
  }
}
