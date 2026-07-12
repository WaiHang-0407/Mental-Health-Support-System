import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/listener_controller.dart';
import '../../models/chat_session.dart';
import '../../models/listener.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../services/subscription_service.dart';
import 'chat_ai.dart';
import 'listener_chat.dart';
import 'listener_main.dart';
import 'listener_waiting.dart';

class ChatMainPage extends StatefulWidget {
  const ChatMainPage({super.key});

  @override
  State<ChatMainPage> createState() => _ChatMainPageState();
}

class _ChatMainPageState extends State<ChatMainPage> {
  final ChatController _controller = ChatController();
  final ListenerController _listenerController = ListenerController();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final supabase = Supabase.instance.client;
  RealtimeChannel? _listenerConversationChannel;
  bool _hasActiveSubscription = false;
  List<Map<String, dynamic>> _pendingListenerRequests = [];
  List<Map<String, dynamic>> _activeListenerSessions = [];
  bool _isCheckingSubscription = true;
  bool _isStartingCheckout = false;

  static const String _listenerDeniedMessage =
      'Looks like your listener is busy at the moment :( its ok ,you can pick another listener!';

  // All available animals — matches your assets
  final List<String> _allAnimals = [
    'dog',
    'cat',
    'rabbit',
    'duck',
    'parrot',
    'guinea-pig',
  ];

  @override
  void initState() {
    super.initState();
    _controller.loadChatPage();
    _controller.addListener(() => setState(() {}));
    _loadSubscriptionStatus();
    _loadPendingListenerRequests();
    _loadActiveListenerSessions();
    _listenToListenerConversationUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPendingListenerRequests();
    _loadActiveListenerSessions();
  }

  @override
  void dispose() {
    _listenerConversationChannel?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  String _assetForAnimal(String? animal) {
    if (animal == null) return 'assets/images/dog.png';
    return 'assets/images/$animal.png';
  }

  String _labelForAnimal(String animal) {
    if (animal == 'guinea-pig') return 'Guinea Pig';
    return animal[0].toUpperCase() + animal.substring(1);
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final hasActiveSubscription = await _subscriptionService
          .hasActiveSubscription();
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = hasActiveSubscription;
        _isCheckingSubscription = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasActiveSubscription = false;
        _isCheckingSubscription = false;
      });
    }
  }

  void _listenToListenerConversationUpdates() {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) return;

    _listenerConversationChannel = supabase
        .channel('patient_listener_conversations_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listener_conversation',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: currentUserId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord as Map<String, dynamic>?;
            final requestStatus = newRecord?['request_status']?.toString();

            if (requestStatus == 'rejected' && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(_listenerDeniedMessage)),
              );
            }

            await _refreshListenerSections();
          },
        )
        .subscribe();
  }

  Future<void> _loadPendingListenerRequests() async {
    final requests = await _listenerController.getMyPendingListenerRequests();

    if (!mounted) return;

    setState(() {
      _pendingListenerRequests = requests;
    });
  }

  Future<void> _loadActiveListenerSessions() async {
    final sessions = await _listenerController.getMyActiveListenerSessions();

    if (!mounted) return;

    setState(() {
      _activeListenerSessions = sessions;
    });
  }

  Future<void> _refreshListenerSections() async {
    await _loadPendingListenerRequests();
    await _loadActiveListenerSessions();
  }

  Future<void> _cancelPendingListenerRequest(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text(
          'Cancel request?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove your pending listener request.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep it',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel request',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await _listenerController.cancelListenerRequest(
      conversationId,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (mounted) {
      setState(() {
        _pendingListenerRequests.removeWhere(
          (request) => request['id']?.toString() == conversationId,
        );
      });
    }

    await _refreshListenerSections();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listener request cancelled.')),
    );
  }

  Future<void> _openListenerPage() async {
    final hasActiveSubscription = await _subscriptionService
        .hasActiveSubscription();
    if (!mounted) return;

    setState(() => _hasActiveSubscription = hasActiveSubscription);

    if (!hasActiveSubscription) {
      _showSubscriptionRequiredSheet();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListenerMainPage(
          onRequestCreated: () async {
            await _refreshListenerSections();
          },
        ),
      ),
    );

    if (mounted) {
      await _refreshListenerSections();
    }
  }

  Future<void> _startSubscriptionCheckout(
    SubscriptionPaymentProvider provider,
  ) async {
    setState(() => _isStartingCheckout = true);
    try {
      await _subscriptionService.startCheckout(provider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start payment: $e')));
    } finally {
      if (mounted) setState(() => _isStartingCheckout = false);
    }
  }

  void _showSubscriptionRequiredSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mindly Premium Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Subscribe to access listener support and premium activities.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isStartingCheckout
                    ? null
                    : () {
                        Navigator.pop(context);
                        _startSubscriptionCheckout(
                          SubscriptionPaymentProvider.stripe,
                        );
                      },
                child: const Text('Subscribe with Stripe'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isStartingCheckout
                    ? null
                    : () {
                        Navigator.pop(context);
                        _startSubscriptionCheckout(
                          SubscriptionPaymentProvider.paypal,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Text('Subscribe with PayPal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSession(String animal) async {
    final session = await _controller.openAnimalSession(animal);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatAiPage(
            session: session,
            controller: _controller,
            animal: animal,
          ),
        ),
      );
    }
  }

  void _showAnimalPicker() {
    final favAnimal = _controller.patient?.favAnimal;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a companion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              children: _allAnimals.map((animal) {
                final isFav = animal == favAnimal;
                final hasSession = _controller.sessions.any(
                  (s) => s.animal == animal,
                );
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openSession(animal);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFav
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _assetForAnimal(animal),
                          height: 40,
                          width: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labelForAnimal(animal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isFav)
                          const Text('⭐', style: TextStyle(fontSize: 10)),
                        if (hasSession)
                          const Text(
                            '• active',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favAnimal = _controller.patient?.favAnimal;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Chats',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAnimalPicker,
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black87),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_pendingListenerRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildPendingListenerCard(
                        _pendingListenerRequests.first,
                      ),
                    ),
                  ],

                  // Fav animal quick-start card
                  if (favAnimal != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () => _openSession(favAnimal),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                _assetForAnimal(favAnimal),
                                height: 48,
                                width: 48,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Mindly ${_labelForAnimal(favAnimal)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            '⭐ Fav',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Your favourite companion',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Listener card
                  // Listener card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GestureDetector(
                      onTap: _isCheckingSubscription ? null : _openListenerPage,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🎧', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Talk to a Listener',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _hasActiveSubscription
                                        ? 'Premium access active'
                                        : 'Premium required',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _hasActiveSubscription
                                  ? Icons.chevron_right
                                  : Icons.lock_outline,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_activeListenerSessions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Listener Chats',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _activeListenerSessions.map((session) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildActiveListenerSessionCard(session),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Sessions list
                  if (_controller.sessions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Companions',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _controller.sessions.length,
                        itemBuilder: (context, index) {
                          final session = _controller.sessions[index];
                          return _buildSessionTile(session);
                        },
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (favAnimal != null)
                              Image.asset(
                                _assetForAnimal(favAnimal),
                                height: 80,
                              ),
                            const SizedBox(height: 12),
                            const Text(
                              'No conversations yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              'Tap + to start chatting',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingListenerCard(Map<String, dynamic> request) {
    final listenerName = request['listener_name']?.toString() ?? 'Listener';
    final listenerProfileUrl = request['listener_profile_url']?.toString();
    final listenerBio = request['listener_bio']?.toString();
    final conversationId = request['id']?.toString();

    final firstLetter = listenerName.isNotEmpty
        ? listenerName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: conversationId == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListenerWaitingPage(
                    listener: ListenerModel(
                      id: request['listener_id']?.toString() ?? '',
                      name: listenerName,
                      bio: listenerBio,
                      profileUrl: listenerProfileUrl,
                      rating: 5.0,
                      totalSessions: 0,
                      status: 'available',
                    ),
                    conversationId: conversationId,
                  ),
                ),
              );

              if (mounted) {
                await _refreshListenerSections();
              }
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            if (listenerProfileUrl != null && listenerProfileUrl.isNotEmpty)
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(listenerProfileUrl),
              )
            else
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listenerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listenerBio != null && listenerBio.isNotEmpty
                        ? listenerBio
                        : 'Waiting for this listener to accept your request.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Waiting for acceptance…',
                    style: TextStyle(color: Colors.white60, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                TextButton(
                  onPressed: conversationId == null
                      ? null
                      : () => _cancelPendingListenerRequest(conversationId),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListenerSessionCard(Map<String, dynamic> session) {
    final listenerName = session['listener_name']?.toString() ?? 'Listener';
    final listenerProfileUrl = session['listener_profile_url']?.toString();
    final conversationId = session['id']?.toString();
    final firstLetter = listenerName.isNotEmpty
        ? listenerName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: conversationId == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListenerChatPage(
                    listener: ListenerModel(
                      id: session['listener_id']?.toString() ?? '',
                      name: listenerName,
                      bio: session['listener_bio']?.toString(),
                      profileUrl: listenerProfileUrl,
                      rating: 5.0,
                      totalSessions: 0,
                      status: 'available',
                    ),
                    conversationId: conversationId,
                  ),
                ),
              );

              if (mounted) {
                await _refreshListenerSections();
              }
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            if (listenerProfileUrl != null && listenerProfileUrl.isNotEmpty)
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(listenerProfileUrl),
              )
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listenerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Active listener session',
                    style: TextStyle(color: Colors.white60, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(ChatSession session) {
    final animal = session.animal ?? 'dog';
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A2340),
            title: const Text(
              'Delete conversation?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Your chat with ${_labelForAnimal(animal)} will be deleted.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _controller.deleteSession(session.id),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatAiPage(
              session: session,
              controller: _controller,
              animal: animal,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Image.asset(_assetForAnimal(animal), height: 40, width: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mindly ${_labelForAnimal(animal)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(session.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
