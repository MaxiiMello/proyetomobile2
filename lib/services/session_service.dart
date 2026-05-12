import 'package:shared_preferences/shared_preferences.dart';
import '../models/database/repositories/user_repository.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();

  static const String _userIdKey = 'current_user_id';
  static const String _userEmailKey = 'current_user_email';
  static const String _sessionActiveKey = 'session_active';

  late SharedPreferences _prefs;
  User? _currentUser;
  bool _isInitialized = false;

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  /// Inicializar o serviço de sessão
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      print('❌ Erro ao inicializar SessionService: $e');
      rethrow;
    }
  }

  /// Garantir que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Salvar sessão após login bem-sucedido
  Future<void> saveSession(User user) async {
    try {
      print('💾 Salvando sessão para usuário: ${user.email}');
      await _ensureInitialized();
      await _prefs.setInt(_userIdKey, user.id);
      await _prefs.setString(_userEmailKey, user.email);
      await _prefs.setBool(_sessionActiveKey, true);
      _currentUser = user;
      print('✅ Sessão salva com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar sessão: $e');
      rethrow;
    }
  }

  /// Restaurar sessão do dispositivo
  Future<User?> restoreSession() async {
    try {
      await _ensureInitialized();
      final isActive = _prefs.getBool(_sessionActiveKey) ?? false;
      if (!isActive) {
        return null;
      }

      final userId = _prefs.getInt(_userIdKey);
      if (userId == null) {
        return null;
      }

      // Buscar usuário no banco de dados
      final userRepository = UserRepository();
      final user = await userRepository.getUserById(userId);

      if (user != null) {
        _currentUser = user;
        return user;
      } else {
        // Usuário não encontrado, limpar sessão
        await clearSession();
        return null;
      }
    } catch (e) {
      print('❌ Erro ao restaurar sessão: $e');
      return null;
    }
  }

  /// Limpar sessão (logout)
  Future<void> clearSession() async {
    try {
      await _ensureInitialized();
      await _prefs.remove(_userIdKey);
      await _prefs.remove(_userEmailKey);
      await _prefs.remove(_sessionActiveKey);
      _currentUser = null;
    } catch (e) {
      print('❌ Erro ao limpar sessão: $e');
      rethrow;
    }
  }

  /// Obter usuário atual em memória
  User? get currentUser => _currentUser;

  /// Verificar se tem sessão ativa
  bool get isSessionActive => _prefs.getBool(_sessionActiveKey) ?? false;

  /// Obter ID do usuário atual
  int? get currentUserId => _prefs.getInt(_userIdKey);

  /// Obter email do usuário atual
  String? get currentUserEmail => _prefs.getString(_userEmailKey);
}
