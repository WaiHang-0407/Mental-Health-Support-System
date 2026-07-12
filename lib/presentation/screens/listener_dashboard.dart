import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/listener_controller.dart';
import '../../../models/listener.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/listener_bottom_nav_bar.dart';
import 'listener_chat.dart';
import 'listener_edit_profile.dart';

class ListenerDashboardPage extends StatefulWidget {
  const ListenerDashboardPage({super.key});

  @override
  State<ListenerDashboardPage> createState() => _ListenerDashboardPageState();
}

class _ListenerDashboardPageState extends State<ListenerDashboardPage> {
  final ListenerController _controller = ListenerController();
  final supabase = Supabase.instance.client;
  RealtimeChannel? _conversationChannel;

  bool _isLoading = true;
  ListenerModel? _listenerProfile;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _completedSessions = [];

  Map<String, dynamic> _stats = {
    'completed_sessions': 0,
    'average_rating': 0.0,
    'total_reviews': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _conversationChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final profile = await _controller.getMyListenerProfile();

    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _listenerProfile = null;

        _pendingRequests = [];
        _activeSessions = [];
        _completedSessions = [];

        _stats = {
          'completed_sessions': 0,
          'average_rating': 0.0,
          'total_reviews': 0,
        };

        _isLoading = false;
      });
      return;
    }

    final requests = await _controller.getMyPendingRequests();
    final active = await _controller.getMyActiveSessions();
    final completed = await _controller.getMyCompletedSessions();
    final stats = await _controller.getMyListenerStats();

    if (!mounted) return;

    if (profile != null) {
      _listenToConversationUpdates(profile.id);
    } else {
      _conversationChannel?.unsubscribe();
      _conversationChannel = null;
    }

    setState(() {
      _listenerProfile = profile;

      _pendingRequests = requests;
      _activeSessions = active;
      _completedSessions = completed;

      _stats = stats;

      _isLoading = false;
    });
  }

  void _listenToConversationUpdates(String listenerId) {
    _conversationChannel?.unsubscribe();

    _conversationChannel = supabase
        .channel('listener_dashboard_$listenerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'listener_conversation',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'listener_id',
            value: listenerId,
          ),
          callback: (_) {
            _loadDashboard();
          },
        )
        .subscribe();
  }

  Future<void> _acceptRequest(String conversationId) async {
    final error = await _controller.acceptRequest(conversationId);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (_listenerProfile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListenerChatPage(
          listener: _listenerProfile!,
          conversationId: conversationId,
          isListenerSide: true,
        ),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _rejectRequest(String conversationId) async {
    final error = await _controller.rejectRequest(conversationId);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await _loadDashboard();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  Widget _patientAvatar(Map<String, dynamic> session) {
    final patient = session['patients'];
    final avatarUrl = patient?['avatar_url'];
    final name = patient?['name']?.toString() ?? 'Patient';

    if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(avatarUrl.toString()),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withOpacity(0.18),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Listener Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _listenerProfile == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(26),
                  child: Text(
                    'You are not registered as a listener.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          child: Text(
                            _listenerProfile!.name.isNotEmpty
                                ? _listenerProfile!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _listenerProfile!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Status: ${_listenerProfile!.status}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),

                                  const SizedBox(width: 4),

                                  Text(
                                    _stats['average_rating'].toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    '(${_stats['total_reviews']} Reviews)',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Listener Profile'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF4C7CF3),
                        overlayColor: Colors.white.withOpacity(0.16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListenerEditProfilePage(),
                          ),
                        );
                        await _loadDashboard();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Completed',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stats['completed_sessions'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Rating',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (_stats['average_rating'] as double)
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stats['total_reviews'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_pendingRequests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Text(
                        'No pending requests right now.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    )
                  else
                    ..._pendingRequests.map((request) {
                      final conversationId = request['id'].toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _patientAvatar(request),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    request['patients']?['name']?.toString() ??
                                        'Patient request',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requested on ${_formatDate(request['started_at'])}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _rejectRequest(conversationId),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _acceptRequest(conversationId),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  const Text(
                    'Active Sessions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),
                  if (_activeSessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(.1)),
                      ),
                      child: const Text(
                        'No active sessions.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ..._activeSessions.map((session) {
                      final conversationId = session['id'].toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _patientAvatar(session),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    session['patients']?['name']?.toString() ??
                                        'Active Conversation',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Started ${_formatDate(session['accepted_at'])}',
                              style: const TextStyle(color: Colors.white54),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ListenerChatPage(
                                        listener: _listenerProfile!,
                                        conversationId: conversationId,
                                        isListenerSide: true,
                                      ),
                                    ),
                                  ).then((_) => _loadDashboard());
                                },
                                child: const Text('Open Chat'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  const Text(
                    'Completed Sessions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_completedSessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(.1)),
                      ),
                      child: const Text(
                        'No completed sessions yet.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ..._completedSessions.map((session) {
                      final rating = session['patient_rating'];
                      final remark = session['patient_remark'];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListenerChatPage(
                                listener: _listenerProfile!,
                                conversationId: session['id'].toString(),
                                isListenerSide: true,
                                readOnly: true,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _patientAvatar(session),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      session['patients']?['name']?.toString() ??
                                          'Completed Conversation',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Ended ${_formatDate(session['ended_at'])}',
                                style: const TextStyle(color: Colors.white54),
                              ),

                              if (rating != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                              ],

                              if (remark != null &&
                                  remark.toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  remark.toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
        bottomNavigationBar: const ListenerBottomNavBar(currentIndex: 0),
      ),
    );
  }
}
