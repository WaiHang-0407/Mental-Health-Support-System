import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/community_activity_controller.dart';
import '../../models/community_activity.dart';
import '../../models/sponsorship.dart';
import '../../models/sponsorship_product.dart';
import '../../repositories/patient_table_repository.dart';
import '../../repositories/sponsorship_products_table_repository.dart';
import '../../repositories/sponsorships_table_repository.dart';
import '../../widgets/gradient_background.dart';

class CommunityActivityDetailPage extends StatefulWidget {
  final CommunityActivity activity;
  final CommunityActivityController controller;

  const CommunityActivityDetailPage({
    super.key,
    required this.activity,
    required this.controller,
  });

  @override
  State<CommunityActivityDetailPage> createState() =>
      _CommunityActivityDetailPageState();
}

class _CommunityActivityDetailPageState
    extends State<CommunityActivityDetailPage> {
  final SponsorshipsTableRepository _sponsorshipsTable =
      SponsorshipsTableRepository();
  final SponsorshipProductsTableRepository _productsTable =
      SponsorshipProductsTableRepository();
  final PatientRepository _patientRepository = PatientRepository();

  bool _isLoadingSponsors = true;
  bool _isSubmittingRegistration = false;
  List<_SponsorWithProducts> _sponsors = [];

  CommunityActivity get activity => widget.activity;
  CommunityActivityController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadSponsorships();
  }

  Future<void> _loadSponsorships() async {
    try {
      final sponsorRows = await _sponsorshipsTable.getVisibleByActivity(
        activity.id,
      );
      final sponsors = sponsorRows
          .map((row) => Sponsorship.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      final sponsorsWithProducts = <_SponsorWithProducts>[];
      for (final sponsor in sponsors) {
        final sponsorId = sponsor.id;
        if (sponsorId == null) continue;

        final productRows = await _productsTable.getVisibleBySponsorship(
          sponsorId,
        );
        final products = productRows
            .map(
              (row) =>
                  SponsorshipProduct.fromMap(Map<String, dynamic>.from(row)),
            )
            .toList();

        sponsorsWithProducts.add(
          _SponsorWithProducts(sponsor: sponsor, products: products),
        );
      }

      if (!mounted) return;
      setState(() {
        _sponsors = sponsorsWithProducts;
        _isLoadingSponsors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSponsors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull =
        activity.maxParticipants != null &&
        activity.registeredCount >= activity.maxParticipants!;
    final isRegistrationClosed =
        activity.registrationDeadline != null &&
        activity.registrationDeadline!.isBefore(DateTime.now());

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24, width: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Activity Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusChip(
                        _activityStatusLabel(),
                        Icons.event_available,
                      ),
                      if (activity.isRegistered)
                        _statusChip('Registered', Icons.check_circle_outline),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (activity.description != null &&
                      activity.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      activity.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Schedule',
              child: Column(
                children: [
                  _detailTile(
                    Icons.calendar_today_outlined,
                    'Activity date',
                    activity.eventDate != null
                        ? _formatDate(activity.eventDate!)
                        : 'To be announced',
                  ),
                  _detailTile(
                    Icons.how_to_reg_outlined,
                    'Registration deadline',
                    activity.registrationDeadline != null
                        ? _formatDate(activity.registrationDeadline!)
                        : _fallbackDeadlineText(),
                  ),
                  _detailTile(
                    Icons.schedule_outlined,
                    'Registration status',
                    _registrationStatusLabel(isFull),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Location and Capacity',
              child: Column(
                children: [
                  _detailTile(
                    Icons.location_on_outlined,
                    'Venue',
                    activity.location?.trim().isNotEmpty == true
                        ? activity.location!
                        : 'Venue to be announced',
                  ),
                  _detailTile(
                    Icons.people_outline,
                    'Participants',
                    '${activity.registeredCount}${activity.maxParticipants != null ? ' / ${activity.maxParticipants}' : ''} registered',
                  ),
                  _detailTile(
                    Icons.event_seat_outlined,
                    'Available spots',
                    _spotsText(isFull),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Sponsorships',
              child: _buildSponsorshipSection(),
            ),
            const SizedBox(height: 14),
            Text(
              'Created ${_formatDate(activity.createdAt)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmittingRegistration ||
                        ((isFull || isRegistrationClosed) &&
                            !activity.isRegistered)
                    ? null
                    : _handleRegistrationAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activity.isRegistered
                      ? Colors.redAccent.withValues(alpha: 0.8)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  activity.isRegistered
                      ? _isSubmittingRegistration
                            ? 'Cancelling...'
                            : 'Cancel Registration'
                      : isRegistrationClosed
                      ? 'Registration Closed'
                      : isFull
                      ? 'Activity Full'
                      : _isSubmittingRegistration
                      ? 'Registering...'
                      : 'Register Now',
                  style: TextStyle(
                    color: activity.isRegistered
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistrationAction() async {
    setState(() => _isSubmittingRegistration = true);

    try {
      if (activity.isRegistered) {
        await controller.cancelRegistration(activity);
      } else {
        final hasPhoneNumber = await _ensurePhoneNumber();
        if (!hasPhoneNumber) return;
        await controller.register(activity);
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update registration.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingRegistration = false);
    }
  }

  Future<bool> _ensurePhoneNumber() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to register.')),
      );
      return false;
    }

    final patient = await _patientRepository.getPatientById(userId);
    if (patient?.phoneno?.trim().isNotEmpty == true) return true;

    final phoneNumber = await _askForPhoneNumber();
    if (phoneNumber == null) return false;

    await _patientRepository.updateProfile(userId, {'phoneno': phoneNumber});
    return true;
  }

  Future<String?> _askForPhoneNumber() {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111A33),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              title: const Text('Add phone number'),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We need your phone number before registering you for this community activity.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: const Color(0xFF9FE7D3),
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: 'Enter your phone number',
                      errorText: errorText,
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF9FE7D3),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFB4AB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final phoneNumber = controller.text.trim();
                    if (phoneNumber.length < 7) {
                      setDialogState(() {
                        errorText = 'Enter a valid phone number.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, phoneNumber);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF112650),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save and Register'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHero() {
    final imageUrl = activity.imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _heroPlaceholder(),
            )
          else
            _heroPlaceholder(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    activity.eventDate != null
                        ? _formatDate(activity.eventDate!)
                        : 'Date to be announced',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(
                  _activityStatusLabel(),
                  Icons.circle,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7BC7B5).withValues(alpha: 0.55),
            const Color(0xFF7288F4).withValues(alpha: 0.42),
          ],
        ),
      ),
      child: const Icon(Icons.event_outlined, color: Colors.white, size: 56),
    );
  }

  Widget _sectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, IconData icon, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: compact ? 9 : 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _activityStatusLabel() {
    final now = DateTime.now();
    if (activity.eventDate != null && activity.eventDate!.isBefore(now)) {
      return 'Completed';
    }
    if (activity.registrationDeadline != null &&
        activity.registrationDeadline!.isBefore(now)) {
      return 'Registration Closed';
    }
    return 'Open';
  }

  String _registrationStatusLabel(bool isFull) {
    if (activity.isRegistered) return 'You are registered';
    if (isFull) return 'Activity is full';
    if (activity.registrationDeadline != null &&
        activity.registrationDeadline!.isBefore(DateTime.now())) {
      return 'Registration is closed';
    }
    return 'Registration is open';
  }

  String _fallbackDeadlineText() {
    if (activity.eventDate == null) return 'To be announced';
    final deadline = DateTime(
      activity.eventDate!.year,
      activity.eventDate!.month,
      activity.eventDate!.day,
    ).subtract(const Duration(days: 2));
    return _formatDate(deadline);
  }

  String _spotsText(bool isFull) {
    if (activity.maxParticipants == null) return 'No participant limit';
    if (isFull) return 'No spots left';
    final remaining = activity.maxParticipants! - activity.registeredCount;
    return '$remaining spot${remaining == 1 ? '' : 's'} left';
  }

  Widget _buildSponsorshipSection() {
    if (_isLoadingSponsors) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sponsors.isEmpty) {
      return const Text(
        'No sponsorships are assigned to this activity yet.',
        style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [..._sponsors.map(_buildSponsorCard)],
    );
  }

  Widget _buildSponsorCard(_SponsorWithProducts item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.sponsor.sponsorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (item.sponsor.description != null &&
              item.sponsor.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.sponsor.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (item.products.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...item.products.map(_buildProductTile),
          ],
        ],
      ),
    );
  }

  Widget _buildProductTile(SponsorshipProduct product) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.imageUrl != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openProductImage(product.imageUrl!),
                child: Image.network(
                  product.imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white54,
                size: 22,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.description != null &&
                    product.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openProductImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorWithProducts {
  final Sponsorship sponsor;
  final List<SponsorshipProduct> products;

  const _SponsorWithProducts({required this.sponsor, required this.products});
}
