import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trading_app/core/services/storage_service.dart';
import 'package:trading_app/core/services/market_feed_service.dart';
import 'package:trading_app/data/models/holding.dart';
import 'package:trading_app/data/models/stock.dart';

class HoldingsState extends Equatable {
  final List<Holding> holdings;
  final double totalInvested;
  final double totalCurrent;
  final double totalPAndL;
  final double totalPAndLPercentage;
  final String sortBy; // 'PL' | 'SYMBOL' | 'VALUE'
  final bool sortDescending;

  const HoldingsState({
    required this.holdings,
    required this.totalInvested,
    required this.totalCurrent,
    required this.totalPAndL,
    required this.totalPAndLPercentage,
    this.sortBy = 'PL',
    this.sortDescending = true,
  });

  HoldingsState copyWith({
    List<Holding>? holdings,
    double? totalInvested,
    double? totalCurrent,
    double? totalPAndL,
    double? totalPAndLPercentage,
    String? sortBy,
    bool? sortDescending,
  }) {
    return HoldingsState(
      holdings: holdings ?? this.holdings,
      totalInvested: totalInvested ?? this.totalInvested,
      totalCurrent: totalCurrent ?? this.totalCurrent,
      totalPAndL: totalPAndL ?? this.totalPAndL,
      totalPAndLPercentage: totalPAndLPercentage ?? this.totalPAndLPercentage,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  @override
  List<Object?> get props => [
        holdings,
        totalInvested,
        totalCurrent,
        totalPAndL,
        totalPAndLPercentage,
        sortBy,
        sortDescending,
      ];
}

class HoldingsCubit extends Cubit<HoldingsState> {
  final StorageService _storageService;
  final MarketFeedService _feedService;
  StreamSubscription<Stock>? _subscription;

  HoldingsCubit({
    StorageService? storageService,
    MarketFeedService? feedService,
  })  : _storageService = storageService ?? StorageService(),
        _feedService = feedService ?? MarketFeedService(),
        super(const HoldingsState(
          holdings: [],
          totalInvested: 0,
          totalCurrent: 0,
          totalPAndL: 0,
          totalPAndLPercentage: 0,
        )) {
    loadHoldings();
    _subscribeToFeed();
  }

  void loadHoldings() {
    final list = _storageService.getHoldings();
    // Update LTP with the latest available price in memory on load
    final updatedList = list.map((h) {
      final currentPrice = _feedService.currentPrices[h.symbol]?.currentPrice ?? h.lastTradePrice;
      return h.copyWith(lastTradePrice: currentPrice);
    }).toList();

    _emitWithCalculations(updatedList, state.sortBy, state.sortDescending);
  }

  void _subscribeToFeed() {
    _subscription?.cancel();
    _subscription = _feedService.priceTicks.listen((stock) {
      final holdingIndex = state.holdings.indexWhere((h) => h.symbol == stock.symbol);
      if (holdingIndex != -1) {
        final updatedList = List<Holding>.from(state.holdings);
        updatedList[holdingIndex] = updatedList[holdingIndex].copyWith(
          lastTradePrice: stock.currentPrice,
        );
        _emitWithCalculations(updatedList, state.sortBy, state.sortDescending);
      }
    });
  }

  // Update holdings when order executes
  Future<void> executeBuyOrder(String symbol, int qty, double executionPrice) async {
    final list = _storageService.getHoldings();
    final index = list.indexWhere((h) => h.symbol == symbol);
    List<Holding> updatedList;

    if (index != -1) {
      final existing = list[index];
      final newQty = existing.quantity + qty;
      // Calculate new average price: (existing_qty * existing_avg + new_qty * execution_price) / new_qty
      final newAvg = ((existing.quantity * existing.averagePrice) + (qty * executionPrice)) / newQty;
      final updatedHolding = existing.copyWith(
        quantity: newQty,
        averagePrice: double.parse(newAvg.toStringAsFixed(2)),
        lastTradePrice: executionPrice,
      );
      updatedList = List<Holding>.from(list)..[index] = updatedHolding;
    } else {
      final newHolding = Holding(
        symbol: symbol,
        quantity: qty,
        averagePrice: executionPrice,
        lastTradePrice: executionPrice,
      );
      updatedList = List<Holding>.from(list)..add(newHolding);
    }

    await _storageService.saveHoldings(updatedList);
    _emitWithCalculations(updatedList, state.sortBy, state.sortDescending);
  }

  Future<void> executeSellOrder(String symbol, int qty, double executionPrice) async {
    final list = _storageService.getHoldings();
    final index = list.indexWhere((h) => h.symbol == symbol);
    if (index == -1) return;

    final existing = list[index];
    final newQty = existing.quantity - qty;
    List<Holding> updatedList;

    if (newQty <= 0) {
      updatedList = List<Holding>.from(list)..removeAt(index);
    } else {
      final updatedHolding = existing.copyWith(
        quantity: newQty,
        lastTradePrice: executionPrice,
      );
      updatedList = List<Holding>.from(list)..[index] = updatedHolding;
    }

    await _storageService.saveHoldings(updatedList);
    _emitWithCalculations(updatedList, state.sortBy, state.sortDescending);
  }

  void updateSort(String sortBy, {bool? descending}) {
    final newDescending = descending ?? (state.sortBy == sortBy ? !state.sortDescending : true);
    _emitWithCalculations(state.holdings, sortBy, newDescending);
  }

  void _emitWithCalculations(List<Holding> list, String sortBy, bool descending) {
    double invested = 0;
    double current = 0;

    for (final h in list) {
      invested += h.investedValue;
      current += h.currentValue;
    }

    final pAndL = current - invested;
    final pAndLPercent = invested == 0 ? 0.0 : (pAndL / invested) * 100.0;

    // Sort list
    final sortedList = List<Holding>.from(list);
    sortedList.sort((a, b) {
      int comparison;
      if (sortBy == 'SYMBOL') {
        comparison = a.symbol.compareTo(b.symbol);
      } else if (sortBy == 'VALUE') {
        comparison = a.currentValue.compareTo(b.currentValue);
      } else {
        // PL sorting (default)
        comparison = a.pAndL.compareTo(b.pAndL);
      }
      return descending ? -comparison : comparison;
    });

    emit(HoldingsState(
      holdings: sortedList,
      totalInvested: double.parse(invested.toStringAsFixed(2)),
      totalCurrent: double.parse(current.toStringAsFixed(2)),
      totalPAndL: double.parse(pAndL.toStringAsFixed(2)),
      totalPAndLPercentage: double.parse(pAndLPercent.toStringAsFixed(2)),
      sortBy: sortBy,
      sortDescending: descending,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
