import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:trading_app/data/models/watchlist.dart';
import 'package:trading_app/data/models/holding.dart';
import 'package:trading_app/data/models/order.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  static const String _keyWatchlists = 'watchlists';
  static const String _keyWalletBalance = 'wallet_balance';
  static const String _keyHoldings = 'holdings';
  static const String _keyOrders = 'orders';

  static const double _initialBalance = 1000000.00; // ₹1,000,000.00 starting balance

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Watchlists
  List<Watchlist> getWatchlists() {
    final String? data = _prefs.getString(_keyWatchlists);
    if (data == null) {
      // Return a default watchlist initially
      return [
        const Watchlist(
          id: 'watchlist_1',
          name: 'My Watchlist 1',
          stockSymbols: ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK'],
        ),
      ];
    }
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Watchlist.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWatchlists(List<Watchlist> watchlists) async {
    final List<Map<String, dynamic>> data =
        watchlists.map((w) => w.toJson()).toList();
    await _prefs.setString(_keyWatchlists, jsonEncode(data));
  }

  // Wallet Balance
  double getWalletBalance() {
    return _prefs.getDouble(_keyWalletBalance) ?? _initialBalance;
  }

  Future<void> saveWalletBalance(double balance) async {
    await _prefs.setDouble(_keyWalletBalance, balance);
  }

  // Holdings
  List<Holding> getHoldings() {
    final String? data = _prefs.getString(_keyHoldings);
    if (data == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Holding.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHoldings(List<Holding> holdings) async {
    final List<Map<String, dynamic>> data =
        holdings.map((h) => h.toJson()).toList();
    await _prefs.setString(_keyHoldings, jsonEncode(data));
  }

  // Orders
  List<Order> getOrders() {
    final String? data = _prefs.getString(_keyOrders);
    if (data == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Order.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveOrders(List<Order> orders) async {
    final List<Map<String, dynamic>> data =
        orders.map((o) => o.toJson()).toList();
    await _prefs.setString(_keyOrders, jsonEncode(data));
  }

  // Clear or Reset
  Future<void> clearAll() async {
    await _prefs.remove(_keyWatchlists);
    await _prefs.remove(_keyWalletBalance);
    await _prefs.remove(_keyHoldings);
    await _prefs.remove(_keyOrders);
  }
}
