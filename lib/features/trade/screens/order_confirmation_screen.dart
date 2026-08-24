import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/data/models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final orderValue = order.quantity * order.price;
    final isBuy = order.side == 'BUY';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Animation / Icon Container
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: (isBuy ? AppColors.upGreen : AppColors.downRed).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isBuy ? AppColors.upGreen : AppColors.downRed,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: isBuy ? AppColors.upGreen : AppColors.downRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Executed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your simulated order was successfully executed at market.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Transaction Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Instrument', order.symbol, isBold: true),
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      'Action',
                      order.side,
                      valueColor: isBuy ? AppColors.upGreen : AppColors.downRed,
                      isBold: true,
                    ),
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow('Quantity', '${order.quantity} shares'),
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow('Execution Price', currencyFormatter.format(order.price)),
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      'Total Value',
                      currencyFormatter.format(orderValue),
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close Confirmation Screen
                  },
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
