import 'package:flutter/material.dart';
import 'package:trading_app/app.dart';
import 'package:trading_app/core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service (SharedPreferences)
  await StorageService().init();

  runApp(const TradingApp());
}
