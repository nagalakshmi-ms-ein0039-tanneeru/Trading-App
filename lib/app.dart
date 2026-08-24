import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_app/core/constants/app_colors.dart';
import 'package:trading_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:trading_app/features/markets/bloc/markets_cubit.dart';
import 'package:trading_app/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:trading_app/features/holdings/bloc/holdings_cubit.dart';
import 'package:trading_app/features/trade/bloc/trade_cubit.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MarketsCubit>(
          create: (context) => MarketsCubit(),
        ),
        BlocProvider<WatchlistCubit>(
          create: (context) => WatchlistCubit(),
        ),
        BlocProvider<HoldingsCubit>(
          create: (context) => HoldingsCubit(),
        ),
        BlocProvider<TradeCubit>(
          create: (context) => TradeCubit(
            holdingsCubit: context.read<HoldingsCubit>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '021 Trading App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
            error: AppColors.downRed,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            elevation: 8,
          ),
          cardTheme: const CardThemeData(
            color: AppColors.surfaceElevated,
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
