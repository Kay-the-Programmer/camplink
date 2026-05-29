import 'package:flutter/foundation.dart';

import '../models/ride_prices.dart';
import '../services/ride_prices_service.dart';

class RidePricesProvider extends ChangeNotifier {
  final _svc = RidePricesService();

  RidePrices _prices = RidePrices.defaults;
  bool _loading = true;
  String? _error;

  RidePrices get prices  => _prices;
  bool       get loading => _loading;
  String?    get error   => _error;

  RidePricesProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      _prices = await _svc.fetch();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Admin-only: persist new prices to the backend.
  Future<void> updatePrices(RidePrices updated) async {
    _prices = await _svc.update(updated);
    notifyListeners();
  }

  /// Refresh from the backend (e.g. after returning to the rides screen).
  Future<void> refresh() => _load();
}
