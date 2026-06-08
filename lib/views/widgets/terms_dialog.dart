import 'package:flutter/material.dart';

void showTermsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        'Termos e Privacidade',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const SingleChildScrollView(
        child: Text(
          '''1. Uso do Aplicativo
Este aplicativo tem como objetivo o cálculo de rotas e navegação offline. Para o seu correto funcionamento, é necessário o download de pacotes de mapas para o armazenamento interno do dispositivo.

2. Geolocalização e Rotas
A sua localização em tempo real é processada exclusivamente de forma local no seu aparelho para traçar as rotas. Não rastreamos, compartilhamos nem armazenamos seu histórico de localização em nossos servidores externos.

3. Coleta de Dados (LGPD)
Coletamos os dados básicos informados no cadastro (nome e email) apenas para a gestão de contas e assinaturas. O usuário pode exercer seu direito de exclusão definitiva da conta e limpeza de dados a qualquer momento pelo menu de Perfil.

4. Armazenamento Offline
O uso do sistema requer espaço de armazenamento no dispositivo para os mapas. O usuário é responsável por gerenciar esse espaço, podendo excluir os downloads pelas configurações.

5. Assinaturas Premium
O acesso a recursos avançados de roteamento pode depender de uma assinatura ativa. O usuário pode gerenciar sua renovação diretamente no aplicativo.''',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1B7E3D),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}