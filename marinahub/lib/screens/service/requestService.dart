import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dio/myDio.dart';

class requestService extends StatefulWidget {
  const requestService({super.key});

  @override
  State<requestService> createState() => _requestServiceState();
}

class _requestServiceState extends State<requestService> {
  static const Color navy = Color(0xFF0D1421);
  static const Color navyCard = Color(0xFF142238);
  static const Color gold = Color(0xFFD4A95E);
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color divider = Color(0xFF243044);

  List<Map<String, dynamic>> categories = [];
  String selectedCategory = '';
  bool loadingCategories = true;
  List<dynamic> services = [];
  bool loadingServices = false;
  String? error;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _initLocationAndCategories();
  }

  Future<void> _initLocationAndCategories() async {
    await _getLocation();
    await loadCategories();
  }

  Future<void> _getLocation() async {
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
      setState(() => userPosition = pos);
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    setState(() => loadingCategories = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/services/categories');
      final fetched = List<Map<String, dynamic>>.from(
        (res.data['categories'] ?? []).map(
          (c) => {
            'key': c['key'],
            'label': _labelFor(c['key']),
            'icon': _iconFor(c['key']),
            'unit': c['unit'],
          },
        ),
      );
      setState(() {
        categories = fetched;
        if (fetched.isNotEmpty) selectedCategory = fetched.first['key'];
      });
      if (fetched.isNotEmpty) await loadServices(fetched.first['key']);
    } catch (e) {
      dioErrorManager(e);
      setState(() => error = "Couldn't load categories");
    } finally {
      setState(() => loadingCategories = false);
    }
  }

  Future<void> loadServices(String category) async {
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

      setState(() => services = fetched);
    } catch (e) {
      dioErrorManager(e);
      setState(() => error = "Couldn't load services");
    } finally {
      setState(() => loadingServices = false);
    }
  }

  void onCategoryTap(String key) {
    if (selectedCategory == key) return;
    setState(() => selectedCategory = key);
    loadServices(key);
  }

  String getDistance(dynamic service) {
    if (userPosition == null) return service['marina_location'] ?? '';
    final lat = (service['marina_latitude'] ?? 0).toDouble();
    final lng = (service['marina_longitude'] ?? 0).toDouble();
    if (lat == 0 && lng == 0) return service['marina_location'] ?? '';
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      lat,
      lng,
    );
    final distStr = meters < 1000
        ? '${meters.toStringAsFixed(0)} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    return '$distStr away';
  }

  String _labelFor(String key) {
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

  IconData _iconFor(String? key) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (loadingCategories)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: gold)),
              )
            else ...[
              _buildCategoryStrip(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.3,
          ),
          children: [
            TextSpan(
              text: 'Request ',
              style: TextStyle(color: textPrimary),
            ),
            TextSpan(
              text: 'Service',
              style: TextStyle(color: gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onCategoryTap(cat['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 78,
                decoration: BoxDecoration(
                  color: selected ? gold : navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? gold : divider,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: selected ? navy : textPrimary,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['label'],
                      style: TextStyle(
                        color: selected ? navy : textSecondary,
                        fontSize: 11,
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

  Widget _buildBody() {
    if (loadingServices)
      return const Center(child: CircularProgressIndicator(color: gold));
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: textSecondary, size: 36),
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: textPrimary, fontSize: 15),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => loadServices(selectedCategory),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: gold),
                  foregroundColor: gold,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: textSecondary, size: 40),
            SizedBox(height: 8),
            Text(
              'No services available',
              style: TextStyle(color: textPrimary, fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different category',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: services.length,
      itemBuilder: (_, i) => _buildServiceCard(services[i]),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name = service['name'] ?? '';
    final price = (service['price_per_unit'] ?? 0).toString();
    final currency = service['currency'] ?? 'NOK';
    final unit = service['unit'] ?? '';
    final eta = service['estimated_minutes'];
    final marinaName = service['marina_name'] ?? '';
    final category = service['category'];
    final distance = getDistance(service);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: navyCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _ServiceRequestSheet(service: service),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2940),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(category), color: gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (marinaName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.anchor,
                              color: textSecondary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              marinaName,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (distance.isNotEmpty) ...[
                              const Text(
                                ' · ',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                distance,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '$price $currency${unit.isNotEmpty ? ' / $unit' : ''}',
                            style: const TextStyle(
                              color: gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (eta != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.schedule,
                              color: textSecondary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~$eta min',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bottom sheet — request form
// ─────────────────────────────────────────────────────────
class _ServiceRequestSheet extends StatefulWidget {
  final Map<String, dynamic> service;
  const _ServiceRequestSheet({required this.service});

  @override
  State<_ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends State<_ServiceRequestSheet> {
  static const Color navy = Color(0xFF0D1421);
  static const Color navyCard = Color(0xFF142238);
  static const Color navyCardSoft = Color(0xFF1A2940);
  static const Color gold = Color(0xFFD4A95E);
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color divider = Color(0xFF243044);

  double quantity = 1;
  String timing = 'asap';
  bool submitting = false;
  final TextEditingController notesController = TextEditingController();

  double get pricePerUnit => (widget.service['price_per_unit'] ?? 0).toDouble();
  String get currency => widget.service['currency'] ?? 'NOK';
  String get unit => widget.service['unit'] ?? '';
  double get total => quantity * pricePerUnit;
  String get serviceId => widget.service['service_id'] ?? '';
  String get marinaId => widget.service['marina_id'] ?? '';

  List<double> get quickAmounts {
    final u = unit.toLowerCase();
    if (u == 'l' || u == 'liter' || u == 'liters') return [50, 100, 200, 300];
    if (u == 'kwh') return [10, 20, 50, 100];
    if (u == 'kg') return [5, 10, 20];
    return [1, 2, 5, 10];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> submitOrder() async {
    setState(() => submitting = true);
    try {
      final dio = await MyDio().getDio();
      await dio.post(
        '/services/order',
        data: {
          'service_id': serviceId,
          'marina_id': marinaId,
          'quantity': quantity,
          'notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          'requested_time': timing,
          'scheduled_at': null,
        },
      );

      if (mounted) {
        Navigator.pop(context); // close sheet

        // Navigate to Bookings tab (index 2)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => DashboardScreen(initialTab: 2),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Service requested — ${total.toStringAsFixed(0)} $currency',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A2940),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHeader(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Quantity'),
                    const SizedBox(height: 10),
                    _buildQuantityRow(),
                    const SizedBox(height: 12),
                    _buildQuickAmounts(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Timing'),
                    const SizedBox(height: 10),
                    _buildTimingToggle(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Notes (optional)'),
                    const SizedBox(height: 10),
                    _buildNotesField(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    final name = widget.service['name'] ?? '';
    final description = widget.service['description'] ?? '';
    final marinaName = widget.service['marina_name'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (marinaName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.anchor, color: textSecondary, size: 13),
              const SizedBox(width: 4),
              Text(
                marinaName,
                style: const TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
        if (description.toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gold.withOpacity(0.35)),
          ),
          child: Text(
            '$pricePerUnit $currency${unit.isNotEmpty ? ' / $unit' : ''}',
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );

  Widget _buildQuantityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _quantityButton(Icons.remove, () {
            if (quantity > 1) setState(() => quantity -= 1);
          }),
          Expanded(
            child: Text(
              '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)}${unit.isNotEmpty ? ' $unit' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _quantityButton(Icons.add, () => setState(() => quantity += 1)),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: navyCardSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textPrimary, size: 20),
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickAmounts.map((amt) {
        final isSelected = quantity == amt;
        return GestureDetector(
          onTap: () => setState(() => quantity = amt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? gold : navyCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? gold : divider),
            ),
            child: Text(
              '${amt.toStringAsFixed(0)}${unit.isNotEmpty ? ' $unit' : ''}',
              style: TextStyle(
                color: isSelected ? navy : textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _timingOption('asap', 'As soon as possible', Icons.bolt),
          _timingOption('scheduled', 'Schedule for later', Icons.event),
        ],
      ),
    );
  }

  Widget _timingOption(String key, String label, IconData icon) {
    final selected = timing == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => timing = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? navy : textSecondary, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? navy : textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: notesController,
        style: const TextStyle(color: textPrimary, fontSize: 14),
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'e.g. diesel, port side tank',
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: navyCard,
        border: Border(top: BorderSide(color: divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                Text(
                  '${total.toStringAsFixed(0)} $currency',
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: submitting ? null : submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: navy,
                disabledBackgroundColor: gold.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D1421),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Request Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
