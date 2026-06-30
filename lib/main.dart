import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:proyetomobile2/models/database/database_bootstrap.dart';
import 'package:proyetomobile2/models/database/web_user_storage.dart';
import 'package:proyetomobile2/services/notification_service.dart';
import 'package:proyetomobile2/services/session_service.dart';
import 'package:proyetomobile2/viewmodels/settings_viewmodel.dart';
import 'package:proyetomobile2/viewmodels/profile_viewmodel.dart';
import 'package:proyetomobile2/viewmodels/login_viewmodel.dart';
import 'package:proyetomobile2/viewmodels/map_viewmodel.dart';
import 'package:proyetomobile2/viewmodels/settings_viewmodel.dart';
import 'package:proyetomobile2/views/screens/login/login_screen.dart';
import 'package:proyetomobile2/views/screens/map/map_screen.dart';
import 'package:proyetomobile2/views/screens/profile/profile_screen.dart';
import 'package:proyetomobile2/views/screens/settings/settings_screen.dart';
import 'package:proyetomobile2/views/wearable/wearable_screen.dart';
import 'package:proyetomobile2/views/widgets/bottom_nav_bar.dart';
import 'package:proyetomobile2/views/screens/plans/premium_screen.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (kIsWeb) {
    try {
      await WebUserStorage().initialize();
    } catch (e) {}
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await DatabaseBootstrap.initialize();
  } catch (e) {}

  try {
    await NotificationService.instance.initialize();
  } catch (e) {}

  try {
    await SessionService().initialize();
  } catch (e) {}

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: MaterialApp(
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
      ),
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
      if (mounted) {
        setState(() {
          isCheckingSession = false;
        });
      }
    } finally {
      FlutterNativeSplash.remove();
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
    if (isCheckingSession) {
      return const Scaffold(backgroundColor: Colors.white);
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
    } catch (e) {
      return const Scaffold(body: Center(child: Text('Erro na navegação.')));
    }
  }

  Widget _buildBody() {
    switch (currentIndex) {
      case 0:
        return const PremiumScreen();
      case 1:
        return const MapScreen();
      case 2:
        return ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
          child: const SettingsScreen(),
        );
      case 3:
        return ProfileScreen(onLogout: _handleLogout);
      default:
        return const MapScreen();
    }
  }
}
