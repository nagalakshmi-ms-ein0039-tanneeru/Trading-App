import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trading_app/core/services/storage_service.dart';
import 'package:trading_app/data/models/watchlist.dart';

class WatchlistState extends Equatable {
  final List<Watchlist> watchlists;
  final int selectedWatchlistIndex;

  const WatchlistState({
    required this.watchlists,
    this.selectedWatchlistIndex = 0,
  });

  Watchlist? get selectedWatchlist {
    if (watchlists.isEmpty ||
        selectedWatchlistIndex < 0 ||
        selectedWatchlistIndex >= watchlists.length) {
      return null;
    }
    return watchlists[selectedWatchlistIndex];
  }

  WatchlistState copyWith({
    List<Watchlist>? watchlists,
    int? selectedWatchlistIndex,
  }) {
    return WatchlistState(
      watchlists: watchlists ?? this.watchlists,
      selectedWatchlistIndex:
          selectedWatchlistIndex ?? this.selectedWatchlistIndex,
    );
  }

  @override
  List<Object?> get props => [watchlists, selectedWatchlistIndex];
}

class WatchlistCubit extends Cubit<WatchlistState> {
  final StorageService _storageService;

  WatchlistCubit({StorageService? storageService})
      : _storageService = storageService ?? StorageService(),
        super(const WatchlistState(watchlists: [])) {
    loadWatchlists();
  }

  void loadWatchlists() {
    final list = _storageService.getWatchlists();
    emit(WatchlistState(watchlists: list, selectedWatchlistIndex: 0));
  }

  Future<void> createWatchlist(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final newWatchlist = Watchlist(
      id: 'watchlist_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      stockSymbols: const [],
    );

    final updated = List<Watchlist>.from(state.watchlists)..add(newWatchlist);
    emit(state.copyWith(
      watchlists: updated,
      selectedWatchlistIndex: updated.length - 1,
    ));
    await _storageService.saveWatchlists(updated);
  }

  Future<void> renameWatchlist(String id, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    final updated = state.watchlists.map((w) {
      if (w.id == id) {
        return w.copyWith(name: cleanName);
      }
      return w;
    }).toList();

    emit(state.copyWith(watchlists: updated));
    await _storageService.saveWatchlists(updated);
  }

  Future<void> deleteWatchlist(String id) async {
    if (state.watchlists.length <= 1) {
      // Keep at least one watchlist
      return;
    }

    final updated = state.watchlists.where((w) => w.id != id).toList();
    int newIndex = state.selectedWatchlistIndex;
    if (newIndex >= updated.length) {
      newIndex = updated.length - 1;
    }

    emit(state.copyWith(
      watchlists: updated,
      selectedWatchlistIndex: newIndex,
    ));
    await _storageService.saveWatchlists(updated);
  }

  void selectWatchlist(int index) {
    if (index >= 0 && index < state.watchlists.length) {
      emit(state.copyWith(selectedWatchlistIndex: index));
    }
  }

  Future<void> addStockToWatchlist(String id, String symbol) async {
    final updated = state.watchlists.map((w) {
      if (w.id == id) {
        if (w.stockSymbols.contains(symbol)) return w;
        final symbols = List<String>.from(w.stockSymbols)..add(symbol);
        return w.copyWith(stockSymbols: symbols);
      }
      return w;
    }).toList();

    emit(state.copyWith(watchlists: updated));
    await _storageService.saveWatchlists(updated);
  }

  Future<void> removeStockFromWatchlist(String id, String symbol) async {
    final updated = state.watchlists.map((w) {
      if (w.id == id) {
        final symbols = List<String>.from(w.stockSymbols)..remove(symbol);
        return w.copyWith(stockSymbols: symbols);
      }
      return w;
    }).toList();

    emit(state.copyWith(watchlists: updated));
    await _storageService.saveWatchlists(updated);
  }

  Future<void> reorderStocks(String id, int oldIndex, int newIndex) async {
    final updated = state.watchlists.map((w) {
      if (w.id == id) {
        final symbols = List<String>.from(w.stockSymbols);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = symbols.removeAt(oldIndex);
        symbols.insert(newIndex, item);
        return w.copyWith(stockSymbols: symbols);
      }
      return w;
    }).toList();

    emit(state.copyWith(watchlists: updated));
    await _storageService.saveWatchlists(updated);
  }
}
