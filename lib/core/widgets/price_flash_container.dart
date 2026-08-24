import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trading_app/core/constants/app_colors.dart';

class PriceFlashContainer extends StatefulWidget {
  final double price;
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const PriceFlashContainer({
    super.key,
    required this.price,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  State<PriceFlashContainer> createState() => _PriceFlashContainerState();
}

class _PriceFlashContainerState extends State<PriceFlashContainer> {
  Color _flashColor = Colors.transparent;
  Timer? _timer;
  late double _lastPrice;

  @override
  void initState() {
    super.initState();
    _lastPrice = widget.price;
  }

  @override
  void didUpdateWidget(covariant PriceFlashContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      final direction = widget.price > _lastPrice;
      _lastPrice = widget.price;

      _timer?.cancel();
      setState(() {
        _flashColor = direction
            ? AppColors.upGreen.withOpacity(0.15)
            : AppColors.downRed.withOpacity(0.15);
      });

      _timer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _flashColor = Colors.transparent;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _flashColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: widget.child,
    );
  }
}
