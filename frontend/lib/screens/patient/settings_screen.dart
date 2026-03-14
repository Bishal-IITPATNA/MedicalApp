import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _language = 'English';
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive notifications about appointments and updates'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _emailNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() => _emailNotifications = value);
            } : null,
            secondary: const Icon(Icons.email),
          ),
          SwitchListTile(
            title: const Text('SMS Notifications'),
            subtitle: const Text('Receive notifications via SMS'),
            value: _smsNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() => _smsNotifications = value);
            } : null,
            secondary: const Icon(Icons.sms),
          ),
          const Divider(),

          // Appearance Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dark mode coming soon!')),
              );
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            leading: const Icon(Icons.language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const Divider(),

          // Privacy & Security Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
              );
            },
          ),
          ListTile(
            title: const Text('Terms & Conditions'),
            leading: const Icon(Icons.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & conditions coming soon')),
              );
            },
          ),
          const Divider(),

          // About Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Help & Support'),
            leading: const Icon(Icons.help),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support contact: support@medicalapp.com')),
              );
            },
          ),
          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await _showLogoutConfirmation();
                if (confirm == true && mounted) {
                  await _authService.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Hindi'),
              value: 'Hindi',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hindi language coming soon!')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Spanish language coming soon!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon!'),
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
