import 'package:flutter/material.dart';

import 'core/database/database_bootstrap.dart';
import 'views/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseBootstrap.initialize();
  runApp(const MainApp());
}
