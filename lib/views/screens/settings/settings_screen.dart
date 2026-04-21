import 'package:flutter/material.dart';

import '../../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
      ),
      body: ListView(
        children: [
          _buildSettingsSection(
            title: 'Preferências',
            children: [
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Idioma',
                subtitle: 'Português (BR)',
              ),
              _buildSettingsTile(
                icon: Icons.location_on,
                title: 'Localização',
                subtitle: 'Sempre ativo',
              ),
              _buildSettingsTile(
                icon: Icons.volume_up,
                title: 'Notificações de Som',
                subtitle: notificationsEnabled ? 'Ativado' : 'Desativado',
                trailing: Switch(
                  value: notificationsEnabled,
                  activeThumbColor: const Color(0xFF1B7E3D),
                  activeTrackColor: const Color(0xFF1B7E3D).withValues(alpha: 0.5),
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
              ),
              _buildSettingsTile(
                icon: Icons.notifications_active,
                title: 'Testar notificação local',
                subtitle: 'Mostra um aviso offline de teste',
                onTap: () async {
                  await NotificationService.instance.showTestNotification();
                },
              ),
            ],
          ),
          _buildSettingsSection(
            title: 'Dados e Privacidade',
            children: [
              _buildSettingsTile(
                icon: Icons.storage,
                title: 'Gerenciar Downloads',
                subtitle: '2.5 GB de mapas instalados',
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: 'Política de Privacidade',
              ),
              _buildSettingsTile(
                icon: Icons.description,
                title: 'Termos de Serviço',
              ),
            ],
          ),
          _buildSettingsSection(
            title: 'Sobre',
            children: [
              _buildSettingsTile(
                icon: Icons.info,
                title: 'Versão do App',
                subtitle: 'v1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B7E3D), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap ?? () {},
      dense: true,
    );
  }
}
