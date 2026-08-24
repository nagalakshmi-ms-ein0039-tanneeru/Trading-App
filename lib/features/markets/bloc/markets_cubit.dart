import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trading_app/core/services/market_feed_service.dart';
import 'package:trading_app/data/models/stock.dart';

class MarketsState extends Equatable {
  final Map<String, Stock> stocks;
  final String? lastTickedSymbol;
  final bool isStressTesting;

  const MarketsState({
    required this.stocks,
    this.lastTickedSymbol,
    this.isStressTesting = false,
  });

  MarketsState copyWith({
    Map<String, Stock>? stocks,
    String? lastTickedSymbol,
    bool? isStressTesting,
  }) {
    return MarketsState(
      stocks: stocks ?? this.stocks,
      lastTickedSymbol: lastTickedSymbol ?? this.lastTickedSymbol,
      isStressTesting: isStressTesting ?? this.isStressTesting,
    );
  }

  @override
  List<Object?> get props => [stocks, lastTickedSymbol, isStressTesting];
}

class MarketsCubit extends Cubit<MarketsState> {
  final MarketFeedService _feedService;
  StreamSubscription<Stock>? _subscription;

  MarketsCubit({MarketFeedService? feedService})
      : _feedService = feedService ?? MarketFeedService(),
        super(MarketsState(stocks: (feedService ?? MarketFeedService()).currentPrices)) {
    _subscribeToFeed();
  }

  void _subscribeToFeed() {
    _subscription?.cancel();
    _subscription = _feedService.priceTicks.listen((stock) {
      final updatedStocks = Map<String, Stock>.from(state.stocks);
      updatedStocks[stock.symbol] = stock;
      emit(state.copyWith(
        stocks: updatedStocks,
        lastTickedSymbol: stock.symbol,
      ));
    });
  }

  void setStressTest(bool enable) {
    if (enable) {
      _feedService.setTickInterval(const Duration(milliseconds: 15)); // ~66 ticks/sec overall
    } else {
      _feedService.setTickInterval(const Duration(milliseconds: 500)); // 2 ticks/sec overall
    }
    emit(state.copyWith(isStressTesting: enable));
  }

  void setCustomIntervalMs(int ms) {
    _feedService.setTickInterval(Duration(milliseconds: ms));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
