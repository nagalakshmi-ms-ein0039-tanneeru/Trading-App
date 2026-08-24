import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/core/services/storage_service.dart';
import 'package:trading_app/features/holdings/bloc/holdings_cubit.dart';
import 'package:trading_app/features/trade/bloc/trade_cubit.dart';

void main() {
  setUp(() async {
    // Mock SharedPreferences values for testing
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  group('Trading App Business Logic Tests', () {
    test('Initial Wallet Balance should be 10 Lakhs (1,000,000)', () {
      final storage = StorageService();
      expect(storage.getWalletBalance(), 1000000.00);
    });

    test('Holdings should calculate average cost and totals correctly', () async {
      final holdingsCubit = HoldingsCubit();
      
      // Execute a Buy Order for RELIANCE: 10 shares @ ₹2500
      await holdingsCubit.executeBuyOrder('RELIANCE', 10, 2500.00);
      expect(holdingsCubit.state.holdings.length, 1);
      expect(holdingsCubit.state.holdings[0].symbol, 'RELIANCE');
      expect(holdingsCubit.state.holdings[0].quantity, 10);
      expect(holdingsCubit.state.holdings[0].averagePrice, 2500.00);
      expect(holdingsCubit.state.totalInvested, 25000.00);

      // Execute another Buy Order for RELIANCE: 10 shares @ ₹2600
      // New average should be: (10 * 2500 + 10 * 2600) / 20 = 2550
      await holdingsCubit.executeBuyOrder('RELIANCE', 10, 2600.00);
      expect(holdingsCubit.state.holdings[0].quantity, 20);
      expect(holdingsCubit.state.holdings[0].averagePrice, 2550.00);
      expect(holdingsCubit.state.totalInvested, 51000.00);

      // Sell part of holdings: 5 shares @ ₹2700
      await holdingsCubit.executeSellOrder('RELIANCE', 5, 2700.00);
      expect(holdingsCubit.state.holdings[0].quantity, 15);
      expect(holdingsCubit.state.holdings[0].averagePrice, 2550.00); // Selling doesn't change cost basis
      
      // Sell all remaining: 15 shares
      await holdingsCubit.executeSellOrder('RELIANCE', 15, 2700.00);
      expect(holdingsCubit.state.holdings.isEmpty, true);
    });

    test('TradeCubit should block orders exceeding wallet balance', () async {
      final holdingsCubit = HoldingsCubit();
      final tradeCubit = TradeCubit(holdingsCubit: holdingsCubit);

      // Buy 500 shares of TCS @ ₹3500 = ₹1,750,000 (Exceeds 1,000,000 balance)
      await tradeCubit.submitOrder(
        symbol: 'TCS',
        side: 'BUY',
        quantity: 500,
        ltp: 3500.00,
      );

      expect(tradeCubit.state.errorMessage != null, true);
      expect(tradeCubit.state.errorMessage!.contains('Insufficient balance'), true);
      expect(tradeCubit.state.walletBalance, 1000000.00); // Balance unchanged
    });

    test('TradeCubit should block sell orders if shares not owned', () async {
      final holdingsCubit = HoldingsCubit();
      final tradeCubit = TradeCubit(holdingsCubit: holdingsCubit);

      // Try selling INFY shares without owning any
      await tradeCubit.submitOrder(
        symbol: 'INFY',
        side: 'SELL',
        quantity: 10,
        ltp: 1400.00,
      );

      expect(tradeCubit.state.errorMessage != null, true);
      expect(tradeCubit.state.errorMessage!.contains('Insufficient holdings'), true);
    });

    test('TradeCubit should execute valid orders successfully', () async {
      final holdingsCubit = HoldingsCubit();
      final tradeCubit = TradeCubit(holdingsCubit: holdingsCubit);

      // Buy 10 shares of INFY @ ₹1400 = ₹14,000
      await tradeCubit.submitOrder(
        symbol: 'INFY',
        side: 'BUY',
        quantity: 10,
        ltp: 1400.00,
      );

      expect(tradeCubit.state.errorMessage, null);
      expect(tradeCubit.state.walletBalance, 986000.00); // 1000000 - 14000
      expect(tradeCubit.state.orderHistory.length, 1);
      expect(tradeCubit.state.orderHistory[0].symbol, 'INFY');
      expect(tradeCubit.state.orderHistory[0].side, 'BUY');

      // Check holdings updated
      expect(holdingsCubit.state.holdings.length, 1);
      expect(holdingsCubit.state.holdings[0].symbol, 'INFY');
      expect(holdingsCubit.state.holdings[0].quantity, 10);
    });
  });
}
