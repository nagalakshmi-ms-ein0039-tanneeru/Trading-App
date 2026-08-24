import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/data/models/stock.dart';
import 'package:trading_app/features/holdings/bloc/holdings_cubit.dart';
import 'package:trading_app/features/markets/bloc/markets_cubit.dart';
import 'package:trading_app/features/trade/bloc/trade_cubit.dart';
import 'package:trading_app/features/trade/screens/order_confirmation_screen.dart';

class OrderTicketSheet extends StatefulWidget {
  final Stock initialStock;

  const OrderTicketSheet({super.key, required this.initialStock});

  static void show(BuildContext context, {required Stock stock}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: OrderTicketSheet(initialStock: stock),
        );
      },
    );
  }

  @override
  State<OrderTicketSheet> createState() => _OrderTicketSheetState();
}

class _OrderTicketSheetState extends State<OrderTicketSheet> {
  late bool _isBuy; // true for BUY, false for SELL
  final _qtyController = TextEditingController(text: '1');
  int _quantity = 1;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _isBuy = true;
    _qtyController.addListener(_onQtyChanged);
  }

  @override
  void dispose() {
    _qtyController.removeListener(_onQtyChanged);
    _qtyController.dispose();
    super.dispose();
  }

  void _onQtyChanged() {
    final text = _qtyController.text;
    if (text.isEmpty) {
      setState(() {
        _quantity = 0;
        _validationError = 'Quantity cannot be empty.';
      });
      return;
    }

    final val = int.tryParse(text);
    if (val == null || val <= 0) {
      setState(() {
        _quantity = 0;
        _validationError = 'Enter a valid positive whole number.';
      });
    } else {
      setState(() {
        _quantity = val;
        _validationError = null;
      });
    }
  }

  void _incrementQty(int delta) {
    final current = int.tryParse(_qtyController.text) ?? 0;
    final next = current + delta;
    if (next >= 1) {
      _qtyController.text = next.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return BlocListener<TradeCubit, TradeState>(
      listener: (context, tradeState) {
        if (tradeState.errorMessage != null) {
          setState(() {
            _validationError = tradeState.errorMessage;
          });
          context.read<TradeCubit>().clearError();
        }

        if (tradeState.lastPlacedOrder != null) {
          final order = tradeState.lastPlacedOrder!;
          // Reset confirmation and close bottom sheet
          context.read<TradeCubit>().resetOrderConfirmation();
          Navigator.pop(context);

          // Navigate to confirmation page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(order: order),
            ),
          );
        }
      },
      child: BlocBuilder<MarketsCubit, MarketsState>(
        builder: (context, marketsState) {
          // Keep LTP fresh in real time
          final stock = marketsState.stocks[widget.initialStock.symbol] ?? widget.initialStock;
          final double ltp = stock.currentPrice;
          final double orderValue = double.parse((_quantity * ltp).toStringAsFixed(2));
          final isPositive = stock.change >= 0;
          final stockColor = isPositive ? AppColors.upGreen : AppColors.downRed;
          final sign = isPositive ? '+' : '';

          return BlocBuilder<TradeCubit, TradeState>(
            builder: (context, tradeState) {
              final double balance = tradeState.walletBalance;

              // Look up current holding size
              final holdings = context.watch<HoldingsCubit>().state.holdings;
              final holdingIndex = holdings.indexWhere((h) => h.symbol == stock.symbol);
              final int heldQty = holdingIndex != -1 ? holdings[holdingIndex].quantity : 0;

              // Perform real-time validation checks for display
              String? activeError = _validationError;
              if (activeError == null) {
                if (_isBuy && orderValue > balance) {
                  activeError =
                      'Insufficient funds. Required: ${currencyFormatter.format(orderValue)}, Available: ${currencyFormatter.format(balance)}';
                } else if (!_isBuy && _quantity > heldQty) {
                  activeError = 'Insufficient shares. You only own $heldQty shares of ${stock.symbol}.';
                }
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.symbol,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'NSE • Market Order',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(ltp),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: stockColor,
                              ),
                            ),
                            Text(
                              '$sign${stock.change.toStringAsFixed(2)} ($sign${stock.changePercentage.toStringAsFixed(2)}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Segmented Side Switcher (BUY/SELL)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBuy = true;
                                });
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _isBuy ? AppColors.upGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'BUY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isBuy ? Colors.black : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBuy = false;
                                });
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: !_isBuy ? AppColors.downRed : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'SELL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: !_isBuy ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quantity Input & Balance Check Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity input box
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUANTITY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _incrementQty(-1),
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    color: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _qtyController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _incrementQty(1),
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Funds indicator / Positions info
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'AVAILABLE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isBuy
                                    ? currencyFormatter.format(balance)
                                    : '$heldQty Shares',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _isBuy ? 'Wallet Margin' : 'Held Quantity',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order Price Value & Summary Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Approx. Order Value',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(orderValue),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message (If any)
                    if (activeError != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.downRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeError,
                              style: const TextStyle(
                                color: AppColors.downRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Slide To Confirm Slider Widget
                    _SlideToConfirm(
                      isBuy: _isBuy,
                      disabled: activeError != null || _quantity <= 0,
                      onConfirm: () {
                        context.read<TradeCubit>().submitOrder(
                              symbol: stock.symbol,
                              side: _isBuy ? 'BUY' : 'SELL',
                              quantity: _quantity,
                              ltp: ltp,
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SlideToConfirm extends StatefulWidget {
  final bool isBuy;
  final bool disabled;
  final VoidCallback onConfirm;

  const _SlideToConfirm({
    required this.isBuy,
    required this.disabled,
    required this.onConfirm,
  });

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm> {
  double _dragOffset = 0.0;
  static const double _buttonHeight = 56.0;
  static const double _thumbWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isBuy ? AppColors.upGreen : AppColors.downRed;
    final String actionText = widget.isBuy ? 'SLIDE TO BUY' : 'SLIDE TO SELL';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDragDistance = constraints.maxWidth - _thumbWidth;

        return Opacity(
          opacity: widget.disabled ? 0.5 : 1.0,
          child: Container(
            height: _buttonHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Text Hint
                Positioned(
                  child: Center(
                    child: Text(
                      actionText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: themeColor.withOpacity(0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                // Sliding thumb and active colored track
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active track filling the background
                      AnimatedContainer(
                        duration: Duration.zero,
                        width: _dragOffset,
                        height: _buttonHeight,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(28),
                          ),
                        ),
                      ),
                      // Drag handle
                      GestureDetector(
                        onHorizontalDragUpdate: widget.disabled
                            ? null
                            : (details) {
                                setState(() {
                                  _dragOffset += details.primaryDelta!;
                                  if (_dragOffset < 0) _dragOffset = 0.0;
                                  if (_dragOffset > maxDragDistance) {
                                    _dragOffset = maxDragDistance;
                                  }
                                });
                              },
                        onHorizontalDragEnd: widget.disabled
                            ? null
                            : (details) {
                                if (_dragOffset >= maxDragDistance * 0.95) {
                                  // snap to end and trigger action
                                  setState(() {
                                    _dragOffset = maxDragDistance;
                                  });
                                  widget.onConfirm();
                                  // Bounce thumb back after brief moment in case of error/sheet not popping immediately
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) {
                                      setState(() {
                                        _dragOffset = 0.0;
                                      });
                                    }
                                  });
                                } else {
                                  // slide back to start
                                  setState(() {
                                    _dragOffset = 0.0;
                                  });
                                }
                              },
                        child: Container(
                          width: _thumbWidth,
                          height: _buttonHeight,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.double_arrow_rounded,
                            color: widget.isBuy ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
