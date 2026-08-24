import 'package:equatable/equatable.dart';

class Stock extends Equatable {
  final String symbol;
  final double currentPrice;
  final double yesterdayClose;
  final List<double> priceHistory;
  final DateTime lastUpdated;

  const Stock({
    required this.symbol,
    required this.currentPrice,
    required this.yesterdayClose,
    this.priceHistory = const [],
    required this.lastUpdated,
  });

  double get change => currentPrice - yesterdayClose;
  double get changePercentage =>
      yesterdayClose == 0 ? 0.0 : (change / yesterdayClose) * 100.0;

  Stock copyWith({
    String? symbol,
    double? currentPrice,
    double? yesterdayClose,
    List<double>? priceHistory,
    DateTime? lastUpdated,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      yesterdayClose: yesterdayClose ?? this.yesterdayClose,
      priceHistory: priceHistory ?? this.priceHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'currentPrice': currentPrice,
      'yesterdayClose': yesterdayClose,
      'priceHistory': priceHistory,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      yesterdayClose: (json['yesterdayClose'] as num).toDouble(),
      priceHistory: (json['priceHistory'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        currentPrice,
        yesterdayClose,
        priceHistory,
        lastUpdated,
      ];
}
