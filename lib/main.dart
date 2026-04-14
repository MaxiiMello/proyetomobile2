import 'package:flutter/material.dart';

import 'models/database/database_bootstrap.dart';
import 'views/screens/login/login_screen.dart';
import 'views/screens/home/home_screen.dart';
import 'views/screens/plans/plans_screen.dart';
import 'views/screens/map/map_screen.dart';
import 'views/screens/settings/settings_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/widgets/bottom_nav_bar.dart';

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

    try {
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
    } catch (e, stackTrace) {
      debugPrint('Error in MainNavigation.build: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Text('Erro na navegação: $e'),
        ),
      );
    }
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
