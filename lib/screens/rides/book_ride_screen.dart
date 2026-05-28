import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/ride_booking.dart';
import '../../models/ride_prices.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_prices_provider.dart';
import '../../services/api_client.dart';
import '../../services/ride_service.dart';
import '../../widgets/auth_prompt.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key, this.initialFrom, this.initialTo});
  final String? initialFrom;
  final String? initialTo;

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final _form    = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  final _svc     = RideService();

  // ── Route state ───────────────────────────────────────────────────────────
  RouteDirection _direction = RouteDirection.campusToTown;
  DropOff _dropOff          = DropOff.across;

  /// Campus location for "Campus → Town" (the pickup) or
  /// "Town → Campus + Inside Campus" (the destination).
  String? _campusLocation;

  // ── Booking state ─────────────────────────────────────────────────────────
  RideType   _type        = RideType.instant;
  DateTime?  _scheduledAt;
  int        _seats       = 1;
  bool       _saving      = false;
  String?    _error;

  // ── Derived fields ────────────────────────────────────────────────────────

  /// The "From" string sent to the backend.
  String? get _from {
    if (_direction == RouteDirection.campusToTown) return _campusLocation;
    return 'Town'; // for town-to-campus the town location is implicit
  }

  /// The "To" string sent to the backend.
  String? get _to {
    if (_direction == RouteDirection.campusToTown) return 'Town';
    if (_dropOff == DropOff.across) return 'Campus (Across — outside gate)';
    return _campusLocation; // inside campus needs a specific location
  }

  double _estimatedFareWith(RidePricesProvider rp) => estimatedFare(
        direction:          _direction,
        dropOff:            _dropOff,
        seats:              _seats,
        campusToTown:       rp.prices.campusToTown,
        townToAcross:       rp.prices.townToAcross,
        townToInsideCampus: rp.prices.townToInsideCampus,
      );

  /// Whether we need the campus location picker.
  bool get _needsCampusLocation =>
      _direction == RouteDirection.campusToTown ||
      (_direction == RouteDirection.townToCampus &&
          _dropOff == DropOff.insideCampus);

  @override
  void initState() {
    super.initState();
    _campusLocation = widget.initialFrom ?? widget.initialTo;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _pickCampusLocation() => showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _LocationPicker(
          title: _direction == RouteDirection.campusToTown
              ? 'Pickup location on campus'
              : 'Drop-off location on campus',
          locations: campusLocations,
          current: _campusLocation,
        ),
      );

  Future<void> _pickDateTime() async {
    final now  = DateTime.now();
    final init = _scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null || !mounted) return;
    setState(() => _scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validation
    if (_needsCampusLocation && (_campusLocation == null || _campusLocation!.isEmpty)) {
      setState(() => _error = _direction == RouteDirection.campusToTown
          ? 'Please choose your pickup location on campus.'
          : 'Please choose where on campus you want to be dropped.');
      return;
    }
    if (_type == RideType.scheduled && _scheduledAt == null) {
      setState(() => _error = 'Please choose the date and time for your ride.');
      return;
    }

    // Auth gate — show prompt without losing form state
    if (!context.read<AuthProvider>().isAuthenticated) {
      showAuthPrompt(
        context,
        message: 'Sign in to confirm your ride from ${_from ?? 'campus'}'
            ' to ${_to ?? 'town'}.',
      );
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await _svc.create(
        from:        _from!,
        to:          _to!,
        direction:   _direction,
        dropOff:     _dropOff,
        type:        _type,
        scheduledAt: _type == RideType.scheduled ? _scheduledAt : null,
        seats:       _seats,
        note:        _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rp     = context.watch<RidePricesProvider>();
    final prices = rp.prices;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Ride')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ════════════════════════════════════════
            // 1. ROUTE DIRECTION
            // ════════════════════════════════════════
            _SectionLabel('Where are you going?'),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(
                child: _DirectionTile(
                  label: 'Campus → Town',
                  fromIcon: Symbols.school,
                  toIcon: Symbols.location_city,
                  selected: _direction == RouteDirection.campusToTown,
                  fare: 'K${prices.campusToTown.toStringAsFixed(0)}/seat',
                  onTap: () => setState(() {
                    _direction = RouteDirection.campusToTown;
                    _error = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectionTile(
                  label: 'Town → Campus',
                  fromIcon: Symbols.location_city,
                  toIcon: Symbols.school,
                  selected: _direction == RouteDirection.townToCampus,
                  fare: 'K${prices.townToAcross.toStringAsFixed(0)}–'
                      'K${prices.townToInsideCampus.toStringAsFixed(0)}/seat',
                  onTap: () => setState(() {
                    _direction = RouteDirection.townToCampus;
                    _error = null;
                  }),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ════════════════════════════════════════
            // 2a. CAMPUS PICKUP (campus → town)
            // ════════════════════════════════════════
            if (_direction == RouteDirection.campusToTown) ...[
              _SectionLabel('Pickup location'),
              const SizedBox(height: 10),
              _RouteCard(
                children: [
                  _LocationRow(
                    dotColor: Colors.green,
                    label: 'From',
                    value: _campusLocation,
                    placeholder: 'Choose your location on campus',
                    icon: Symbols.my_location,
                    onTap: () async {
                      final v = await _pickCampusLocation();
                      if (v != null) setState(() => _campusLocation = v);
                    },
                  ),
                  _RouteDivider(),
                  _LocationRow(
                    dotColor: kOrange,
                    label: 'To',
                    value: 'Town',
                    icon: Symbols.location_city,
                    isFixed: true,
                  ),
                ],
              ),
            ],

            // ════════════════════════════════════════
            // 2b. TOWN → CAMPUS
            // ════════════════════════════════════════
            if (_direction == RouteDirection.townToCampus) ...[
              _SectionLabel('Drop-off preference'),
              const SizedBox(height: 10),

              // Fixed "from" town row
              _RouteCard(
                children: [
                  _LocationRow(
                    dotColor: Colors.green,
                    label: 'From',
                    value: 'Town',
                    icon: Symbols.location_city,
                    isFixed: true,
                  ),
                  _RouteDivider(),
                  _LocationRow(
                    dotColor: kOrange,
                    label: 'To',
                    value: _dropOff == DropOff.across
                        ? 'Campus (Across — outside gate)'
                        : (_campusLocation ?? 'Choose campus location'),
                    placeholder: 'Choose campus location',
                    icon: Symbols.school,
                    isFixed: _dropOff == DropOff.across,
                    onTap: _dropOff == DropOff.insideCampus
                        ? () async {
                            final v = await _pickCampusLocation();
                            if (v != null) setState(() => _campusLocation = v);
                          }
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Drop-off tiles
              _DropOffTile(
                selected: _dropOff == DropOff.across,
                onTap: () => setState(() {
                  _dropOff = DropOff.across;
                  _campusLocation = null;
                  _error = null;
                }),
                title: 'Across',
                subtitle: 'Driver drops you at the road crossing just '
                    'outside the campus gate.',
                badge: 'K${prices.townToAcross.toStringAsFixed(0)}/seat',
                badgeColor: Colors.green,
                icon: Symbols.directions_walk,
              ),
              const SizedBox(height: 8),
              _DropOffTile(
                selected: _dropOff == DropOff.insideCampus,
                onTap: () => setState(() {
                  _dropOff = DropOff.insideCampus;
                  _error = null;
                }),
                title: 'Inside Campus',
                subtitle: 'Driver enters campus and drops you at your '
                    'chosen location.',
                badge: 'K${prices.townToInsideCampus.toStringAsFixed(0)}/seat',
                badgeColor: kOrange,
                icon: Symbols.school,
              ),

              // Inside-campus location picker
              if (_dropOff == DropOff.insideCampus) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(
                    Symbols.location_on,
                    color: _campusLocation != null ? kOrange : null,
                  ),
                  label: Text(
                    _campusLocation ?? 'Choose drop-off location on campus',
                    style: TextStyle(
                        color: _campusLocation != null
                            ? kOrange
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  onPressed: () async {
                    final v = await _pickCampusLocation();
                    if (v != null) setState(() => _campusLocation = v);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: _campusLocation != null
                            ? kOrange
                            : Colors.grey.shade300),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ════════════════════════════════════════
            // 3. FARE ESTIMATE
            // ════════════════════════════════════════
            _FareCard(
              fare: _estimatedFareWith(rp),
              seats: _seats,
              direction: _direction,
              dropOff: _dropOff,
              prices: prices,
            ),

            const SizedBox(height: 20),

            // ════════════════════════════════════════
            // 4. BOOKING TYPE
            // ════════════════════════════════════════
            _SectionLabel('Booking type'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _TypeChip(
                  label: 'Book Now',
                  icon: Symbols.bolt,
                  selected: _type == RideType.instant,
                  description: 'Find a driver immediately',
                  onTap: () => setState(() {
                    _type = RideType.instant;
                    _scheduledAt = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChip(
                  label: 'Reserve',
                  icon: Symbols.schedule,
                  selected: _type == RideType.scheduled,
                  description: 'Pick a date & time',
                  onTap: () => setState(() => _type = RideType.scheduled),
                ),
              ),
            ]),

            // Date/time picker
            if (_type == RideType.scheduled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Symbols.calendar_today),
                label: Text(_scheduledAt == null
                    ? 'Choose date & time'
                    : DateFormat('EEE, d MMM y  •  h:mm a')
                        .format(_scheduledAt!)),
                onPressed: _pickDateTime,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ════════════════════════════════════════
            // 5. SEATS
            // ════════════════════════════════════════
            Row(children: [
              _SectionLabel('Seats needed'),
              const Spacer(),
              _CounterButton(
                icon: Symbols.remove,
                onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_seats',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _CounterButton(
                icon: Symbols.add,
                onPressed: _seats < 4 ? () => setState(() => _seats++) : null,
              ),
            ]),
            Text('Up to 4 passengers per ride',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),

            const SizedBox(height: 16),

            // ════════════════════════════════════════
            // 6. NOTE
            // ════════════════════════════════════════
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note to driver (optional)',
                hintText: "e.g. I'll be at the main entrance",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Symbols.sticky_note_2),
              ),
            ),

            // Error banner
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Symbols.error, size: 18,
                      color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: scheme.onErrorContainer)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ════════════════════════════════════════
            // 7. SUBMIT
            // ════════════════════════════════════════
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _type == RideType.instant
                          ? 'Find a Ride Now'
                          : 'Reserve Seat',
                      style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOCATION PICKER BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _LocationPicker extends StatefulWidget {
  final String title;
  final List<String> locations;
  final String? current;
  const _LocationPicker(
      {required this.title, required this.locations, this.current});

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  final _ctrl = TextEditingController();
  late List<String> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.locations;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _results = q.isEmpty
            ? widget.locations
            : widget.locations
                .where((l) => l.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search or type a location…',
                prefixIcon: Icon(Symbols.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_ctrl.text.isNotEmpty && _results.isEmpty)
            ListTile(
              leading:
                  const Icon(Symbols.edit_location_alt, color: kOrange),
              title: Text('"${_ctrl.text}"'),
              subtitle: const Text('Use this custom location'),
              onTap: () => Navigator.pop(context, _ctrl.text.trim()),
            ),
          if (_ctrl.text.isNotEmpty && _results.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.edit_location_alt, size: 16),
                label: Text('Use "${_ctrl.text}"'),
                onPressed: () =>
                    Navigator.pop(context, _ctrl.text.trim()),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final loc  = _results[i];
                final sel  = loc == widget.current;
                return ListTile(
                  leading: Icon(Symbols.location_on,
                      color: sel ? kOrange : Colors.grey, size: 20),
                  title: Text(loc,
                      style: TextStyle(
                          color: sel ? kOrange : null,
                          fontWeight:
                              sel ? FontWeight.w600 : null)),
                  trailing: sel
                      ? const Icon(Symbols.check_circle,
                          color: kOrange, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, loc),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );
}

// ── Route card shell ──────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final List<Widget> children;
  const _RouteCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

// ── Single from/to row inside the route card ──────────────────────────────────

class _LocationRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String? value;
  final String? placeholder;
  final IconData icon;
  final bool isFixed;
  final VoidCallback? onTap;

  const _LocationRow({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.icon,
    this.placeholder,
    this.isFixed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;

    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: dotColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: dotColor),
      ),
      title: Text(
        hasValue ? value! : placeholder ?? '',
        style: TextStyle(
          color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
          fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(label, style: const TextStyle(fontSize: 11)),
      trailing: isFixed
          ? null
          : const Icon(Symbols.chevron_right),
      onTap: isFixed ? null : onTap,
    );
  }
}

class _RouteDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant),
      );
}

// ── Direction tile (Campus → Town / Town → Campus) ────────────────────────────

class _DirectionTile extends StatelessWidget {
  final String label;
  final IconData fromIcon;
  final IconData toIcon;
  final bool selected;
  final String fare;
  final VoidCallback onTap;

  const _DirectionTile({
    required this.label,
    required this.fromIcon,
    required this.toIcon,
    required this.selected,
    required this.fare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kOrangeLight : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(fromIcon,
                    size: 22,
                    color: selected ? kOrange : Colors.grey.shade600),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Symbols.arrow_forward,
                      size: 16,
                      color: selected ? kOrange : Colors.grey.shade400),
                ),
                Icon(toIcon,
                    size: 22,
                    color: selected ? kOrange : Colors.grey.shade600),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? kOrange : null)),
            const SizedBox(height: 4),
            // Fare hint
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (selected ? kOrange : Colors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(fare,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? kOrange : Colors.grey.shade600)),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Symbols.check_circle,
                    size: 16, color: kOrange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Drop-off choice tile ──────────────────────────────────────────────────────

class _DropOffTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;

  const _DropOffTile({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kOrangeLight : Colors.transparent,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:
                  (selected ? kOrange : Colors.grey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 20,
                color: selected ? kOrange : Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? kOrange : null)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? kOrange.withValues(alpha: 0.8)
                            : Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Symbols.check_circle,
                color: kOrange, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ── Fare estimate card ────────────────────────────────────────────────────────

class _FareCard extends StatelessWidget {
  final double fare;
  final int seats;
  final RouteDirection direction;
  final DropOff dropOff;
  final RidePrices prices;

  const _FareCard({
    required this.fare,
    required this.seats,
    required this.direction,
    required this.dropOff,
    required this.prices,
  });

  String get _fareLabel {
    final perSeat = direction == RouteDirection.campusToTown
        ? prices.campusToTown
        : dropOff == DropOff.across
            ? prices.townToAcross
            : prices.townToInsideCampus;
    return 'K${perSeat.toStringAsFixed(0)} × $seats seat${seats > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kOrange.withValues(alpha: 0.08),
            kOrange.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrange.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
              color: kOrangeLight, shape: BoxShape.circle),
          child: const Icon(Symbols.account_balance_wallet,
              size: 20, color: kOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimated fare',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(_fareLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text(
          'K${fare.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kOrange),
        ),
      ]),
    );
  }
}

// ── Booking type chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String description;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kOrangeLight : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  size: 20,
                  color: selected ? kOrange : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? kOrange : null)),
              const Spacer(),
              if (selected)
                const Icon(Symbols.check_circle,
                    size: 16, color: kOrange),
            ]),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? kOrange
                        : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ── Seat counter button ───────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          onPressed == null ? Colors.grey.shade100 : kOrangeLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 18,
              color: onPressed == null ? Colors.grey : kOrange),
        ),
      ),
    );
  }
}
