import 'package:flutter/material.dart';
import '../../controllers/community_activity_controller.dart';
import '../../models/community_activity.dart';
import '../../models/sponsorship.dart';
import '../../models/sponsorship_product.dart';
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

  bool _isLoadingSponsors = true;
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
            'Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activity.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  activity.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 10),
              Text(
                activity.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
            const SizedBox(height: 16),
            _infoRow(
              Icons.calendar_today,
              activity.eventDate != null
                  ? _formatDate(activity.eventDate!)
                  : 'TBA',
            ),
            if (activity.location != null)
              _infoRow(Icons.location_on_outlined, activity.location!),
            _infoRow(
              Icons.people_outline,
              '${activity.registeredCount}${activity.maxParticipants != null ? ' / ${activity.maxParticipants}' : ''} registered',
            ),
            const SizedBox(height: 16),
            _buildSponsorshipSection(),
            const SizedBox(height: 24),
            // Register / Cancel button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFull && !activity.isRegistered
                    ? null
                    : () async {
                        if (activity.isRegistered) {
                          await controller.cancelRegistration(activity);
                        } else {
                          await controller.register(activity);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
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
                      ? 'Cancel Registration'
                      : isFull
                      ? 'Activity Full'
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

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    ),
  );

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _buildSponsorshipSection() {
    if (_isLoadingSponsors) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sponsors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sponsorships',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ..._sponsors.map(_buildSponsorCard),
      ],
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
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
}

class _SponsorWithProducts {
  final Sponsorship sponsor;
  final List<SponsorshipProduct> products;

  const _SponsorWithProducts({required this.sponsor, required this.products});
}
