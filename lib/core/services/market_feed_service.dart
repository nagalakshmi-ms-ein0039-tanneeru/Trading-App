import 'dart:async';
import 'dart:math';
import 'package:trading_app/data/models/stock.dart';

class MarketFeedService {
  static final MarketFeedService _instance = MarketFeedService._internal();
  factory MarketFeedService() => _instance;
  MarketFeedService._internal() {
    _initializePrices();
    startFeed();
  }

  final _random = Random();
  final StreamController<Stock> _controller = StreamController<Stock>.broadcast();
  Timer? _timer;

  // Default tick interval: 500ms
  Duration _tickInterval = const Duration(milliseconds: 500);

  final List<String> symbols = [
    'RELIANCE', 'TCS', 'INFY', 'HDFCBANK', 'ICICIBANK',
    'SBIN', 'ITC', 'LT', 'BHARTIARTL', 'AXISBANK'
  ];

  final Map<String, double> _basePrices = {
    'RELIANCE': 2450.00,
    'TCS': 3400.00,
    'INFY': 1420.00,
    'HDFCBANK': 1610.00,
    'ICICIBANK': 940.00,
    'SBIN': 570.00,
    'ITC': 435.00,
    'LT': 2350.00,
    'BHARTIARTL': 870.00,
    'AXISBANK': 960.00,
  };

  final Map<String, Stock> _currentPrices = {};

  Stream<Stock> get priceTicks => _controller.stream;

  Map<String, Stock> get currentPrices => Map.unmodifiable(_currentPrices);

  Duration get tickInterval => _tickInterval;

  void _initializePrices() {
    final now = DateTime.now();
    for (final symbol in symbols) {
      final base = _basePrices[symbol]!;
      _currentPrices[symbol] = Stock(
        symbol: symbol,
        currentPrice: base,
        yesterdayClose: base * (1 + (_random.nextDouble() * 0.04 - 0.02)), // +/- 2% close
        priceHistory: List.generate(15, (index) {
          return base * (1 + (_random.nextDouble() * 0.02 - 0.01));
        }),
        lastUpdated: now,
      );
    }
  }

  void startFeed() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (timer) {
      _tick();
    });
  }

  void stopFeed() {
    _timer?.cancel();
    _timer = null;
  }

  void setTickInterval(Duration interval) {
    if (_tickInterval == interval) return;
    _tickInterval = interval;
    if (_timer != null) {
      startFeed();
    }
  }

  void _tick() {
    // Pick a random stock to update
    final symbol = symbols[_random.nextInt(symbols.length)];
    final currentStock = _currentPrices[symbol]!;

    // Random walk movement: +/- 0.3% max
    final changePercent = (_random.nextDouble() * 0.006) - 0.003;
    final newPrice = currentStock.currentPrice * (1 + changePercent);

    // Keep price history size limited to 20
    final newHistory = List<double>.from(currentStock.priceHistory);
    newHistory.add(newPrice);
    if (newHistory.length > 20) {
      newHistory.removeAt(0);
    }

    final updatedStock = currentStock.copyWith(
      currentPrice: double.parse(newPrice.toStringAsFixed(2)),
      priceHistory: newHistory,
      lastUpdated: DateTime.now(),
    );

    _currentPrices[symbol] = updatedStock;
    _controller.add(updatedStock);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
