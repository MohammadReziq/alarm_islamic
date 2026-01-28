import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';
import '../controllers/settings_controller.dart';
import '../core/app_theme.dart';
import '../screens/settings/settings_screen.dart';

/// App Drawer - Side menu with settings, social links, and contact options
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          _buildDrawerHeader(context, settingsController),

          // Settings
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: settingsController.tr('settings'),
            onTap: () {
              Get.back();
              Get.to(() => const SettingsScreen());
            },
          ),

          const Divider(),

          // Social Media Section
          _buildSectionHeader(context, settingsController.tr('social_media')),
          _buildSocialLink(context, 'Facebook', Icons.facebook, AppConfig.facebook),
          _buildSocialLink(context, 'Instagram', Icons.camera_alt, AppConfig.instagram),
          _buildSocialLink(context, 'Twitter', Icons.alternate_email, AppConfig.twitter),

          const Divider(),

          // Contact Section
          _buildMenuItem(
            context,
            icon: Icons.email,
            title: settingsController.tr('contact_us'),
            onTap: () => _sendEmail(AppConfig.supportEmail, settingsController.tr('email_subject_contact')),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bug_report,
            title: settingsController.tr('report_bug'),
            onTap: () => _sendEmail(AppConfig.bugReportEmail, settingsController.tr('email_subject_bug')),
          ),
          _buildMenuItem(
            context,
            icon: Icons.lightbulb_outline,
            title: settingsController.tr('suggest_feature'),
            onTap: () => _sendEmail(AppConfig.featureSuggestionEmail, settingsController.tr('email_subject_feature')),
          ),

          const Divider(),

          // About & Website
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: settingsController.tr('about'),
            onTap: () => _showAboutDialog(context, settingsController),
          ),
          _buildMenuItem(
            context,
            icon: Icons.public,
            title: settingsController.tr('website'),
            onTap: () => _launchURL(AppConfig.website),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, SettingsController controller) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: AppTheme.goldGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
                controller.tr('app_name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              )),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  '${controller.tr('version')} ${snapshot.data!.version}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildSocialLink(
    BuildContext context,
    String name,
    IconData icon,
    String url,
  ) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(name),
      dense: true,
      onTap: () => _launchURL(url),
    );
  }

  // Helper methods
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAboutDialog(BuildContext context, SettingsController controller) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.goldGradient,
        ),
        child: const Icon(Icons.wb_sunny_outlined, color: Colors.white),
      ),
      children: [
        Text(controller.tr('app_tagline')),
        const SizedBox(height: 16),
        Text('${controller.tr('developed_by')} ${AppConfig.developerName}'),
      ],
    );
  }
}
