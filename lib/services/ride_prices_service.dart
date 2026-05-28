import '../models/ride_prices.dart';
import 'api_client.dart';

class RidePricesService {
  static const _path = '/settings/ride-prices';

  Future<RidePrices> fetch() async {
    final data = await ApiClient.get(_path) as Map<String, dynamic>;
    return RidePrices.fromJson(data);
  }

  Future<RidePrices> update(RidePrices prices) async {
    final data =
        await ApiClient.put(_path, prices.toJson()) as Map<String, dynamic>;
    return RidePrices.fromJson(data);
  }
}
