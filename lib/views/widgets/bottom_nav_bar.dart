import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedItemColor: const Color(0xFF1B7E3D),
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard, size: 22),
          label: 'Planos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map, size: 22),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 22),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: 22),
          label: 'Configurações',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 22),
          label: 'Perfil',
        ),
      ],
    );
  }
}
