import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyetomobile2/views/screens/privacy_policy_screen.dart';
import '../../../viewmodels/login_viewmodel.dart';
import '../../widgets/terms_dialog.dart';


class LoginScreen extends StatefulWidget {
  final Function() onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController nameController;

  bool isLoginMode = true;
  bool showPassword = false;
  bool acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _handleLogin(LoginViewModel viewModel) {
    _performLogin(viewModel);
  }

  Future<void> _performLogin(LoginViewModel viewModel) async {
    final success = await viewModel.loginWithEmail(
      emailController.text.trim(),
      passwordController.text,
    );

    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  void _handleRegister(LoginViewModel viewModel) {
    if (!acceptedTerms) return;
    _performRegister(viewModel);
  }

  Future<void> _performRegister(LoginViewModel viewModel) async {
    final success = await viewModel.registerUser(
      emailInput: emailController.text.trim(),
      passwordInput: passwordController.text,
      nameInput: nameController.text.trim(),
    );

    if (success && mounted) {
      emailController.clear();
      passwordController.clear();
      nameController.clear();
      setState(() {
        isLoginMode = true;
        acceptedTerms = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso. Faça login com sua conta.'),
          backgroundColor: Color(0xFF1B7E3D),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF9500),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    size: 50,
                    color: Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  isLoginMode ? 'Entrar' : 'Criar Conta',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isLoginMode
                      ? 'Insira seus dados para acessar sua conta'
                      : 'Preencha o formulário para se cadastrar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Consumer<LoginViewModel>(
                  builder: (context, viewModel, _) {
                    return Column(
                      children: [
                        if (viewModel.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (!isLoginMode) ...[
                          TextField(
                            controller: nameController,
                            enabled: !viewModel.isLoadingRegister,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Seu nome completo',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon:
                                  const Icon(Icons.person, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1B7E3D),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: emailController,
                          enabled: !viewModel.isLoadingRegister &&
                              !viewModel.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'email@dominio.com',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B7E3D),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          enabled: !viewModel.isLoadingRegister &&
                              !viewModel.isLoading,
                          obscureText: !showPassword,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Senha',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  setState(() => showPassword = !showPassword),
                              child: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B7E3D),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!isLoginMode) ...[
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: acceptedTerms,
                                  onChanged: viewModel.isLoadingRegister
                                      ? null
                                      : (value) {
                                          setState(() {
                                            acceptedTerms = value ?? false;
                                          });
                                        },
                                  activeColor: const Color(0xFF1B7E3D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                                          );
                                        },
                                  child: const Text(
                                    'Eu concordo com os Termos de Uso e Política de Privacidade',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1B7E3D),
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (isLoginMode && viewModel.isLoading) ||
                                    (!isLoginMode &&
                                        (viewModel.isLoadingRegister || !acceptedTerms))
                                ? null
                                : () => isLoginMode
                                    ? _handleLogin(viewModel)
                                    : _handleRegister(viewModel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B7E3D),
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: isLoginMode && viewModel.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : !isLoginMode && viewModel.isLoadingRegister
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        isLoginMode ? 'Entrar' : 'Cadastrar Conta',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLoginMode
                                  ? 'Não tem uma conta? '
                                  : 'Já tem uma conta? ',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: !viewModel.isLoading &&
                                      !viewModel.isLoadingRegister
                                  ? () {
                                      setState(() {
                                        isLoginMode = !isLoginMode;
                                      });
                                      viewModel.errorMessage = null;
                                    }
                                  : null,
                              child: Text(
                                isLoginMode ? 'Cadastre-se' : 'Fazer Login',
                                style: const TextStyle(
                                  color: Color(0xFF1B7E3D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isLoginMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[300],
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[300],
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => viewModel.loginWithGoogle(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade50,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_circle,
                                    color: Color(0xFFFF9500),
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Continuar com o Google',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFFF9500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}