import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyetomobile2/viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Scaffold(
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
        body: Consumer<SettingsViewModel>(
          builder: (context, viewModel, child) {
            return ListView(
              children: [
                _buildSettingsSection(
                  title: 'Preferências',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Idioma',
                      subtitle: viewModel.selectedLanguage,
                    ),
                    _buildSettingsTile(
                      icon: Icons.location_on,
                      title: 'Localização',
                      subtitle: viewModel.locationSetting,
                    ),
                    _buildSettingsTile(
                      icon: Icons.volume_up,
                      title: 'Notificações de Som',
                      subtitle: viewModel.notificationsEnabled ? 'Ativado' : 'Desativado',
                      trailing: Switch(
                        value: viewModel.notificationsEnabled,
                        activeThumbColor: const Color(0xFF1B7E3D),
                        activeTrackColor: const Color(0xFF1B7E3D).withValues(alpha: 0.5),
                        onChanged: (value) => viewModel.toggleNotifications(value),
                      ),
                    ),
                  ],
                ),
                _buildSettingsSection(
                  title: 'Dados e Privacidade',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.storage,
                      title: 'Gerenciar Downloads',
                      subtitle: '${viewModel.mapStorageSize} de mapas instalados',
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
                      subtitle: viewModel.appVersion,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
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
      onTap: () {},
      dense: true,
    );
  }
}
