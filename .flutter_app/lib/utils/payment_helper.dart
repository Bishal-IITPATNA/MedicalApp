import 'package:flutter/material.dart';

/// Helper class for payment-related functionality
class PaymentHelper {
  /// Format amount to display with rupee symbol
  static String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get payment status color
  static Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'initiated':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get payment status icon
  static IconData getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'initiated':
        return Icons.payment;
      default:
        return Icons.help;
    }
  }

  /// Get payment status display text
  static String getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Paid';
      case 'initiated':
        return 'Processing';
      case 'pending':
        return 'Awaiting Payment';
      case 'failed':
        return 'Payment Failed';
      default:
        return status;
    }
  }

  /// Build payment status widget
  static Widget buildPaymentStatusWidget(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getPaymentStatusColor(status).withOpacity(0.2),
        border: Border.all(color: getPaymentStatusColor(status)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getPaymentStatusIcon(status),
            size: 16,
            color: getPaymentStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            getPaymentStatusText(status),
            style: TextStyle(
              color: getPaymentStatusColor(status),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Show payment error snackbar
  static void showPaymentError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show payment success snackbar
  static void showPaymentSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build payment summary card
  static Widget buildPaymentSummaryCard({
    required String title,
    required String subtitle,
    required double amount,
    required String status,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          getPaymentStatusIcon(status),
          color: getPaymentStatusColor(status),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatAmount(amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            buildPaymentStatusWidget(status),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
