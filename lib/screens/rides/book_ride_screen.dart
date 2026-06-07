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

/// Book a ride in four focused steps:
///   0. Direction   — Campus → Town or Town → Campus
///   1. Location    — pickup spot / drop-off preference
///   2. When        — book now or reserve for later
///   3. Review      — seats, note, fare and confirm
class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key, this.initialFrom, this.initialTo});
  final String? initialFrom;
  final String? initialTo;

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  static const _stepCount = 4;

  final _noteCtrl = TextEditingController();
  final _svc      = RideService();

  int _step = 0;

  // ── Route state ───────────────────────────────────────────────────────────
  RouteDirection _direction = RouteDirection.campusToTown;
  DropOff _dropOff          = DropOff.across;
  String? _campusLocation;

  // ── Booking state ─────────────────────────────────────────────────────────
  RideType  _type        = RideType.instant;
  DateTime? _scheduledAt;
  int       _seats       = 1;
  bool      _saving      = false;
  String?   _error;

  // ── Derived fields ────────────────────────────────────────────────────────

  String get _from =>
      _direction == RouteDirection.campusToTown ? (_campusLocation ?? '') : 'Town';

  String get _to {
    if (_direction == RouteDirection.campusToTown) return 'Town';
    if (_dropOff == DropOff.across) return 'Campus (Across — outside gate)';
    return _campusLocation ?? '';
  }

  bool get _needsCampusLocation =>
      _direction == RouteDirection.campusToTown ||
      (_direction == RouteDirection.townToCampus &&
          _dropOff == DropOff.insideCampus);

  double _fareWith(RidePricesProvider rp) => estimatedFare(
        direction:          _direction,
        dropOff:            _dropOff,
        seats:              _seats,
        campusToTown:       rp.prices.campusToTown,
        townToAcross:       rp.prices.townToAcross,
        townToInsideCampus: rp.prices.townToInsideCampus,
      );

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

  // ── Navigation between steps ────────────────────────────────────────────────

  String? _validateStep() {
    switch (_step) {
      case 1:
        if (_needsCampusLocation &&
            (_campusLocation == null || _campusLocation!.isEmpty)) {
          return _direction == RouteDirection.campusToTown
              ? 'Please choose your pickup location on campus.'
              : 'Please choose where on campus you want to be dropped.';
        }
        return null;
      case 2:
        if (_type == RideType.scheduled && _scheduledAt == null) {
          return 'Please choose the date and time for your ride.';
        }
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final err = _validateStep();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() {
        _step++;
        _error = null;
      });
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────

  Future<void> _pickCampusLocation() async {
    final v = await showModalBottomSheet<String>(
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
    if (v != null) setState(() => _campusLocation = v);
  }

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
    if (!context.read<AuthProvider>().isAuthenticated) {
      showAuthPrompt(
        context,
        message: 'Sign in to confirm your ride from $_from to $_to.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error  = null;
    });
    try {
      await _svc.create(
        from:        _from,
        to:          _to,
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

  static const _titles = [
    'Where to?',
    'Set your location',
    'When do you need it?',
    'Review & confirm',
  ];

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RidePricesProvider>();

    return PopScope(
      // On the first step let the route pop normally; otherwise consume the
      // back gesture and step backwards through the wizard.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _step--;
            _error = null;
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: _back,
        ),
        title: const Text('Book a Ride'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: _StepProgress(step: _step, total: _stepCount),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: ListView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  Text(
                    _titles[_step],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  ..._stepBody(rp),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(_error!),
                  ],
                ],
              ),
            ),
          ),
          _BottomBar(
            step: _step,
            total: _stepCount,
            fare: _fareWith(rp),
            saving: _saving,
            primaryLabel: _step < _stepCount - 1
                ? 'Continue'
                : (_type == RideType.instant ? 'Find a Ride Now' : 'Reserve Seat'),
            onBack: _step == 0 ? null : _back,
            onPrimary: _saving ? null : _next,
          ),
        ],
      ),
      ),
    );
  }

  // ── Step bodies ─────────────────────────────────────────────────────────────

  List<Widget> _stepBody(RidePricesProvider rp) {
    switch (_step) {
      case 0:
        return _directionStep(rp.prices);
      case 1:
        return _locationStep(rp.prices);
      case 2:
        return _whenStep();
      default:
        return _reviewStep(rp);
    }
  }

  // Step 0 — direction
  List<Widget> _directionStep(RidePrices prices) => [
        _DirectionTile(
          label: 'Campus → Town',
          subtitle: 'Pick-up on campus, drop in town',
          fromIcon: Symbols.school,
          toIcon: Symbols.location_city,
          fare: 'K${prices.campusToTown.toStringAsFixed(0)}/seat',
          selected: _direction == RouteDirection.campusToTown,
          onTap: () => setState(() {
            _direction = RouteDirection.campusToTown;
            _error = null;
          }),
        ),
        const SizedBox(height: 12),
        _DirectionTile(
          label: 'Town → Campus',
          subtitle: 'From town back to campus',
          fromIcon: Symbols.location_city,
          toIcon: Symbols.school,
          fare: 'from K${prices.townToAcross.toStringAsFixed(0)}/seat',
          selected: _direction == RouteDirection.townToCampus,
          onTap: () => setState(() {
            _direction = RouteDirection.townToCampus;
            _error = null;
          }),
        ),
      ];

  // Step 1 — location / drop-off
  List<Widget> _locationStep(RidePrices prices) {
    if (_direction == RouteDirection.campusToTown) {
      return [
        const _Hint('Tell us where on campus the driver should pick you up.'),
        const SizedBox(height: 14),
        _FieldButton(
          icon: Symbols.my_location,
          label: 'Pickup location',
          value: _campusLocation,
          placeholder: 'Choose your location on campus',
          onTap: _pickCampusLocation,
        ),
      ];
    }

    // Town → Campus: drop-off preference
    return [
      const _Hint('Where would you like the driver to drop you?'),
      const SizedBox(height: 14),
      _DropOffTile(
        selected: _dropOff == DropOff.across,
        onTap: () => setState(() {
          _dropOff = DropOff.across;
          _campusLocation = null;
          _error = null;
        }),
        title: 'Across',
        subtitle: 'Dropped at the road crossing just outside the campus gate.',
        badge: 'K${prices.townToAcross.toStringAsFixed(0)}/seat',
        badgeColor: Colors.green,
        icon: Symbols.directions_walk,
      ),
      const SizedBox(height: 10),
      _DropOffTile(
        selected: _dropOff == DropOff.insideCampus,
        onTap: () => setState(() {
          _dropOff = DropOff.insideCampus;
          _error = null;
        }),
        title: 'Inside Campus',
        subtitle: 'Driver enters campus and drops you at your chosen spot.',
        badge: 'K${prices.townToInsideCampus.toStringAsFixed(0)}/seat',
        badgeColor: kOrange,
        icon: Symbols.school,
      ),
      if (_dropOff == DropOff.insideCampus) ...[
        const SizedBox(height: 14),
        _FieldButton(
          icon: Symbols.location_on,
          label: 'Drop-off location',
          value: _campusLocation,
          placeholder: 'Choose drop-off location on campus',
          onTap: _pickCampusLocation,
        ),
      ],
    ];
  }

  // Step 2 — when
  List<Widget> _whenStep() => [
        _TypeChip(
          label: 'Book Now',
          icon: Symbols.bolt,
          description: 'We find you a driver right away',
          selected: _type == RideType.instant,
          onTap: () => setState(() {
            _type = RideType.instant;
            _scheduledAt = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 10),
        _TypeChip(
          label: 'Reserve',
          icon: Symbols.schedule,
          description: 'Schedule the ride for a later date & time',
          selected: _type == RideType.scheduled,
          onTap: () => setState(() {
            _type = RideType.scheduled;
            _error = null;
          }),
        ),
        if (_type == RideType.scheduled) ...[
          const SizedBox(height: 14),
          _FieldButton(
            icon: Symbols.calendar_today,
            label: 'Date & time',
            value: _scheduledAt == null
                ? null
                : DateFormat('EEE, d MMM y  •  h:mm a').format(_scheduledAt!),
            placeholder: 'Choose date & time',
            onTap: _pickDateTime,
          ),
        ],
      ];

  // Step 3 — review & confirm
  List<Widget> _reviewStep(RidePricesProvider rp) {
    final prices = rp.prices;
    final perSeat = _direction == RouteDirection.campusToTown
        ? prices.campusToTown
        : _dropOff == DropOff.across
            ? prices.townToAcross
            : prices.townToInsideCampus;

    return [
      // Trip summary
      _SummaryCard(children: [
        _SummaryRow(
          icon: Symbols.route,
          label: 'Route',
          value: '$_from  →  $_to',
        ),
        _SummaryRow(
          icon: Symbols.event,
          label: 'When',
          value: _type == RideType.instant
              ? 'As soon as possible'
              : DateFormat('EEE, d MMM y • h:mm a').format(_scheduledAt!),
        ),
      ]),

      const SizedBox(height: 16),

      // Seats
      _SectionLabel('Seats needed'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Text('Up to 4 passengers per ride',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        _CounterButton(
          icon: Symbols.remove,
          onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$_seats',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        _CounterButton(
          icon: Symbols.add,
          onPressed: _seats < 4 ? () => setState(() => _seats++) : null,
        ),
      ]),

      const SizedBox(height: 16),

      // Note
      TextField(
        controller: _noteCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Note to driver (optional)',
          hintText: "e.g. I'll be at the main entrance",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Symbols.sticky_note_2),
        ),
      ),

      const SizedBox(height: 18),

      // Fare
      _FareCard(
        total: _fareWith(rp),
        perSeat: perSeat,
        seats: _seats,
      ),
    ];
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP CHROME
// ══════════════════════════════════════════════════════════════════════════════

class _StepProgress extends StatelessWidget {
  final int step;
  final int total;
  const _StepProgress({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: List.generate(total, (i) {
          final done = i <= step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                decoration: BoxDecoration(
                  color: done ? kOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final int total;
  final double fare;
  final bool saving;
  final String primaryLabel;
  final VoidCallback? onBack;
  final VoidCallback? onPrimary;

  const _BottomBar({
    required this.step,
    required this.total,
    required this.fare,
    required this.saving,
    required this.primaryLabel,
    required this.onBack,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Estimated fare',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  Text('K${fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kOrange)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onBack != null) ...[
                    OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14)),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(primaryLabel,
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                final loc = _results[i];
                final sel = loc == widget.current;
                return ListTile(
                  leading: Icon(Symbols.location_on,
                      color: sel ? kOrange : Colors.grey, size: 20),
                  title: Text(loc,
                      style: TextStyle(
                          color: sel ? kOrange : null,
                          fontWeight: sel ? FontWeight.w600 : null)),
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

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Symbols.error, size: 18, color: scheme.onErrorContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: TextStyle(color: scheme.onErrorContainer)),
        ),
      ]),
    );
  }
}

/// A large tappable field that opens a picker (location, date/time).
class _FieldButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _FieldButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? kOrange : Colors.grey.shade300,
            width: hasValue ? 1.5 : 1,
          ),
          color: hasValue ? kOrangeLight : Colors.transparent,
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: hasValue ? kOrange : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value! : placeholder,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Symbols.chevron_right),
        ]),
      ),
    );
  }
}

// ── Direction tile (full-width) ───────────────────────────────────────────────

class _DirectionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData fromIcon;
  final IconData toIcon;
  final bool selected;
  final String fare;
  final VoidCallback onTap;

  const _DirectionTile({
    required this.label,
    required this.subtitle,
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kOrangeLight : Colors.transparent,
        ),
        child: Row(children: [
          // Route icons
          Row(children: [
            Icon(fromIcon,
                size: 24, color: selected ? kOrange : Colors.grey.shade600),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Symbols.arrow_forward,
                  size: 16, color: selected ? kOrange : Colors.grey.shade400),
            ),
            Icon(toIcon,
                size: 24, color: selected ? kOrange : Colors.grey.shade600),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: selected ? kOrange : null)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? kOrange.withValues(alpha: 0.8)
                            : Colors.grey.shade600)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        (selected ? kOrange : Colors.grey).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(fare,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? kOrange : Colors.grey.shade600)),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Symbols.check_circle : Symbols.radio_button_unchecked,
            color: selected ? kOrange : Colors.grey.shade400,
            size: 22,
          ),
        ]),
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
              color: (selected ? kOrange : Colors.grey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 20, color: selected ? kOrange : Colors.grey.shade600),
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
          Icon(
            selected ? Symbols.check_circle : Symbols.radio_button_unchecked,
            color: selected ? kOrange : Colors.grey.shade400,
            size: 20,
          ),
        ]),
      ),
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
              color: (selected ? kOrange : Colors.grey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 20, color: selected ? kOrange : Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? kOrange : null)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? kOrange.withValues(alpha: 0.8)
                            : Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Symbols.check_circle : Symbols.radio_button_unchecked,
            color: selected ? kOrange : Colors.grey.shade400,
            size: 20,
          ),
        ]),
      ),
    );
  }
}

// ── Review summary ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<Widget> children;
  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: kOrange, size: 22),
      title: Text(label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Fare estimate card ────────────────────────────────────────────────────────

class _FareCard extends StatelessWidget {
  final double total;
  final double perSeat;
  final int seats;

  const _FareCard({
    required this.total,
    required this.perSeat,
    required this.seats,
  });

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
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                  'K${perSeat.toStringAsFixed(0)} × $seats seat${seats > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text('K${total.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: kOrange)),
      ]),
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
      color: onPressed == null ? Colors.grey.shade100 : kOrangeLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 18, color: onPressed == null ? Colors.grey : kOrange),
        ),
      ),
    );
  }
}
