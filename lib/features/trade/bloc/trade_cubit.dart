import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trading_app/core/services/storage_service.dart';
import 'package:trading_app/data/models/holding.dart';
import 'package:trading_app/data/models/order.dart';
import 'package:trading_app/features/holdings/bloc/holdings_cubit.dart';

class TradeState extends Equatable {
  final double walletBalance;
  final List<Order> orderHistory;
  final bool isSubmitting;
  final String? errorMessage;
  final Order? lastPlacedOrder;

  const TradeState({
    required this.walletBalance,
    required this.orderHistory,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastPlacedOrder,
  });

  TradeState copyWith({
    double? walletBalance,
    List<Order>? orderHistory,
    bool? isSubmitting,
    String? errorMessage,
    Order? lastPlacedOrder,
  }) {
    return TradeState(
      walletBalance: walletBalance ?? this.walletBalance,
      orderHistory: orderHistory ?? this.orderHistory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage, // We pass null to clear it
      lastPlacedOrder: lastPlacedOrder,
    );
  }

  @override
  List<Object?> get props => [
        walletBalance,
        orderHistory,
        isSubmitting,
        errorMessage,
        lastPlacedOrder,
      ];
}

class TradeCubit extends Cubit<TradeState> {
  final StorageService _storageService;
  final HoldingsCubit _holdingsCubit;

  TradeCubit({
    required HoldingsCubit holdingsCubit,
    StorageService? storageService,
  })  : _storageService = storageService ?? StorageService(),
        _holdingsCubit = holdingsCubit,
        super(const TradeState(walletBalance: 0.0, orderHistory: [])) {
    loadTradeData();
  }

  void loadTradeData() {
    final balance = _storageService.getWalletBalance();
    final orders = _storageService.getOrders();
    emit(TradeState(walletBalance: balance, orderHistory: orders));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void resetOrderConfirmation() {
    emit(TradeState(
      walletBalance: state.walletBalance,
      orderHistory: state.orderHistory,
      isSubmitting: false,
      errorMessage: null,
      lastPlacedOrder: null,
    ));
  }

  Future<void> submitOrder({
    required String symbol,
    required String side,
    required int quantity,
    required double ltp,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    if (quantity <= 0) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Quantity must be greater than zero.',
      ));
      return;
    }

    final double orderValue = double.parse((quantity * ltp).toStringAsFixed(2));

    if (side == 'BUY') {
      if (orderValue > state.walletBalance) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage:
              'Insufficient balance. Required: ₹${orderValue.toStringAsFixed(2)}, Available: ₹${state.walletBalance.toStringAsFixed(2)}',
        ));
        return;
      }

      // Execute buy order
      final newBalance = double.parse((state.walletBalance - orderValue).toStringAsFixed(2));
      await _storageService.saveWalletBalance(newBalance);

      // Trigger HoldingsCubit update
      await _holdingsCubit.executeBuyOrder(symbol, quantity, ltp);

      final order = Order(
        id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: ltp,
        timestamp: DateTime.now(),
      );

      final updatedOrders = List<Order>.from(state.orderHistory)..insert(0, order);
      await _storageService.saveOrders(updatedOrders);

      emit(state.copyWith(
        walletBalance: newBalance,
        orderHistory: updatedOrders,
        isSubmitting: false,
        lastPlacedOrder: order,
      ));
    } else if (side == 'SELL') {
      // Find holding to check quantity
      final holdings = _holdingsCubit.state.holdings;
      final holdingIndex = holdings.indexWhere((h) => h.symbol == symbol);
      final heldQty = holdingIndex != -1 ? holdings[holdingIndex].quantity : 0;

      if (heldQty < quantity) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: 'Insufficient holdings. You only own $heldQty shares of $symbol.',
        ));
        return;
      }

      // Execute sell order
      final newBalance = double.parse((state.walletBalance + orderValue).toStringAsFixed(2));
      await _storageService.saveWalletBalance(newBalance);

      // Trigger HoldingsCubit update
      await _holdingsCubit.executeSellOrder(symbol, quantity, ltp);

      final order = Order(
        id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: ltp,
        timestamp: DateTime.now(),
      );

      final updatedOrders = List<Order>.from(state.orderHistory)..insert(0, order);
      await _storageService.saveOrders(updatedOrders);

      emit(state.copyWith(
        walletBalance: newBalance,
        orderHistory: updatedOrders,
        isSubmitting: false,
        lastPlacedOrder: order,
      ));
    }
  }

  Future<void> resetWallet() async {
    const double initial = 1000000.00;
    await _storageService.saveWalletBalance(initial);
    await _storageService.saveOrders([]);
    // Clear holdings as well
    final emptyHoldings = <Holding>[];
    await _storageService.saveHoldings(emptyHoldings);
    _holdingsCubit.loadHoldings();

    emit(const TradeState(
      walletBalance: initial,
      orderHistory: [],
      isSubmitting: false,
      errorMessage: null,
      lastPlacedOrder: null,
    ));
  }
}
