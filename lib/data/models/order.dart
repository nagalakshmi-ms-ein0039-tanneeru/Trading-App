import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String symbol;
  final String side; // 'BUY' or 'SELL'
  final int quantity;
  final double price;
  final DateTime timestamp;

  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side,
      'quantity': quantity,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, symbol, side, quantity, price, timestamp];
}
