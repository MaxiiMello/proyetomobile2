import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/database/database_bootstrap.dart';
import 'models/database/web_user_storage.dart';
import 'views/screens/login/login_screen.dart';
import 'views/screens/plans/plans_screen.dart';
import 'views/screens/map/map_screen.dart';
import 'views/screens/settings/settings_screen.dart';
import 'views/screens/profile/profile_screen.dart';
import 'views/widgets/bottom_nav_bar.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/map_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite based on the specific platform
  if (kIsWeb) {
    // Flutter Web - NO necesita sqflite, usa WebUserStorage + SharedPreferences
    debugPrint('🌐 Ejecutando en WEB - usando WebUserStorage con SharedPreferences');
    debugPrint('⏭️ Saltando inicialización de sqflite para web');
    
    // Initialize web storage BEFORE anything else
    try {
      debugPrint('🔧 Inicializando WebUserStorage...');
      await WebUserStorage().initialize();
      debugPrint('✅ WebUserStorage inicializado correctamente');
    } catch (e) {
      debugPrint('⚠️ Error inicializando WebUserStorage: $e');
    }
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop platforms - usa sqflite
    debugPrint('🖥️ Ejecutando en DESKTOP - usando sqflite');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // Mobile platforms - usa sqflite
    debugPrint('📱 Ejecutando en MOBILE - usando sqflite');
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

  // Inicializar SessionService
  try {
    await SessionService().initialize();
  } catch (e) {
    debugPrint('SessionService initialization skipped: $e');
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
  bool isCheckingSession = true;
  late LoginViewModel _loginViewModel;

  @override
  void initState() {
    super.initState();
    _loginViewModel = LoginViewModel();
    _restoreSessionIfExists();
  }

  Future<void> _restoreSessionIfExists() async {
    try {
      final sessionRestored = await _loginViewModel.restoreSession();
      
      if (mounted) {
        setState(() {
          isLoggedIn = sessionRestored;
          isCheckingSession = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao restaurar sessão: $e');
      if (mounted) {
        setState(() {
          isCheckingSession = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _loginViewModel.logout();
    if (mounted) {
      setState(() {
        isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto verifica sessão
    if (isCheckingSession) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Carregando...'),
            ],
          ),
        ),
      );
    }

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
          onLogout: _handleLogout,
        );
      default:
        return const MapScreen();
    }
  }
}