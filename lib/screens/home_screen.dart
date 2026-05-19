import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'favoritos_screen.dart';
import 'perfil_screen.dart';
import 'cercanos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final GlobalKey<PerfilScreenState> _perfilKey = GlobalKey<PerfilScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const CercanosScreen(),
          const FavoritosScreen(),
          PerfilScreen(key: _perfilKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2 && _selectedIndex == 2) {
            _perfilKey.currentState?.refreshStats();
          }
          setState(() => _selectedIndex = index);
        },
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.near_me), label: 'Cercanos'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
