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
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();

      _isInitialized = true;

      final rawJson = _prefs.getString(_usersKey);

      if (rawJson == null) {
      } else {}

      final users = await getAllUsers();

      if (users.isNotEmpty) {
        for (var user in users) {}
      } else {
        await _createTestUser();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createTestUser() async {
    try {
      final passwordHash = _hashPassword('password123');

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

      final jsonData = jsonEncode([testUser.toMap()]);

      await _prefs.setString(_usersKey, jsonData);
    } catch (e) {}
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
      final json = _prefs.getString(_usersKey);
      print('📝 JSON en SharedPreferences:');

      if (json == null) {
        return [];
      }

      try {
        final list = jsonDecode(json) as List;

        final users = list.map((e) {
          final userMap = e as Map<String, dynamic>;

          final user = User.fromMap(userMap);
          return user;
        }).toList();

        return users;
      } catch (decodeError) {
        throw Exception('Error decodificando usuarios: $decodeError');
      }
    } catch (e) {
      return [];
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final users = await getAllUsers();

      final emailLower = email.toLowerCase();
      final found = users.firstWhere(
        (user) => user.email == emailLower,
        orElse: () => null as User,
      );

      return found;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final users = await getAllUsers();

      final found = users.firstWhere(
        (user) => user.id == id,
        orElse: () => null as User,
      );

      return found;
    } catch (e) {
      print('❌ Error al obtener usuario por ID: $e');
      return null;
    }
  }

  Future<int> saveUser(User user) async {
    try {
      await _ensureInitialized();

      final users = await getAllUsers();

      if (users.any((u) => u.email == user.email.toLowerCase())) {
        throw Exception('Email ya está registrado');
      }

      final newId = users.isEmpty
          ? 1
          : (users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1);

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

      users.add(newUser);

      await _saveUsers(users);

      return newId;
    } catch (e) {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUsers(List<User> users) async {
    try {
      final maps = users.map((u) => u.toMap()).toList();
      for (var i = 0; i < maps.length; i++) {
        final map = maps[i];
      }

      final json = jsonEncode(maps);
      final success = await _prefs.setString(_usersKey, json);

      final saved = _prefs.getString(_usersKey);

      if (saved == null) {
        throw Exception('SharedPreferences no guardó los datos');
      }

      if (saved == json) {
      } else {
        throw Exception('Contenido guardado no coincide con lo esperado');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _prefs.remove(_usersKey);
  }

  Future<void> deleteUser(int userId) async {
    final users = await getAllUsers();
    users.removeWhere((user) => user.id == userId);
    await _saveUsers(users);
  }
}
