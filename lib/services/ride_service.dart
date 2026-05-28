import '../models/ride_booking.dart';
import 'api_client.dart';

class RideService {
  // ── Streams (polling) ─────────────────────────────────────────────────────

  Stream<List<RideBooking>> streamPending() => pollingStream(
        () => _fetch('/rides?status=pending'),
        interval: const Duration(seconds: 15),
      );

  Stream<List<RideBooking>> streamMine() => pollingStream(
        () => _fetch('/rides/mine'),
        interval: const Duration(seconds: 15),
      );

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<RideBooking> create({
    required String from,
    required String to,
    required RouteDirection direction,
    required DropOff dropOff,
    required RideType type,
    DateTime? scheduledAt,
    int seats = 1,
    String? note,
  }) async {
    final body = {
      'from':        from,
      'to':          to,
      'direction':   routeDirectionToApi(direction),
      'dropOff':     dropOffToApi(dropOff),
      'type':        type.name.toUpperCase(),
      'seats':       seats,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final data = await ApiClient.post('/rides', body) as Map<String, dynamic>;
    return RideBooking.fromJson(data);
  }

  Future<void> accept(String id) =>
      ApiClient.post('/rides/$id/accept').then((_) {});

  Future<void> complete(String id) =>
      ApiClient.post('/rides/$id/complete').then((_) {});

  Future<void> cancel(String id) =>
      ApiClient.post('/rides/$id/cancel').then((_) {});

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<RideBooking>> _fetch(String path) async {
    final data = await ApiClient.get(path) as List<dynamic>;
    return data
        .map((e) => RideBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
