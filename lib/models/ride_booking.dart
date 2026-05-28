// ── Campus locations ──────────────────────────────────────────────────────────

/// Well-known spots at Mulungushi University used as autocomplete options.
const campusLocations = [
  'Main Gate',
  'Administration Block',
  'Library',
  'Student Centre',
  'Cafeteria / Tuck Shop',
  'Main Hall / Auditorium',
  'Sports Complex',
  'Sinozulu Hostel',
  'Lunsemfwa Hostel',
  'Kafue Hostel',
  'Luangwa Hostel',
  'Zambezi Hostel',
  'Engineering Block',
  'ICT Block',
  'Business School',
  'Law School',
  'Health Sciences Block',
  'Staff Houses',
  'Security Office',
  'Bank / ATM',
];

/// Known town pick-up / drop-off points.
const townLocations = [
  'Town Centre',
  'Kabwe Bus Station',
  'Freedom Way',
  'Cairo Road',
  'Shoprite Kabwe',
  'Pick n Pay',
  'Hospital',
  'Railway Station',
];

// ── Route direction ────────────────────────────────────────────────────────────

enum RouteDirection { campusToTown, townToCampus }

RouteDirection routeDirectionFromString(String? s) {
  return s?.toUpperCase() == 'TOWN_TO_CAMPUS'
      ? RouteDirection.townToCampus
      : RouteDirection.campusToTown;
}

String routeDirectionToApi(RouteDirection d) =>
    d == RouteDirection.campusToTown ? 'CAMPUS_TO_TOWN' : 'TOWN_TO_CAMPUS';

// ── Drop-off option (town → campus only) ─────────────────────────────────────

/// Where the driver drops the passenger when coming from town.
enum DropOff {
  /// Dropped at the road crossing just outside the campus gate — cheaper.
  across,

  /// Driver enters campus and drops passenger at their chosen location.
  insideCampus,
}

DropOff dropOffFromString(String? s) =>
    s?.toUpperCase() == 'INSIDE_CAMPUS' ? DropOff.insideCampus : DropOff.across;

String dropOffToApi(DropOff d) =>
    d == DropOff.insideCampus ? 'INSIDE_CAMPUS' : 'ACROSS';

// ── Fare helpers ──────────────────────────────────────────────────────────────

/// Compute estimated total fare given the admin-configured per-seat prices.
/// [campusToTown], [townToAcross], [townToInsideCampus] come from
/// [RidePricesProvider] — never hardcode these in the UI.
double estimatedFare({
  required RouteDirection direction,
  required DropOff dropOff,
  required int seats,
  required double campusToTown,
  required double townToAcross,
  required double townToInsideCampus,
}) {
  final perSeat = direction == RouteDirection.campusToTown
      ? campusToTown
      : dropOff == DropOff.across
          ? townToAcross
          : townToInsideCampus;
  return perSeat * seats;
}

// ── Ride type (instant vs scheduled) ─────────────────────────────────────────

enum RideType { instant, scheduled }

RideType rideTypeFromString(String? s) =>
    s?.toUpperCase() == 'SCHEDULED' ? RideType.scheduled : RideType.instant;

// ── Ride status ───────────────────────────────────────────────────────────────

enum RideStatus { pending, accepted, inProgress, completed, cancelled }

RideStatus rideStatusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'ACCEPTED':    return RideStatus.accepted;
    case 'IN_PROGRESS': return RideStatus.inProgress;
    case 'COMPLETED':   return RideStatus.completed;
    case 'CANCELLED':   return RideStatus.cancelled;
    default:            return RideStatus.pending;
  }
}

String rideStatusLabel(RideStatus s) {
  switch (s) {
    case RideStatus.pending:    return 'Pending';
    case RideStatus.accepted:   return 'Accepted';
    case RideStatus.inProgress: return 'In Progress';
    case RideStatus.completed:  return 'Completed';
    case RideStatus.cancelled:  return 'Cancelled';
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class RideBooking {
  final String id;
  final String passengerId;
  final String passengerName;
  final String from;
  final String to;
  final RouteDirection direction;
  final DropOff dropOff;
  final RideType type;
  final DateTime? scheduledAt;
  final int seats;
  final String? note;
  final RideStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? fare;
  final DateTime createdAt;

  const RideBooking({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.from,
    required this.to,
    required this.direction,
    required this.dropOff,
    required this.type,
    this.scheduledAt,
    required this.seats,
    this.note,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.fare,
    required this.createdAt,
  });

  factory RideBooking.fromJson(Map<String, dynamic> j) => RideBooking(
        id:            j['id'] as String,
        passengerId:   j['passengerId'] as String,
        passengerName: j['passengerName'] as String,
        from:          j['from'] as String,
        to:            j['to'] as String,
        direction:     routeDirectionFromString(j['direction'] as String?),
        dropOff:       dropOffFromString(j['dropOff'] as String?),
        type:          rideTypeFromString(j['type'] as String?),
        scheduledAt:   j['scheduledAt'] != null
            ? DateTime.parse(j['scheduledAt'] as String)
            : null,
        seats:         (j['seats'] as num?)?.toInt() ?? 1,
        note:          j['note'] as String?,
        status:        rideStatusFromString(j['status'] as String?),
        driverId:      j['driverId'] as String?,
        driverName:    j['driverName'] as String?,
        driverPhone:   j['driverPhone'] as String?,
        fare:          (j['fare'] as num?)?.toDouble(),
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'from':        from,
        'to':          to,
        'direction':   routeDirectionToApi(direction),
        'dropOff':     dropOffToApi(dropOff),
        'type':        type.name.toUpperCase(),
        'seats':       seats,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  bool get isActive =>
      status == RideStatus.pending ||
      status == RideStatus.accepted ||
      status == RideStatus.inProgress;

  /// Human-readable drop-off label shown on cards.
  String get dropOffLabel => dropOff == DropOff.across
      ? 'Across (outside gate)'
      : 'Inside campus';
}
