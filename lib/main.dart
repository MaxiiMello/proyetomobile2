import 'package:flutter/material.dart';

import 'model/database/database_bootstrap.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plans_screen_new.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar banco de dados com tratamento seguro para web
  try {
    await DatabaseBootstrap.initialize();
  } catch (e) {
    // Em web, o banco de dados não é suportado, apenas continua
    debugPrint('Database initialization skipped: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinalVerde',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1B7E3D),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool isLoggedIn = false;
  int currentIndex = 2; // Home é o índice padrão

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            isLoggedIn = true;
          });
        },
      );
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (currentIndex) {
      case 0: // Planos
        return const PlansScreen();
      case 1: // Mapa
        return const MapScreen();
      case 2: // Home
        return const HomeScreen();
      case 3: // Configurações
        return const SettingsScreen();
      case 4: // Perfil
        return ProfileScreen(
          onLogout: () {
            setState(() {
              isLoggedIn = false;
            });
          },
        );
      default:
        return const HomeScreen();
    }
  }
}
