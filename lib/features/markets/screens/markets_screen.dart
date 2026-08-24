import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/core/widgets/price_flash_container.dart';
import 'package:trading_app/core/widgets/sparkline_mini_graph.dart';
import 'package:trading_app/data/models/stock.dart';
import 'package:trading_app/features/markets/bloc/markets_cubit.dart';
import 'package:trading_app/features/trade/widgets/order_ticket_sheet.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market Feed'),
      ),
      body: BlocBuilder<MarketsCubit, MarketsState>(
        builder: (context, state) {
          final symbols = state.stocks.keys.toList();

          return Column(
            children: [
              // Controller Card for Stress Testing
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stress Test Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Simulate 60+ updates per second',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: state.isStressTesting,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            context.read<MarketsCubit>().setStressTest(value);
                          },
                        ),
                      ],
                    ),
                    if (!state.isStressTesting) ...[
                      const Divider(color: AppColors.divider, height: 24),
                      const Text(
                        'Adjust Tick Frequency (ms)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Custom slider to adjust interval from 50ms to 2000ms
                      _CustomTickRateSlider(),
                    ]
                  ],
                ),
              ),
              // Header row
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STOCK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'TREND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'LTP / CHANGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
              // List of Stocks
              Expanded(
                child: ListView.builder(
                  itemCount: symbols.length,
                  itemBuilder: (context, index) {
                    return MarketStockRow(
                      symbol: symbols[index],
                      key: ValueKey('market_row_${symbols[index]}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomTickRateSlider extends StatefulWidget {
  @override
  State<_CustomTickRateSlider> createState() => _CustomTickRateSliderState();
}

class _CustomTickRateSliderState extends State<_CustomTickRateSlider> {
  double _currentValue = 500;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _currentValue,
              min: 50,
              max: 2000,
              divisions: 39, // steps of 50ms
              label: '${_currentValue.round()}ms',
              onChanged: (val) {
                setState(() {
                  _currentValue = val;
                });
              },
              onChangeEnd: (val) {
                context.read<MarketsCubit>().setCustomIntervalMs(val.round());
              },
            ),
          ),
        ),
        SizedBox(
          width: 55,
          child: Text(
            '${_currentValue.round()}ms',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: Alignment.centerRight.x == 1.0 ? TextAlign.right : TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class MarketStockRow extends StatelessWidget {
  final String symbol;

  const MarketStockRow({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    // Rebuild only this specific stock widget when its price changes
    final stock = context.select<MarketsCubit, Stock?>((cubit) => cubit.state.stocks[symbol]);

    if (stock == null) return const SizedBox.shrink();

    final isPositive = stock.change >= 0;
    final color = isPositive ? AppColors.upGreen : AppColors.downRed;
    final sign = isPositive ? '+' : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            OrderTicketSheet.show(context, stock: stock);
          },
          child: PriceFlashContainer(
            price: stock.currentPrice,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Symbol info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'NSE',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sparkline
                SparklineMiniGraph(
                  data: stock.priceHistory,
                  color: color,
                ),
                const SizedBox(width: 30),
                // Price information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${stock.currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
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
          ),
        ),
      ),
    );
  }
}
