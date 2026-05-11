import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'models/database/database_bootstrap.dart';
import 'views/screens/login/login_screen.dart';
import 'views/screens/plans/plans_screen.dart';
import 'views/screens/map/map_screen.dart';
import 'views/screens/settings/settings_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/widgets/bottom_nav_bar.dart';
import 'services/notification_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o SQLite para todas as plataformas
  if (kIsWeb) {
    // Flutter Web
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Windows, Linux, macOS, Android e iOS
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await DatabaseBootstrap.initialize();
  } catch (e) {
    debugPrint('Database initialization skipped: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification initialization skipped: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinalVerde',
      debugShowCheckedModeBanner: false,
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
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: LoginScreen(
          onLoginSuccess: () {
            setState(() {
              isLoggedIn = true;
            });
          },
        ),
      );
    }

    try {
      return ChangeNotifierProvider(
        create: (_) => MapViewModel(),
        child: Scaffold(
          body: _buildBody(),
          bottomNavigationBar: BottomNavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
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
      case 0:
        return const PlansScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const SettingsScreen();
      case 3:
        return ProfileScreen(
          onLogout: () {
            setState(() {
              isLoggedIn = false;
            });
          },
        );
      default:
        return const MapScreen();
    }
  }
}