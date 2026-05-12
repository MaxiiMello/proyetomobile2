import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../db_constants.dart';
import '../app_database.dart';
import '../web_user_storage.dart';

class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String? preferredCityCode;
  final String subscriptionPlan;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final String? passwordHash; // Para uso interno de autenticación

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.preferredCityCode,
    required this.subscriptionPlan,
    this.subscriptionEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.passwordHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'preferred_city_code': preferredCityCode,
      'subscription_plan': subscriptionPlan,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'password_hash': passwordHash,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      preferredCityCode: map['preferred_city_code'] as String?,
      subscriptionPlan: map['subscription_plan'] as String? ?? 'essential',
      subscriptionEndDate: map['subscription_end_date'] != null
          ? DateTime.parse(map['subscription_end_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
      passwordHash: map['password_hash'] as String?,
    );
  }
}

class UserRepository {
  final _webStorage = WebUserStorage();
  
  Future<Database> get _db async => AppDatabase.instance.database;

  /// Verificar si está en web
  bool get _isWeb => kIsWeb;

  // Hash de contraseña con salt
  static String _hashPassword(String password, {String? salt}) {
    salt ??= DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$password$salt');
    final hashedPassword = sha256.convert(bytes).toString();
    return '$salt:$hashedPassword';
  }

  static bool _verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      final storedHash = parts[1];
      final bytes = utf8.encode('$password$salt');
      final computedHash = sha256.convert(bytes).toString();
      return computedHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Registrar nuevo usuario
  Future<User> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? preferredCityCode,
  }) async {
    try {
      print('📝 Iniciando registro para: $email (Platform: ${_isWeb ? "Web" : "Mobile/Desktop"})');
      
      if (_isWeb) {
        // En web, usar WebUserStorage
        print('🌐 Usando WebUserStorage para registro');
        await _webStorage.initialize();
        
        // Verificar si el email ya existe
        print('🔍 Verificando si el email existe...');
        final existing = await _webStorage.getUserByEmail(email);
        
        if (existing != null) {
          throw Exception('Email ya está registrado');
        }

        print('✅ Email disponible');
        final passwordHash = _hashPassword(password);

        print('💾 Insertando usuario en almacenamiento web...');
        final userId = await _webStorage.saveUser(User(
          id: 0, // ID temporal, será actualizado
          email: email.toLowerCase(),
          passwordHash: passwordHash,
          name: name,
          phone: phone,
          preferredCityCode: preferredCityCode,
          subscriptionPlan: 'essential',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        print('✅ Usuario insertado con ID: $userId');
        final user = await _webStorage.getUserById(userId);
        print('✅ Registro exitoso para: $email');
        return user!;
      } else {
        // En mobile/desktop, usar SQLite
        print('📱 Usando SQLite para registro');
        final db = await _db;
        print('✅ Banco de datos conectado');
        
        final now = DateTime.now().toUtc();

        // Verificar si el email ya existe
        print('🔍 Verificando si el email existe...');
        final existing = await db.query(
          DbConstants.tableUsers,
          where: 'email = ?',
          whereArgs: [email.toLowerCase()],
        );

        if (existing.isNotEmpty) {
          throw Exception('Email ya está registrado');
        }

        print('✅ Email disponible');
        final passwordHash = _hashPassword(password);

        print('💾 Insertando usuario en la base de datos...');
        final userId = await db.insert(
          DbConstants.tableUsers,
          {
            'email': email.toLowerCase(),
            'password_hash': passwordHash,
            'name': name,
            'phone': phone,
            'preferred_city_code': preferredCityCode,
            'subscription_plan': 'essential',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        );

        print('✅ Usuario insertado con ID: $userId');
        final user = await getUserById(userId);
        print('✅ Registro exitoso para: $email');
        return user!;
      }
    } catch (e) {
      print('❌ Error en registro: $e');
      throw Exception('Error al registrar: $e');
    }
  }

  // Login
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Iniciando login para: $email (Platform: ${_isWeb ? "Web" : "Mobile/Desktop"})');
      
      if (_isWeb) {
        // En web, usar WebUserStorage
        print('🌐 Usando WebUserStorage para login');
        await _webStorage.initialize();
        
        final user = await _webStorage.getUserByEmail(email);
        if (user == null) {
          throw Exception('Usuário não encontrado. Faça o registro primeiro!');
        }

        print('✅ Usuario encontrado: ${user.email}');
        print('🔐 passwordHash from DB: ${user.passwordHash}');
        
        final storedHash = user.passwordHash;
        print('🔐 storedHash variable: $storedHash');
        
        if (storedHash == null) {
          print('❌ ERROR: storedHash é null! O passwordHash não foi salvo corretamente');
          throw Exception('Senha não está configurada para este usuário');
        }
        
        if (!_verifyPassword(password, storedHash)) {
          print('❌ Verificação de senha falhou');
          print('   Password fornecida: $password');
          print('   Hash armazenado: $storedHash');
          throw Exception('Senha incorreta');
        }

        print('✅ Senha verificada corretamente!');
        // Actualizar último login
        final updatedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          phone: user.phone,
          preferredCityCode: user.preferredCityCode,
          subscriptionPlan: user.subscriptionPlan,
          subscriptionEndDate: user.subscriptionEndDate,
          createdAt: user.createdAt,
          updatedAt: DateTime.now(),
          lastLogin: DateTime.now(),
          passwordHash: storedHash, // Mantener el hash
        );
        
        await _webStorage.updateUser(updatedUser);
        print('✅ Login bem-sucedido para: $email (Web)');
        return updatedUser;
      } else {
        // En mobile/desktop, usar SQLite
        print('📱 Usando SQLite para login');
        final db = await _db;
        print('✅ Banco de datos conectado');
        
        final result = await db.query(
          DbConstants.tableUsers,
          where: 'email = ?',
          whereArgs: [email.toLowerCase()],
        );
        print('📊 Resultado da query: ${result.length} registros encontrados');

        if (result.isEmpty) {
          throw Exception('Usuário não encontrado. Faça o registro primeiro!');
        }

        final record = result.first;
        final storedHash = record['password_hash'] as String;

        if (!_verifyPassword(password, storedHash)) {
          throw Exception('Senha incorreta');
        }

        // Actualizar último login
        final now = DateTime.now().toUtc().toIso8601String();
        await db.update(
          DbConstants.tableUsers,
          {'last_login': now},
          where: 'id = ?',
          whereArgs: [record['id']],
        );

        print('✅ Login bem-sucedido para: $email');
        return User.fromMap(record);
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      throw Exception('Erro no login: $e');
    }
  }

  // Obtener usuario por ID
  Future<User?> getUserById(int userId) async {
    try {
      print('🔍 Buscando usuario con ID: $userId');
      
      if (_isWeb) {
        // En web, usar WebUserStorage
        print('🌐 Usando WebUserStorage para obtener usuario');
        await _webStorage.initialize();
        final user = await _webStorage.getUserById(userId);
        if (user != null) {
          print('✅ Usuario encontrado: ID $userId (Web)');
        } else {
          print('⚠️ Usuario con ID $userId no encontrado (Web)');
        }
        return user;
      } else {
        // En mobile/desktop, usar SQLite
        print('📱 Usando SQLite para obtener usuario');
        final db = await _db;
        final result = await db.query(
          DbConstants.tableUsers,
          where: 'id = ?',
          whereArgs: [userId],
        );

        if (result.isEmpty) {
          print('⚠️ Usuario con ID $userId no encontrado');
          return null;
        }
        print('✅ Usuario encontrado: ID $userId');
        return User.fromMap(result.first);
      }
    } catch (e) {
      print('❌ Error al obtener usuario: $e');
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // Obtener usuario por email
  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await _db;
      final result = await db.query(
        DbConstants.tableUsers,
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (result.isEmpty) return null;
      return User.fromMap(result.first);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // Actualizar perfil
  Future<User?> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? preferredCityCode,
  }) async {
    try {
      final db = await _db;
      final now = DateTime.now().toUtc().toIso8601String();

      final updateData = <String, dynamic>{
        'updated_at': now,
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (preferredCityCode != null) updateData['preferred_city_code'] = preferredCityCode;

      await db.update(
        DbConstants.tableUsers,
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return await getUserById(userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  // Cambiar contraseña
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final db = await _db;
      final result = await db.query(
        DbConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final storedHash = result.first['password_hash'] as String;
      if (!_verifyPassword(oldPassword, storedHash)) {
        throw Exception('Contraseña actual incorrecta');
      }

      final newHash = _hashPassword(newPassword);
      final now = DateTime.now().toUtc().toIso8601String();

      await db.update(
        DbConstants.tableUsers,
        {
          'password_hash': newHash,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  // Actualizar suscripción
  Future<User?> updateSubscription({
    required int userId,
    required String plan,
    int? daysValid,
  }) async {
    try {
      final db = await _db;
      final now = DateTime.now().toUtc();
      final endDate = daysValid != null ? now.add(Duration(days: daysValid)) : null;

      await db.update(
        DbConstants.tableUsers,
        {
          'subscription_plan': plan,
          'subscription_end_date': endDate?.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return await getUserById(userId);
    } catch (e) {
      throw Exception('Error al actualizar suscripción: $e');
    }
  }
}
