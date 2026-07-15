import 'package:flutter/material.dart';

import '../../../controllers/listener_controller.dart';
import '../../../models/listener.dart';
import '../../../services/subscription_service.dart';
import '../../../widgets/gradient_background.dart';
import 'listener_waiting.dart';

class ListenerMainPage extends StatefulWidget {
  final Future<void> Function()? onRequestCreated;

  const ListenerMainPage({super.key, this.onRequestCreated});

  @override
  State<ListenerMainPage> createState() => _ListenerMainPageState();
}

class _ListenerMainPageState extends State<ListenerMainPage> {
  final ListenerController _controller = ListenerController();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _hasActiveSubscription = false;
  List<ListenerModel> _listeners = [];

  @override
  void initState() {
    super.initState();
    _loadListeners();
  }

  Future<void> _loadListeners() async {
    final hasActiveSubscription =
        await _subscriptionService.hasActiveSubscription();

    if (!mounted) return;

    if (!hasActiveSubscription) {
      setState(() {
        _hasActiveSubscription = false;
        _isLoading = false;
      });
      return;
    }

    final listeners = await _controller.getAvailableListeners();

    if (!mounted) return;

    setState(() {
      _hasActiveSubscription = true;
      _listeners = listeners;
      _isLoading = false;
    });
  }

  Future<void> _openListenerChat(ListenerModel listener) async {
    final hasActiveSubscription =
        await _subscriptionService.hasActiveSubscription();
    if (!mounted) return;

    if (!hasActiveSubscription) {
      setState(() => _hasActiveSubscription = false);
      _showSubscriptionRequiredMessage();
      return;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _listenerAvatar(listener),
            const SizedBox(height: 14),

            Text(
              listener.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            _ratingStars(listener.rating),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                listener.bio?.trim().isNotEmpty == true
                    ? listener.bio!
                    : 'This listener has not added a bio yet.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Choose Listener'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final conversationId = await _controller.requestListener(listener.id);

    if (!mounted) return;

    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to request listener.')),
      );
      return;
    }

    await widget.onRequestCreated?.call();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListenerWaitingPage(
          listener: listener,
          conversationId: conversationId,
        ),
      ),
    );

    await widget.onRequestCreated?.call();
  }

  void _showSubscriptionRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mindly Premium is required to access listeners.'),
      ),
    );
  }

  String _shortBio(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return 'Available to listen and support you.';
    }

    if (bio.length <= 70) return bio;

    return '${bio.substring(0, 70)}...';
  }

  Widget _listenerAvatar(ListenerModel listener) {
    final firstLetter = listener.name.isNotEmpty
        ? listener.name[0].toUpperCase()
        : '?';

    if (listener.profileUrl != null && listener.profileUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(listener.profileUrl!),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _ratingStars(double rating) {
    final fullStars = rating.floor().clamp(0, 5);

    return Row(
      children: [
        ...List.generate(
          fullStars,
          (_) => const Icon(Icons.star, color: Colors.amber, size: 14),
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  void _showFullBio(ListenerModel listener) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listener.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _ratingStars(listener.rating),
            const SizedBox(height: 16),
            Text(
              listener.bio?.trim().isNotEmpty == true
                  ? listener.bio!
                  : 'This listener has not added a bio yet.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Talk to a Listener',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_hasActiveSubscription
            ? _buildLockedState()
            : _listeners.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(26),
                  child: Text(
                    'No listeners are available right now.\nPlease check again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  const Text(
                    'Available listeners',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._listeners.map((listener) {
                    return GestureDetector(
                      onTap: () => _openListenerChat(listener),
                      onLongPress: () => _showFullBio(listener),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _listenerAvatar(listener),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listener.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _ratingStars(listener.rating),
                                  const SizedBox(height: 6),
                                  Text(
                                    _shortBio(listener.bio),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Mindly Premium Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Subscribe before accessing listener support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
