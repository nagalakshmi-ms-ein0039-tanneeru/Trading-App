import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/core/widgets/price_flash_container.dart';
import 'package:trading_app/core/widgets/sparkline_mini_graph.dart';
import 'package:trading_app/data/models/stock.dart';
import 'package:trading_app/data/models/watchlist.dart';
import 'package:trading_app/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:trading_app/features/markets/bloc/markets_cubit.dart';
import 'package:trading_app/features/trade/widgets/order_ticket_sheet.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  void _showCreateWatchlistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Watchlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter watchlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<WatchlistCubit>().createWatchlist(name);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameWatchlistDialog(BuildContext context, Watchlist watchlist) {
    final controller = TextEditingController(text: watchlist.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Watchlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<WatchlistCubit>().renameWatchlist(
                  watchlist.id,
                  name,
                );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Watchlist watchlist) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: Text('Are you sure you want to delete "${watchlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.downRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<WatchlistCubit>().deleteWatchlist(watchlist.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStockPicker(BuildContext context, Watchlist watchlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final marketsCubit = context.read<MarketsCubit>();
        final watchlistCubit = context.read<WatchlistCubit>();
        final allSymbols = marketsCubit.state.stocks.keys.toList();

        // Listen to the cubit so we always read the LATEST watchlist by id,
        // instead of the stale snapshot passed into this method.
        return BlocBuilder<WatchlistCubit, WatchlistState>(
          bloc: watchlistCubit,
          builder: (context, watchlistState) {
            final liveWatchlist = watchlistState.watchlists.firstWhere(
              (w) => w.id == watchlist.id,
              orElse: () => watchlist,
            );

            return FractionallySizedBox(
              heightFactor: 0.7,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      'Add/Remove Stocks to ${liveWatchlist.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allSymbols.length,
                        itemBuilder: (itemContext, index) {
                          final symbol = allSymbols[index];
                          final stock = marketsCubit.state.stocks[symbol]!;
                          final isAdded = liveWatchlist.stockSymbols.contains(
                            symbol,
                          );

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAdded
                                    ? AppColors.primary.withOpacity(0.5)
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'LTP: ₹${stock.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Checkbox(
                                value: isAdded,
                                activeColor: AppColors.primary,
                                checkColor: Colors.black,
                                onChanged: (value) {
                                  if (value == true) {
                                    watchlistCubit.addStockToWatchlist(
                                      liveWatchlist.id,
                                      symbol,
                                    );
                                  } else {
                                    watchlistCubit.removeStockFromWatchlist(
                                      liveWatchlist.id,
                                      symbol,
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, watchlistState) {
        final watchlists = watchlistState.watchlists;
        final selectedIndex = watchlistState.selectedWatchlistIndex;

        if (watchlists.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Watchlist'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showCreateWatchlistDialog(context),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.playlist_add_rounded,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No watchlists found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateWatchlistDialog(context),
                    child: const Text('Create Watchlist'),
                  ),
                ],
              ),
            ),
          );
        }

        final activeWatchlist = watchlistState.selectedWatchlist!;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedIndex,
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.primary,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    items: List.generate(watchlists.length, (idx) {
                      return DropdownMenuItem(
                        value: idx,
                        child: Text(watchlists[idx].name),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<WatchlistCubit>().selectWatchlist(val);
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Add Stock',
                onPressed: () => _showStockPicker(context, activeWatchlist),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (action) {
                  if (action == 'rename') {
                    _showRenameWatchlistDialog(context, activeWatchlist);
                  } else if (action == 'delete') {
                    _showDeleteConfirmDialog(context, activeWatchlist);
                  } else if (action == 'new') {
                    _showCreateWatchlistDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new',
                    child: Text('Create New Watchlist'),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename Current'),
                  ),
                  if (watchlists.length > 1)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Current',
                        style: TextStyle(color: AppColors.downRed),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: activeWatchlist.stockSymbols.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Watchlist "${activeWatchlist.name}" is empty',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Stocks'),
                        onPressed: () =>
                            _showStockPicker(context, activeWatchlist),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: activeWatchlist.stockSymbols.length,
                  onReorder: (oldIndex, newIndex) {
                    context.read<WatchlistCubit>().reorderStocks(
                      activeWatchlist.id,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final symbol = activeWatchlist.stockSymbols[index];
                    return Dismissible(
                      key: ValueKey('dismiss_${activeWatchlist.id}_$symbol'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        context.read<WatchlistCubit>().removeStockFromWatchlist(
                          activeWatchlist.id,
                          symbol,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$symbol removed from ${activeWatchlist.name}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      background: Container(
                        color: AppColors.downRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: WatchlistStockRow(
                          key: ValueKey('row_${activeWatchlist.id}_$symbol'),
                          symbol: symbol,
                          index: index,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class WatchlistStockRow extends StatelessWidget {
  final String symbol;
  final int index;

  const WatchlistStockRow({
    super.key,
    required this.symbol,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Select only this stock's state to minimize rebuilds to only the changing row
    final stock = context.select<MarketsCubit, Stock?>(
      (cubit) => cubit.state.stocks[symbol],
    );

    if (stock == null) {
      return const SizedBox.shrink();
    }

    final isPositive = stock.change >= 0;
    final color = isPositive ? AppColors.upGreen : AppColors.downRed;
    final sign = isPositive ? '+' : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            OrderTicketSheet.show(context, stock: stock);
          },
          child: PriceFlashContainer(
            price: stock.currentPrice,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // Reorder drag handle
                const Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                // Symbol Info
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
                // Sparkline Trend Mini Graph
                SparklineMiniGraph(data: stock.priceHistory, color: color),
                const SizedBox(width: 20),
                // Price & Percentage Change
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
