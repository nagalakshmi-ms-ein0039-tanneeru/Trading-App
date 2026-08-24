import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/core/widgets/price_flash_container.dart';
import 'package:trading_app/data/models/holding.dart';
import 'package:trading_app/data/models/stock.dart';
import 'package:trading_app/features/holdings/bloc/holdings_cubit.dart';
import 'package:trading_app/features/markets/bloc/markets_cubit.dart';
import 'package:trading_app/features/trade/widgets/order_ticket_sheet.dart';

class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
      ),
      body: BlocBuilder<HoldingsCubit, HoldingsState>(
        builder: (context, state) {
          if (state.holdings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No holdings found',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buy stocks from the Watchlist or Markets tab to build your portfolio.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final totalPAndLColor = state.totalPAndL >= 0 ? AppColors.upGreen : AppColors.downRed;
          final totalPAndLSign = state.totalPAndL >= 0 ? '+' : '';

          return Column(
            children: [
              // Glassmorphic Portfolio Summary Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invested Value',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(state.totalInvested),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Current Value',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(state.totalCurrent),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.divider, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total P&L',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$totalPAndLSign${currencyFormatter.format(state.totalPAndL)}',
                              style: TextStyle(
                                color: totalPAndLColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: totalPAndLColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$totalPAndLSign${state.totalPAndLPercentage.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: totalPAndLColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sorting Options Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Sort by:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    _buildSortChip(context, 'PL', 'P&L', state.sortBy, state.sortDescending),
                    const SizedBox(width: 6),
                    _buildSortChip(context, 'SYMBOL', 'Symbol', state.sortBy, state.sortDescending),
                    const SizedBox(width: 6),
                    _buildSortChip(context, 'VALUE', 'Value', state.sortBy, state.sortDescending),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Holdings list headers
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QTY / AVG COST',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'LTP / VALUE',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'NET P&L',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),

              // Holdings List
              Expanded(
                child: ListView.builder(
                  itemCount: state.holdings.length,
                  itemBuilder: (context, index) {
                    final holding = state.holdings[index];
                    return HoldingRowItem(
                      key: ValueKey('holding_${holding.symbol}'),
                      holding: holding,
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

  Widget _buildSortChip(
    BuildContext context,
    String key,
    String label,
    String activeSortBy,
    bool descending,
  ) {
    final isActive = activeSortBy == key;
    final arrow = descending ? ' ↓' : ' ↑';

    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: RawChip(
        label: Text('$label${isActive ? arrow : ''}'),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.black : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        selected: isActive,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.black,
        showCheckmark: false,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.border,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () {
          context.read<HoldingsCubit>().updateSort(key);
        },
      ),
    );
  }
}

class HoldingRowItem extends StatelessWidget {
  final Holding holding;

  const HoldingRowItem({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Subscribe to only the current price changes of this symbol to avoid excessive rebuilds
    final livePrice = context.select<MarketsCubit, double?>(
      (cubit) => cubit.state.stocks[holding.symbol]?.currentPrice,
    );

    final currentPrice = livePrice ?? holding.lastTradePrice;
    final currentValue = holding.quantity * currentPrice;
    final investedValue = holding.quantity * holding.averagePrice;
    final pAndL = currentValue - investedValue;
    final pAndLPercentage = investedValue == 0 ? 0.0 : (pAndL / investedValue) * 100;

    final isPositive = pAndL >= 0;
    final plColor = isPositive ? AppColors.upGreen : AppColors.downRed;
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
            // Find current stock object in MarketsCubit state
            final marketsCubit = context.read<MarketsCubit>();
            final stock = marketsCubit.state.stocks[holding.symbol] ??
                Stock(
                  symbol: holding.symbol,
                  currentPrice: currentPrice,
                  yesterdayClose: currentPrice,
                  lastUpdated: DateTime.now(),
                );

            OrderTicketSheet.show(context, stock: stock);
          },
          child: PriceFlashContainer(
            price: currentPrice,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Symbol + Qty / Avg Cost
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${holding.quantity} Shares @ ${currencyFormatter.format(holding.averagePrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // LTP / Value
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currencyFormatter.format(currentPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Val: ${currencyFormatter.format(currentValue)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Net P&L
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign${currencyFormatter.format(pAndL)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: plColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sign${pAndLPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: plColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
