import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'repositories/user_repository.dart';

class WebUserStorage {
  static final WebUserStorage _instance = WebUserStorage._internal();
  static const String _usersKey = 'web_users_storage';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  factory WebUserStorage() {
    return _instance;
  }

  WebUserStorage._internal();

  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ WebUserStorage ya está inicializado, saltando reinicialización');
      return;
    }
    try {
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║        🔧 INICIALIZANDO WEBUSERTORAGE                ║');
      print('╚════════════════════════════════════════════════════════╝');
      
      print('📌 Paso 1: Obteniendo instancia de SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      print('  ✅ SharedPreferences obtenido');
      
      _isInitialized = true;
      print('  ✅ _isInitialized = true');
      
      print('\n📌 Paso 2: Verificando datos existentes...');
      final rawJson = _prefs.getString(_usersKey);
      
      if (rawJson == null) {
        print('  ⚠️ No hay datos guardados (primera ejecución)');
      } else {
        print('  ✅ Datos encontrados (${rawJson.length} caracteres)');
        print('  Contenido: $rawJson');
      }
      
      print('\n📌 Paso 3: Cargando usuarios...');
      final users = await getAllUsers();
      print('  ✅ Usuarios cargados: ${users.length}');
      
      if (users.isNotEmpty) {
        for (var user in users) {
          print('      - ${user.email} (ID: ${user.id}, hasPassword: ${user.passwordHash != null})');
        }
      } else {
        print('  📝 Sin usuarios. Creando usuario de prueba...');
        await _createTestUser();
      }
      
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║      ✅ WEBUSERTORAGE INICIALIZADO CORRECTAMENTE      ║');
      print('╚════════════════════════════════════════════════════════╝\n');
    } catch (e) {
      print('\n❌ ERROR al inicializar WebUserStorage: $e');
      print('╚════════════════════════════════════════════════════════╝\n');
      rethrow;
    }
  }

  Future<void> _createTestUser() async {
    try {
      print('📝 Creando usuario de prueba para web...');
      final passwordHash = _hashPassword('password123');
      print('🔐 Hash de contraseña creado: $passwordHash');
      
      final testUser = User(
        id: 1,
        email: 'test@example.com',
        name: 'Usuario Prueba',
        phone: '+1234567890',
        preferredCityCode: 'ny',
        subscriptionPlan: 'essential',
        subscriptionEndDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: null,
        passwordHash: passwordHash,
      );
      
      print('📋 User object creado: ${testUser.toMap()}');
      final jsonData = jsonEncode([testUser.toMap()]);
      print('💾 JSON a guardar: $jsonData');
      
      await _prefs.setString(_usersKey, jsonData);
      print('✅ Usuario de prueba creado: test@example.com / password123');
      print('🔐 Hash almacenado: $passwordHash');
    } catch (e) {
      print('⚠️ Error creando usuario de prueba: $e');
    }
  }

  static String _hashPassword(String password, {String? salt}) {
    salt ??= DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$password$salt');
    final hashedPassword = sha256.convert(bytes).toString();
    return '$salt:$hashedPassword';
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<List<User>> getAllUsers() async {
    await _ensureInitialized();
    try {
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║          📖 LEYENDO USUARIOS DE SHAREPREFS             ║');
      print('╚════════════════════════════════════════════════════════╝');
      
      final json = _prefs.getString(_usersKey);
      print('📝 JSON en SharedPreferences:');
      
      if (json == null) {
        print('  ⚠️ NULL - No hay usuarios guardados');
        print('╚════════════════════════════════════════════════════════╝\n');
        return [];
      }
      
      print('  ✅ Presente (${json.length} caracteres)');
      print('  Contenido: $json');
      
      try {
        final list = jsonDecode(json) as List;
        print('\n📊 Decodificado: ${list.length} usuarios en JSON');
        
        final users = list.map((e) {
          final userMap = e as Map<String, dynamic>;
          print('\n🔍 Procesando usuario:');
          print('  email: ${userMap['email']}');
          print('  password_hash en JSON: ${userMap['password_hash']}');
          
          final user = User.fromMap(userMap);
          print('  ✅ User creado:');
          print('      - email: ${user.email}');
          print('      - passwordHash: ${user.passwordHash}');
          return user;
        }).toList();
        
        print('\n✅ ${users.length} usuarios cargados exitosamente');
        print('╚════════════════════════════════════════════════════════╝\n');
        return users;
      } catch (decodeError) {
        print('❌ Error decodificando JSON: $decodeError');
        print('╚════════════════════════════════════════════════════════╝\n');
        throw Exception('Error decodificando usuarios: $decodeError');
      }
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      print('╚════════════════════════════════════════════════════════╝\n');
      return [];
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      print('🔍 Buscando usuario por email: $email');
      final users = await getAllUsers();
      print('  Total usuarios en storage: ${users.length}');
      
      final emailLower = email.toLowerCase();
      final found = users.firstWhere(
        (user) => user.email == emailLower,
        orElse: () => null as User,
      );
      
      print('✅ Usuario encontrado: ${found.email}');
          
      return found;
    } catch (e) {
      print('❌ Error al obtener usuario por email: $e');
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      print('🔍 Buscando usuario por ID: $id');
      final users = await getAllUsers();
      print('  Total usuarios en storage: ${users.length}');
      
      final found = users.firstWhere(
        (user) => user.id == id,
        orElse: () => null as User,
      );
      
      print('✅ Usuario encontrado: ${found.email} (ID: $id)');
          
      return found;
    } catch (e) {
      print('❌ Error al obtener usuario por ID: $e');
      return null;
    }
  }

  Future<int> saveUser(User user) async {
    try {
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║          📝 REGISTRANDO NUEVO USUARIO                ║');
      print('╚════════════════════════════════════════════════════════╝');
      print('📌 Email: ${user.email}');
      print('📌 Nombre: ${user.name}');
      print('📌 passwordHash recibido: ${user.passwordHash}');
      
      await _ensureInitialized();
      print('  ✅ WebUserStorage inicializado');
      
      final users = await getAllUsers();
      print('  ✅ Usuarios actuales: ${users.length}');

      if (users.any((u) => u.email == user.email.toLowerCase())) {
        print('❌ Email ya registrado');
        throw Exception('Email ya está registrado');
      }
      print('  ✅ Email disponible');

      final newId = users.isEmpty ? 1 : (users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1);
      print('  ✅ Nuevo ID asignado: $newId');
      
      final newUser = User(
        id: newId,
        email: user.email.toLowerCase(),
        name: user.name,
        phone: user.phone,
        preferredCityCode: user.preferredCityCode,
        subscriptionPlan: user.subscriptionPlan,
        subscriptionEndDate: user.subscriptionEndDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: null,
        passwordHash: user.passwordHash,
      );
      
      print('\n📌 Nuevo usuario creado en memoria:');
      print('  - ID: ${newUser.id}');
      print('  - Email: ${newUser.email}');
      print('  - passwordHash: ${newUser.passwordHash}');

      users.add(newUser);
      print('\n📌 Usuario agregado a lista (total: ${users.length})');
      
      print('\n📌 Guardando ${users.length} usuarios...');
      await _saveUsers(users);
      
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║      ✅ USUARIO REGISTRADO EXITOSAMENTE CON ID: $newId     ║');
      print('╚════════════════════════════════════════════════════════╝\n');
      return newId;
    } catch (e) {
      print('\n❌ ERROR al guardar usuario: $e');
      print('╚════════════════════════════════════════════════════════╝\n');
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _ensureInitialized();
      final users = await getAllUsers();
      final index = users.indexWhere((u) => u.id == user.id);

      if (index == -1) {
        throw Exception('Usuario no encontrado');
      }

      users[index] = user;
      await _saveUsers(users);
      print('✅ Usuario actualizado: ${user.email}');
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      rethrow;
    }
  }

  Future<void> _saveUsers(List<User> users) async {
    try {
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║          💾 SALVANDO USUARIOS EN SHAREPREFS            ║');
      print('╚════════════════════════════════════════════════════════╝');
      print('📊 Total usuarios a guardar: ${users.length}');
      
      final maps = users.map((u) => u.toMap()).toList();
      print('\n📋 Mapas creados:');
      for (var i = 0; i < maps.length; i++) {
        final map = maps[i];
        print('  [$i] Email: ${map['email']}');
        print('       passwordHash: ${map['password_hash']}');
      }
      
      final json = jsonEncode(maps);
      print('\n📝 JSON completo a guardar:');
      print('  Longitud: ${json.length} caracteres');
      print('  Contenido: $json');
      
      print('\n🔍 Verificando SharedPreferences...');
      print('  _prefs inicializado: $_isInitialized');
      print('  _prefs es nulo: ${"NO (OK)"}');
      
      print('\n💾 Ejecutando _prefs.setString()...');
      final success = await _prefs.setString(_usersKey, json);
      print('  ✅ setString retornó: $success');
      
      print('\n✔️ VERIFICANDO QUE SE GUARDÓ CORRECTAMENTE...');
      final saved = _prefs.getString(_usersKey);
      print('  Datos en memoria: ${saved == null ? "NULL (ERROR!)" : "Presentes (${saved.length} chars)"}');
      
      if (saved == null) {
        print('❌ ERROR CRÍTICO: SharedPreferences no guardó los datos!');
        throw Exception('SharedPreferences no guardó los datos');
      }
      
      if (saved == json) {
        print('  ✅ Contenido guardado = Contenido esperado ✅');
      } else {
        print('  ❌ CONTENIDO NO COINCIDE!');
        print('  Esperado: $json');
        print('  Guardado: $saved');
        throw Exception('Contenido guardado no coincide con lo esperado');
      }
      
      print('\n╔════════════════════════════════════════════════════════╗');
      print('║        ✅ DATOS GUARDADOS EXITOSAMENTE EN WEB        ║');
      print('╚════════════════════════════════════════════════════════╝\n');
    } catch (e) {
      print('❌ ERROR CRÍTICO al guardar usuarios: $e');
      print('╚════════════════════════════════════════════════════════╝\n');
      rethrow;
    }
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _prefs.remove(_usersKey);
    print('✅ Almacenamiento limpiado');
  }

  Future<void> deleteUser(int userId) async {
    final users = await getAllUsers();
    users.removeWhere((user) => user.id == userId);
    await _saveUsers(users);
  }
}