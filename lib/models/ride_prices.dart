/// Fare configuration set by the super admin.
/// Prices are per seat in ZMW (Zambian Kwacha).
class RidePrices {
  final double campusToTown;
  final double townToAcross;
  final double townToInsideCampus;

  const RidePrices({
    required this.campusToTown,
    required this.townToAcross,
    required this.townToInsideCampus,
  });

  /// Hard-coded defaults used when the backend is unreachable or before
  /// the first successful fetch. The admin can override these at any time.
  static const defaults = RidePrices(
    campusToTown:       20.0,
    townToAcross:       15.0,
    townToInsideCampus: 25.0,
  );

  factory RidePrices.fromJson(Map<String, dynamic> j) => RidePrices(
        campusToTown:       (j['campusToTown']       as num).toDouble(),
        townToAcross:       (j['townToAcross']       as num).toDouble(),
        townToInsideCampus: (j['townToInsideCampus'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'campusToTown':       campusToTown,
        'townToAcross':       townToAcross,
        'townToInsideCampus': townToInsideCampus,
      };

  RidePrices copyWith({
    double? campusToTown,
    double? townToAcross,
    double? townToInsideCampus,
  }) =>
      RidePrices(
        campusToTown:       campusToTown       ?? this.campusToTown,
        townToAcross:       townToAcross       ?? this.townToAcross,
        townToInsideCampus: townToInsideCampus ?? this.townToInsideCampus,
      );
}
