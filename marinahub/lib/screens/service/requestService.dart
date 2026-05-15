import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/screens/service/myServices.dart';

/// Pass [booking] when navigating from a booking card.
/// Leave null for walk-in / no-booking mode (e.g. just stopping for fuel).
class requestService extends StatefulWidget {
  final Map<String, dynamic>? booking;
  const requestService({super.key, this.booking});

  @override
  State<requestService> createState() => _requestServiceState();
}

class _requestServiceState extends State<requestService> {
  // ── Colours ──────────────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0D1421);
  static const Color navyCard = Color(0xFF142238);
  static const Color navyCardSoft = Color(0xFF1A2940);
  static const Color gold = Color(0xFFD4A95E);
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color dividerColor = Color(0xFF243044);

  // ── State ────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> categories = [];
  String selectedCategory = '';
  bool loadingCategories = true;
  List<dynamic> services = [];
  bool loadingServices = false;
  String? error;
  Position? userPosition;

  // Sheet state
  double sheetQuantity = 1;
  String sheetTiming = 'asap';
  DateTime? scheduledAt;
  bool sheetSubmitting = false;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController locationNoteController = TextEditingController();
  Map<String, dynamic> activeService = {};

  // ── Active booking (auto-fetched on load, or passed in) ─────────────────────
  Map<String, dynamic>? _activeBooking;
  bool _loadingBooking = true;

  bool get hasBooking => _activeBooking != null;

  String get _bookingId => _activeBooking?['id'] as String? ?? '';

  String get _berthLabel =>
      _activeBooking?['berth']?['name'] as String? ??
      _activeBooking?['berth_name'] as String? ??
      '';

  String get _marinaLabel =>
      _activeBooking?['marina']?['name'] as String? ??
      _activeBooking?['marina_name'] as String? ??
      '';

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // If booking passed in (from booking card), use it directly.
    // Otherwise fetch from API — user may be checked in via nav bar.
    if (widget.booking != null) {
      _activeBooking = widget.booking;
      _loadingBooking = false;
    } else {
      _fetchActiveBooking();
    }
    initLocationAndCategories();
  }

  @override
  void dispose() {
    notesController.dispose();
    locationNoteController.dispose();
    super.dispose();
  }

  // ── Scaling helpers ──────────────────────────────────────────────────────────
  double scale(BuildContext ctx) =>
      (MediaQuery.of(ctx).size.width / 375.0).clamp(0.75, 1.6);
  double fs(BuildContext ctx, double base) =>
      (base * scale(ctx)).clamp(base * 0.75, base * 1.5);
  double d(BuildContext ctx, double base) =>
      (base * scale(ctx)).clamp(base * 0.75, base * 1.6);
  double px(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 360 ? 12.0 : 20.0;
  bool isWide(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 768;

  // ── Fetch active booking (checked_in or ongoing confirmed) ──────────────────
  Future<void> _fetchActiveBooking() async {
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/bookings/my');
      final bookings = res.data['bookings'] as List? ?? [];
      final now = DateTime.now();

      // Priority: checked_in first, then confirmed within date range
      Map<String, dynamic>? found;
      for (final b in bookings) {
        final status = b['status'] as String? ?? '';
        if (status == 'checked_in') {
          found = b;
          break;
        }
        if (status == 'confirmed') {
          final from = DateTime.tryParse(b['from_date'] ?? '')?.toLocal();
          final to = DateTime.tryParse(b['to_date'] ?? '')?.toLocal();
          if (from != null &&
              to != null &&
              !now.isBefore(from) &&
              !now.isAfter(to)) {
            found ??= b; // take first match, prefer checked_in
          }
        }
      }

      if (mounted)
        setState(() {
          _activeBooking = found;
          _loadingBooking = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingBooking = false);
    }
  }

  // ── Location ─────────────────────────────────────────────────────────────────
  Future<void> initLocationAndCategories() async {
    await getLocation();
    await loadCategories();
  }

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => userPosition = pos);
    } catch (_) {}
  }

  // ── Data loading ─────────────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    if (mounted) setState(() => loadingCategories = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/services/categories');
      final fetched = List<Map<String, dynamic>>.from(
        (res.data['categories'] ?? []).map(
          (c) => {
            'key': c['key'],
            'label': labelFor(c['key'] as String),
            'icon': iconFor(c['key'] as String?),
            'unit': c['unit'],
          },
        ),
      );
      if (mounted) {
        setState(() {
          categories = fetched;
          if (fetched.isNotEmpty)
            selectedCategory = fetched.first['key'] as String;
        });
      }
      if (fetched.isNotEmpty)
        await loadServices(fetched.first['key'] as String);
    } catch (e) {
      dioErrorManager(e);
      if (mounted) setState(() => error = "Couldn't load categories");
    } finally {
      if (mounted) setState(() => loadingCategories = false);
    }
  }

  Future<void> loadServices(String category) async {
    if (mounted)
      setState(() {
        loadingServices = true;
        error = null;
      });
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/services/category/$category');
      List fetched = res.data['services'] ?? [];

      if (userPosition != null) {
        fetched.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            (a['marina_latitude'] ?? 0).toDouble(),
            (a['marina_longitude'] ?? 0).toDouble(),
          );
          final distB = Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            (b['marina_latitude'] ?? 0).toDouble(),
            (b['marina_longitude'] ?? 0).toDouble(),
          );
          return distA.compareTo(distB);
        });
      }
      if (mounted) setState(() => services = fetched);
    } catch (e) {
      dioErrorManager(e);
      if (mounted) setState(() => error = "Couldn't load services");
    } finally {
      if (mounted) setState(() => loadingServices = false);
    }
  }

  void onCategoryTap(String key) {
    if (selectedCategory == key) return;
    setState(() => selectedCategory = key);
    loadServices(key);
  }

  // ── Distance helper ───────────────────────────────────────────────────────────
  String getDistance(dynamic service) {
    if (userPosition == null)
      return service['marina_location'] as String? ?? '';
    final lat = (service['marina_latitude'] ?? 0).toDouble();
    final lng = (service['marina_longitude'] ?? 0).toDouble();
    if (lat == 0 && lng == 0)
      return service['marina_location'] as String? ?? '';
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      lat,
      lng,
    );
    return meters < 1000
        ? '${meters.toStringAsFixed(0)} m away'
        : '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  // ── Label / icon maps ─────────────────────────────────────────────────────────
  String labelFor(String key) {
    const labels = {
      'fuel': 'Fuel',
      'cleaning': 'Cleaning',
      'repairs': 'Repairs',
      'maintenance': 'Maintenance',
      'provisioning': 'Provisioning',
      'waste_disposal': 'Waste',
      'electricity': 'Electricity',
      'water': 'Water',
      'other': 'Other',
    };
    return labels[key] ?? key[0].toUpperCase() + key.substring(1);
  }

  IconData iconFor(String? key) {
    switch (key) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'repairs':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      case 'provisioning':
        return Icons.shopping_basket;
      case 'waste_disposal':
        return Icons.delete_outline;
      case 'electricity':
        return Icons.bolt;
      case 'water':
        return Icons.water_drop;
      default:
        return Icons.miscellaneous_services;
    }
  }

  List<double> quickAmountsFor(String unit) {
    final u = unit.toLowerCase();
    if (u == 'l' || u == 'liter' || u == 'liters') return [50, 100, 200, 300];
    if (u == 'kwh') return [10, 20, 50, 100];
    if (u == 'kg') return [5, 10, 20];
    return [1, 2, 5, 10];
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> submitOrder() async {
    // Walk-in: location note required
    if (!hasBooking && locationNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe where your boat is'),
          backgroundColor: const Color(0xFF1A2940),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    // Scheduled: must pick a date/time
    if (sheetTiming == 'scheduled' && scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please pick a date and time for scheduling'),
          backgroundColor: const Color(0xFF1A2940),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (mounted) setState(() => sheetSubmitting = true);
    try {
      // ✅ Use 'id' — the field the API returns, not 'service_id'
      final String serviceId = activeService['service_id'] as String? ?? '';
      final String currency = activeService['currency'] as String? ?? 'NOK';
      final double pricePerUnit = (activeService['price_per_unit'] ?? 0)
          .toDouble();
      final double total = sheetQuantity * pricePerUnit;

      final Map<String, dynamic> body = {
        'service_id': serviceId,
        'quantity': sheetQuantity,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'requested_time': sheetTiming,
        'scheduled_at': sheetTiming == 'scheduled' && scheduledAt != null
            ? scheduledAt!.toUtc().toIso8601String()
            : null,
        // ✅ Tell the backend which berth — booking_id if we have one,
        //    otherwise the user-typed location note (walk-in mode)
        if (hasBooking) 'booking_id': _bookingId,
        if (!hasBooking && locationNoteController.text.trim().isNotEmpty)
          'location_note': locationNoteController.text.trim(),
      };

      final dio = await MyDio().getDio();
      // Add this temporarily before dio.post
      debugPrint('=== serviceId: $serviceId');
      debugPrint('=== activeService keys: ${activeService.keys.toList()}');
      debugPrint('=== activeService: $activeService');

      await dio.post('/service-orders', data: body);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyServiceOrdersScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Service requested — ${total.toStringAsFixed(0)} $currency',
                  style: const TextStyle(color: textPrimary),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A2940),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => sheetSubmitting = false);
    }
  }

  // ── Schedule date/time picker ─────────────────────────────────────────────────
  Future<void> pickScheduledDateTime(StateSetter setSheetState) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: gold,
            onPrimary: navy,
            surface: navyCard,
            onSurface: textPrimary,
          ),
          dialogBackgroundColor: navy,
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: gold,
            onPrimary: navy,
            surface: navyCard,
            onSurface: textPrimary,
          ),
          dialogBackgroundColor: navy,
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setSheetState(() => scheduledAt = picked);
    setState(() => scheduledAt = picked);
  }

  String _formatScheduled(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:$m $p';
  }

  // ── Sheet ─────────────────────────────────────────────────────────────────────
  void openServiceSheet(Map<String, dynamic> service) {
    activeService = service;
    sheetQuantity = quickAmountsFor(service['unit'] as String? ?? '').first;
    sheetTiming = 'asap';
    scheduledAt = null;
    notesController.clear();
    // Don't clear locationNoteController — user may have typed it already

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
            final String unit = activeService['unit'] as String? ?? '';
            final String currency =
                activeService['currency'] as String? ?? 'NOK';
            final double pricePerUnit = (activeService['price_per_unit'] ?? 0)
                .toDouble();
            final double total = sheetQuantity * pricePerUnit;
            final List<double> quickAmounts = quickAmountsFor(unit);

            final content = Container(
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(d(ctx, 24)),
                ),
              ),
              child: Column(
                children: [
                  // drag handle
                  Container(
                    margin: EdgeInsets.only(top: d(ctx, 12), bottom: d(ctx, 6)),
                    width: d(ctx, 36),
                    height: d(ctx, 4),
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(d(ctx, 2)),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        px(ctx),
                        d(ctx, 8),
                        px(ctx),
                        d(ctx, 20) + viewInsets,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSheetHeader(ctx, unit, currency, pricePerUnit),
                          SizedBox(height: d(ctx, 16)),

                          // ── Berth context banner / walk-in field ──────────
                          if (hasBooking)
                            _buildBerthBanner(ctx)
                          else
                            _buildWalkInField(ctx),

                          SizedBox(height: d(ctx, 20)),
                          buildSectionLabel(ctx, 'QUANTITY'),
                          SizedBox(height: d(ctx, 10)),
                          buildQuantityRow(ctx, setSheetState, unit),
                          SizedBox(height: d(ctx, 12)),
                          buildQuickAmounts(
                            ctx,
                            setSheetState,
                            quickAmounts,
                            unit,
                          ),
                          SizedBox(height: d(ctx, 24)),
                          buildSectionLabel(ctx, 'TIMING'),
                          SizedBox(height: d(ctx, 10)),
                          buildTimingToggle(ctx, setSheetState),
                          // Date picker — only when scheduled is selected
                          if (sheetTiming == 'scheduled') ...[
                            SizedBox(height: d(ctx, 12)),
                            _buildSchedulePicker(ctx, setSheetState),
                          ],
                          SizedBox(height: d(ctx, 24)),
                          buildSectionLabel(ctx, 'NOTES (OPTIONAL)'),
                          SizedBox(height: d(ctx, 10)),
                          buildNotesField(ctx),
                          SizedBox(height: d(ctx, 20)),
                        ],
                      ),
                    ),
                  ),
                  buildBottomBar(ctx, total, currency),
                ],
              ),
            );

            if (isWide(ctx)) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (_, __) => content,
                  ),
                ),
              );
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, __) => content,
            );
          },
        );
      },
    );
  }

  // ── Berth context banner (booking mode) ───────────────────────────────────────
  Widget _buildBerthBanner(BuildContext ctx) {
    final label = [
      if (_berthLabel.isNotEmpty) 'Berth $_berthLabel',
      if (_marinaLabel.isNotEmpty) _marinaLabel,
    ].join(' — ');

    return Container(
      padding: EdgeInsets.all(d(ctx, 12)),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(d(ctx, 12)),
        border: Border.all(color: gold.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.anchor_rounded, color: gold, size: d(ctx, 16)),
          SizedBox(width: d(ctx, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to your berth',
                  style: TextStyle(
                    color: gold,
                    fontSize: fs(ctx, 11.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  SizedBox(height: d(ctx, 2)),
                  Text(
                    label,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: fs(ctx, 12),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Walk-in location field (no booking) ───────────────────────────────────────
  Widget _buildWalkInField(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: d(ctx, 10),
            vertical: d(ctx, 8),
          ),
          decoration: BoxDecoration(
            color: navyCardSoft,
            borderRadius: BorderRadius.circular(d(ctx, 10)),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: textSecondary,
                size: d(ctx, 14),
              ),
              SizedBox(width: d(ctx, 7)),
              Expanded(
                child: Text(
                  'No active booking — tell us where your boat is so staff can find you.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: fs(ctx, 11.5),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: d(ctx, 12)),
        buildSectionLabel(ctx, 'WHERE IS YOUR BOAT? *'),
        SizedBox(height: d(ctx, 8)),
        Container(
          decoration: BoxDecoration(
            color: navyCard,
            borderRadius: BorderRadius.circular(d(ctx, 14)),
            border: Border.all(color: dividerColor, width: 0.5),
          ),
          child: TextField(
            controller: locationNoteController,
            style: TextStyle(color: textPrimary, fontSize: fs(ctx, 14)),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Berth A-12, fuel dock, yard spot 6',
              hintStyle: TextStyle(color: textSecondary, fontSize: fs(ctx, 13)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: d(ctx, 14),
                vertical: d(ctx, 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Schedule date/time picker widget ──────────────────────────────────────────
  Widget _buildSchedulePicker(BuildContext ctx, StateSetter setSheetState) {
    return GestureDetector(
      onTap: () => pickScheduledDateTime(setSheetState),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: d(ctx, 14),
          vertical: d(ctx, 13),
        ),
        decoration: BoxDecoration(
          color: navyCard,
          borderRadius: BorderRadius.circular(d(ctx, 12)),
          border: Border.all(
            color: scheduledAt != null ? gold.withOpacity(0.5) : dividerColor,
            width: scheduledAt != null ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: scheduledAt != null ? gold : textSecondary,
              size: d(ctx, 18),
            ),
            SizedBox(width: d(ctx, 10)),
            Expanded(
              child: Text(
                scheduledAt != null
                    ? _formatScheduled(scheduledAt!)
                    : 'Tap to pick date & time',
                style: TextStyle(
                  color: scheduledAt != null ? textPrimary : textSecondary,
                  fontSize: fs(ctx, 14),
                  fontWeight: scheduledAt != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (scheduledAt != null)
              GestureDetector(
                onTap: () => setSheetState(() => scheduledAt = null),
                child: Icon(
                  Icons.close_rounded,
                  color: textSecondary,
                  size: d(ctx, 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sheet sub-widgets (unchanged from your original) ─────────────────────────
  Widget buildSheetHeader(
    BuildContext ctx,
    String unit,
    String currency,
    double pricePerUnit,
  ) {
    final String name = activeService['name'] as String? ?? '';
    final String description = activeService['description'] as String? ?? '';
    final String marinaName = activeService['marina_name'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: textPrimary,
            fontSize: fs(ctx, 22),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (marinaName.isNotEmpty) ...[
          SizedBox(height: d(ctx, 6)),
          Row(
            children: [
              Icon(
                Icons.anchor_rounded,
                color: textSecondary,
                size: d(ctx, 13),
              ),
              SizedBox(width: d(ctx, 4)),
              Flexible(
                child: Text(
                  marinaName,
                  style: TextStyle(color: textSecondary, fontSize: fs(ctx, 13)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (description.isNotEmpty) ...[
          SizedBox(height: d(ctx, 8)),
          Text(
            description,
            style: TextStyle(
              color: textSecondary,
              fontSize: fs(ctx, 13),
              height: 1.5,
            ),
          ),
        ],
        SizedBox(height: d(ctx, 12)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: d(ctx, 12),
            vertical: d(ctx, 7),
          ),
          decoration: BoxDecoration(
            color: gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(d(ctx, 10)),
            border: Border.all(color: gold.withOpacity(0.3)),
          ),
          child: Text(
            '$pricePerUnit $currency${unit.isNotEmpty ? ' / $unit' : ''}',
            style: TextStyle(
              color: gold,
              fontSize: fs(ctx, 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSectionLabel(BuildContext ctx, String text) {
    return Text(
      text,
      style: TextStyle(
        color: textSecondary,
        fontSize: fs(ctx, 10.5),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget buildQuantityRow(
    BuildContext ctx,
    StateSetter setSheetState,
    String unit,
  ) {
    final double btnSize = d(ctx, 42).clamp(36.0, 54.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: d(ctx, 6), vertical: d(ctx, 6)),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(d(ctx, 14)),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          buildQuantityButton(ctx, Icons.remove_rounded, btnSize, () {
            if (sheetQuantity > 1) setSheetState(() => sheetQuantity -= 1);
          }),
          Expanded(
            child: Text(
              '${sheetQuantity.toStringAsFixed(sheetQuantity.truncateToDouble() == sheetQuantity ? 0 : 1)}'
              '${unit.isNotEmpty ? ' $unit' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: fs(ctx, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          buildQuantityButton(ctx, Icons.add_rounded, btnSize, () {
            setSheetState(() => sheetQuantity += 1);
          }),
        ],
      ),
    );
  }

  Widget buildQuantityButton(
    BuildContext ctx,
    IconData icon,
    double size,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: navyCardSoft,
          borderRadius: BorderRadius.circular(d(ctx, 10)),
        ),
        child: Icon(icon, color: gold, size: d(ctx, 18)),
      ),
    );
  }

  Widget buildQuickAmounts(
    BuildContext ctx,
    StateSetter setSheetState,
    List<double> amounts,
    String unit,
  ) {
    return Row(
      children: amounts.map((amt) {
        final selected = sheetQuantity == amt;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: amt != amounts.last ? d(ctx, 8) : 0,
            ),
            child: GestureDetector(
              onTap: () => setSheetState(() => sheetQuantity = amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(vertical: d(ctx, 10)),
                decoration: BoxDecoration(
                  color: selected ? gold.withOpacity(0.15) : navyCard,
                  borderRadius: BorderRadius.circular(d(ctx, 10)),
                  border: Border.all(
                    color: selected ? gold.withOpacity(0.5) : dividerColor,
                    width: selected ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  '${amt.toStringAsFixed(0)}${unit.isNotEmpty ? ' $unit' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? gold : textSecondary,
                    fontSize: fs(ctx, 12),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildTimingToggle(BuildContext ctx, StateSetter setSheetState) {
    return Container(
      padding: EdgeInsets.all(d(ctx, 4)),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(d(ctx, 14)),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          buildTimingOption(
            ctx,
            setSheetState,
            'asap',
            'As soon as possible',
            Icons.bolt_rounded,
          ),
          buildTimingOption(
            ctx,
            setSheetState,
            'scheduled',
            'Schedule for later',
            Icons.event_rounded,
          ),
        ],
      ),
    );
  }

  Widget buildTimingOption(
    BuildContext ctx,
    StateSetter setSheetState,
    String key,
    String label,
    IconData icon,
  ) {
    final selected = sheetTiming == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() {
          sheetTiming = key;
          if (key == 'asap') scheduledAt = null; // clear when switching back
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: d(ctx, 12)),
          decoration: BoxDecoration(
            color: selected ? gold : Colors.transparent,
            borderRadius: BorderRadius.circular(d(ctx, 10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? navy : textSecondary,
                size: d(ctx, 18),
              ),
              SizedBox(height: d(ctx, 4)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? navy : textSecondary,
                  fontSize: fs(ctx, 11).clamp(9.0, 14.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNotesField(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(d(ctx, 14)),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: TextField(
        controller: notesController,
        style: TextStyle(color: textPrimary, fontSize: fs(ctx, 14)),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'e.g. diesel, port side tank, please knock twice',
          hintStyle: TextStyle(color: textSecondary, fontSize: fs(ctx, 13)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: d(ctx, 14),
            vertical: d(ctx, 12),
          ),
        ),
      ),
    );
  }

  Widget buildBottomBar(BuildContext ctx, double total, String currency) {
    return Container(
      padding: EdgeInsets.fromLTRB(px(ctx), d(ctx, 16), px(ctx), d(ctx, 24)),
      decoration: BoxDecoration(
        color: navyCard,
        border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: TextStyle(color: textSecondary, fontSize: fs(ctx, 11)),
                ),
                Text(
                  '${total.toStringAsFixed(0)} $currency',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: fs(ctx, 22),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: sheetSubmitting ? null : submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: navy,
                disabledBackgroundColor: gold.withOpacity(0.4),
                padding: EdgeInsets.symmetric(
                  horizontal: d(ctx, 28),
                  vertical: d(ctx, 15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(d(ctx, 14)),
                ),
                elevation: 0,
              ),
              child: sheetSubmitting
                  ? SizedBox(
                      width: d(ctx, 18),
                      height: d(ctx, 18),
                      child: CircularProgressIndicator(
                        color: navy,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Request Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: fs(ctx, 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page body ─────────────────────────────────────────────────────────────────
  Widget buildBody(BuildContext context) {
    if (loadingServices) {
      return const Center(child: CircularProgressIndicator(color: gold));
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(d(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: textSecondary,
                size: d(context, 40),
              ),
              SizedBox(height: d(context, 10)),
              Text(
                error!,
                style: TextStyle(color: textPrimary, fontSize: fs(context, 15)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: d(context, 16)),
              OutlinedButton(
                onPressed: () => loadServices(selectedCategory),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: gold),
                  foregroundColor: gold,
                  padding: EdgeInsets.symmetric(
                    horizontal: d(context, 24),
                    vertical: d(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: textSecondary,
              size: d(context, 44),
            ),
            SizedBox(height: d(context, 10)),
            Text(
              'No services available',
              style: TextStyle(color: textPrimary, fontSize: fs(context, 15)),
            ),
            SizedBox(height: d(context, 4)),
            Text(
              'Try a different category',
              style: TextStyle(color: textSecondary, fontSize: fs(context, 12)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        px(context),
        d(context, 8),
        px(context),
        d(context, 100), // so FAB doesn't cover last card
      ),
      itemCount: services.length,
      itemBuilder: (ctx, i) =>
          buildServiceCard(context, services[i] as Map<String, dynamic>),
    );
  }

  Widget buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final String name = service['name'] as String? ?? '';
    final String price = (service['price_per_unit'] ?? 0).toString();
    final String currency = service['currency'] as String? ?? 'NOK';
    final String unit = service['unit'] as String? ?? '';
    final dynamic eta = service['estimated_minutes'];
    final String mName = service['marina_name'] as String? ?? '';
    final String category = service['category'] as String? ?? '';
    final String distance = getDistance(service);
    final double iconBoxSize = d(context, 48).clamp(38.0, 62.0);
    final double iconSize = d(context, 22).clamp(18.0, 28.0);

    return Padding(
      padding: EdgeInsets.only(bottom: d(context, 10)),
      child: Material(
        color: navyCard,
        borderRadius: BorderRadius.circular(d(context, 16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(d(context, 16)),
          onTap: () => openServiceSheet(service),
          splashColor: gold.withOpacity(0.06),
          highlightColor: gold.withOpacity(0.03),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(d(context, 16)),
              border: Border.all(color: dividerColor, width: 0.5),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: d(context, 14),
              vertical: d(context, 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(d(context, 12)),
                    border: Border.all(
                      color: gold.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(iconFor(category), color: gold, size: iconSize),
                ),
                SizedBox(width: d(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: fs(context, 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (mName.isNotEmpty || distance.isNotEmpty) ...[
                        SizedBox(height: d(context, 3)),
                        Row(
                          children: [
                            Icon(
                              Icons.anchor_rounded,
                              color: textSecondary,
                              size: d(context, 12),
                            ),
                            SizedBox(width: d(context, 4)),
                            if (mName.isNotEmpty)
                              Flexible(
                                child: Text(
                                  mName,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: fs(context, 12),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (distance.isNotEmpty) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: fs(context, 12),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  distance,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: fs(context, 12),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      SizedBox(height: d(context, 6)),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$price $currency${unit.isNotEmpty ? ' / $unit' : ''}',
                              style: TextStyle(
                                color: gold,
                                fontSize: fs(context, 13),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (eta != null) ...[
                            SizedBox(width: d(context, 10)),
                            Icon(
                              Icons.schedule_rounded,
                              color: textSecondary,
                              size: d(context, 12),
                            ),
                            SizedBox(width: d(context, 3)),
                            Text(
                              '~$eta min',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: fs(context, 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: d(context, 8)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: d(context, 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isTabletOrUp(double w) => w >= 600;

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget buildHeader(BuildContext context) {
    final isBig = isTabletOrUp(MediaQuery.of(context).size.width);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        px(context),
        d(context, 20),
        px(context),
        d(context, 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: isBig ? 32.0 : 26.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: d(context, 6)),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: d(context, 6)),
              Expanded(
                child: Text(
                  hasBooking
                      ? 'Ordering for '
                            '${_berthLabel.isNotEmpty ? 'Berth $_berthLabel' : _marinaLabel}'
                      : userPosition != null
                      ? 'Sorted by distance · walk-in mode'
                      : 'Available near you · walk-in mode',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: fs(context, 12),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category strip ────────────────────────────────────────────────────────────
  Widget buildCategoryStrip(BuildContext context) {
    final double chipHeight = d(context, 88).clamp(72.0, 110.0);
    final double chipWidth = d(context, 78).clamp(64.0, 100.0);
    final double iconSize = d(context, 22).clamp(18.0, 28.0);
    final double labelSize = fs(context, 11).clamp(9.0, 14.0);

    return SizedBox(
      height: chipHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: d(context, 16),
          vertical: d(context, 10),
        ),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final selected = selectedCategory == cat['key'];
          return Padding(
            padding: EdgeInsets.only(right: d(context, 10)),
            child: GestureDetector(
              onTap: () => onCategoryTap(cat['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: chipWidth,
                decoration: BoxDecoration(
                  color: selected ? gold : navyCard,
                  borderRadius: BorderRadius.circular(d(context, 14)),
                  border: Border.all(
                    color: selected ? gold : dividerColor,
                    width: selected ? 1.5 : 0.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: gold.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: selected ? navy : textPrimary,
                      size: iconSize,
                    ),
                    SizedBox(height: d(context, 6)),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? navy : textSecondary,
                        fontSize: labelSize,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(context),
            if (loadingCategories)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: gold)),
              )
            else ...[
              buildCategoryStrip(context),
              Container(height: 0.5, color: dividerColor),
              Expanded(child: buildBody(context)),
            ],
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyServiceOrdersScreen()),
          ),
          backgroundColor: gold,
          foregroundColor: navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.receipt_long_rounded, size: 20),
          label: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
