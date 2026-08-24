import 'package:equatable/equatable.dart';

class Holding extends Equatable {
  final String symbol;
  final int quantity;
  final double averagePrice;
  final double lastTradePrice;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
    required this.lastTradePrice,
  });

  double get currentValue => quantity * lastTradePrice;
  double get investedValue => quantity * averagePrice;
  double get pAndL => currentValue - investedValue;
  double get pAndLPercentage =>
      investedValue == 0 ? 0.0 : (pAndL / investedValue) * 100.0;

  Holding copyWith({
    String? symbol,
    int? quantity,
    double? averagePrice,
    double? lastTradePrice,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      lastTradePrice: lastTradePrice ?? this.lastTradePrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'lastTradePrice': lastTradePrice,
    };
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      averagePrice: (json['averagePrice'] as num).toDouble(),
      lastTradePrice: (json['lastTradePrice'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [symbol, quantity, averagePrice, lastTradePrice];
}
