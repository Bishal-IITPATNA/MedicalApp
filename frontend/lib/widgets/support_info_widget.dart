import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportInfoWidget extends StatelessWidget {
  final bool showAsCard;
  final bool showInFooter;
  
  const SupportInfoWidget({
    super.key,
    this.showAsCard = false,
    this.showInFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsCard) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSupportContent(context),
        ),
      );
    } else if (showInFooter) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: _buildSupportContent(context),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSupportContent(context),
      );
    }
  }

  Widget _buildSupportContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Need Help? Contact Support',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _launchEmail(),
              child: Text(
                'seevakcare@gmail.com',
                style: TextStyle(
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 16, color: Colors.green[700]),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _launchPhone(),
              child: Text(
                '+91 9883258362',
                style: TextStyle(
                  color: Colors.green[700],
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'seevakcare@gmail.com',
      query: 'subject=Support Request - SeevakCare App',
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+919883258362',
    );
    
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }
}
