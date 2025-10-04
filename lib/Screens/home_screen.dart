import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_content.dart';

import '../Servicios/firebase_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Lista de pantallas que se mostrarán
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Obtenemos el nombre del usuario de Firebase
    final user = _authService.currentUser;
    final userName = user?.displayName?.split(' ')[0] ?? 'Usuario';

    // Inicializamos la lista de pantallas con el nombre real del usuario
    _screens = [
      // Pantalla de inicio con el nombre del usuario de Google
      HomeContent(userName: userName),
      // Pantalla de control de bloqueo
      //const BlockingScreen(),
      // Pantalla de navegador seguro
      //const WebBrowserScreen(),
      // Pantalla de chat de apoyo
      //const ChatScreen(),
      // Pantalla de perfil personalizada
      //ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.shield),
            label: 'Bloqueo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.web),
            label: 'Navegador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Apoyo',
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
