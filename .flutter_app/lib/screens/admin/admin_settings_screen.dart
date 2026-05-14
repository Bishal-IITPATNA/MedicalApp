import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _emailNotifications = true;
  bool _orderAlerts = true;
  bool _systemAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                  },
                  secondary: const Icon(Icons.email),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Order Alerts'),
                  subtitle: const Text('Get notified about new orders'),
                  value: _orderAlerts,
                  onChanged: (value) {
                    setState(() => _orderAlerts = value);
                  },
                  secondary: const Icon(Icons.shopping_bag),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('System Alerts'),
                  subtitle: const Text('Critical system notifications'),
                  value: _systemAlerts,
                  onChanged: (value) {
                    setState(() => _systemAlerts = value);
                  },
                  secondary: const Icon(Icons.warning),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password change feature coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Two-Factor Authentication'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('2FA feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTermsAndConditions(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyPolicy(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              subtitle: const Text('Contact us for assistance'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email: seevakcare@gmail.com | Phone: +91 9771365160')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Last Updated: May 2026\n\n'
                'At SeevakCare, we are committed to protecting your privacy and ensuring secure administration of our platform.\n\n'
                '1. Information We Collect\n'
                'We collect information necessary to administer the platform, including:\n'
                '- Administrative access logs and activities\n'
                '- System performance and user data\n'
                '- Security and audit information\n\n'
                '2. How We Use Your Information\n'
                'Your information is used to:\n'
                '- Maintain platform security\n'
                '- Ensure regulatory compliance\n'
                '- Monitor system performance\n'
                '- Prevent fraud and abuse\n\n'
                '3. Data Security\n'
                'We implement enterprise-level security measures.\n\n'
                '4. Contact Us\n'
                'For privacy concerns:\n'
                'Email: seevakcare@gmail.com\n'
                'Phone: +91 9771365160',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Last Updated: May 2026\n\n'
                '1. Acceptance of Terms\n'
                'By using SeevakCare Admin Panel, you agree to these terms.\n\n'
                '2. Administrator Responsibilities\n'
                'Administrators agree to:\n'
                '- Maintain strict confidentiality\n'
                '- Use access for authorized purposes only\n'
                '- Report security incidents immediately\n'
                '- Comply with all applicable laws\n\n'
                '3. Platform Usage\n'
                'Administrators must:\n'
                '- Protect user data\n'
                '- Maintain system integrity\n'
                '- Follow best practices\n\n'
                '4. Liability\n'
                'SeevakCare is not liable for unauthorized access or misuse by admins.\n\n'
                '5. Support\n'
                'For questions:\n'
                'Email: seevakcare@gmail.com\n'
                'Phone: +91 9771365160',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
