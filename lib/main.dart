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
import 'views/wearable/wearable_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite based on the specific platform
  if (kIsWeb) {
    // Flutter Web - não usa sqflite
    debugPrint('🌐 Executando em WEB - usando WebUserStorage com SharedPreferences');
    debugPrint('⏭️ Pulando inicialização do sqflite para web');

    try {
      debugPrint('🔧 Inicializando WebUserStorage...');
      await WebUserStorage().initialize();
      debugPrint('✅ WebUserStorage inicializado corretamente');
    } catch (e) {
      debugPrint('⚠️ Erro inicializando WebUserStorage: $e');
    }
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop - obrigatório inicializar sqflite_common_ffi
    debugPrint('🖥️ Executando em DESKTOP - usando sqflite_common_ffi');

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    debugPrint('✅ databaseFactory inicializado com databaseFactoryFfi');
  } else {
    // Android/iOS - sqflite funciona automaticamente
    debugPrint('📱 Executando em MOBILE - usando sqflite');
  }

  // Inicializar banco
  try {
    debugPrint('🔧 Inicializando DatabaseBootstrap...');
    await DatabaseBootstrap.initialize();
    debugPrint('✅ DatabaseBootstrap inicializado com sucesso');
  } catch (e, stackTrace) {
    debugPrint('❌ Database initialization failed: $e');
    debugPrint('$stackTrace');
  }

  // Inicializar notificações
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification initialization skipped: $e');
  }

  // Inicializar sessão
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
      routes: {
        '/wearable': (context) => const WearableScreen(),
      },
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
  int currentIndex = 1;
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
          if (sessionRestored) {
            currentIndex = 1;
          }
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
              currentIndex = 1;
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