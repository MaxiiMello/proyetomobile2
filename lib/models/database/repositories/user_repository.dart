import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../db_constants.dart';
import '../app_database.dart';

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
    );
  }
}

class UserRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

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
      // En web, retornar usuario demo sin usar BD
      if (kIsWeb) {
        return User(
          id: 1,
          email: email.toLowerCase(),
          name: name,
          phone: phone,
          preferredCityCode: preferredCityCode,
          subscriptionPlan: 'essential',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

      final db = await _db;
      final now = DateTime.now().toUtc();

      // Verificar si el email ya existe
      final existing = await db.query(
        DbConstants.tableUsers,
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existing.isNotEmpty) {
        throw Exception('Email ya está registrado');
      }

      final passwordHash = _hashPassword(password);

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

      return (await getUserById(userId))!;
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  // Login
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      // En web, retornar usuario demo sin usar BD
      if (kIsWeb) {
        return User(
          id: 1,
          email: email.toLowerCase(),
          name: email.split('@').first,
          phone: null,
          preferredCityCode: null,
          subscriptionPlan: 'essential',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

      final db = await _db;
      final result = await db.query(
        DbConstants.tableUsers,
        where: 'email = ? AND is_active = 1',
        whereArgs: [email.toLowerCase()],
      );

      if (result.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final record = result.first;
      final storedHash = record['password_hash'] as String;

      if (!_verifyPassword(password, storedHash)) {
        throw Exception('Contraseña incorrecta');
      }

      // Actualizar último login
      final now = DateTime.now().toUtc().toIso8601String();
      await db.update(
        DbConstants.tableUsers,
        {'last_login': now},
        where: 'id = ?',
        whereArgs: [record['id']],
      );

      return User.fromMap(record);
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // Obtener usuario por ID
  Future<User?> getUserById(int userId) async {
    try {
      final db = await _db;
      final result = await db.query(
        DbConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) return null;
      return User.fromMap(result.first);
    } catch (e) {
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
