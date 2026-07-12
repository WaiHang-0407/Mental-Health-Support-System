import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controllers/listener_controller.dart';
import '../../../models/listener.dart';
import '../../../widgets/gradient_background.dart';
import 'listener_chat.dart';

class ListenerWaitingPage extends StatefulWidget {
  final ListenerModel listener;
  final String conversationId;

  const ListenerWaitingPage({
    super.key,
    required this.listener,
    required this.conversationId,
  });

  @override
  State<ListenerWaitingPage> createState() => _ListenerWaitingPageState();
}

class _ListenerWaitingPageState extends State<ListenerWaitingPage> {
  final ListenerController _controller = ListenerController();

  Timer? _timer;
  String _status = 'pending';
  bool _isOpeningChat = false;
  static const String _listenerDeniedMessage =
      'Looks like your listener is busy at the moment :( its ok ,you can pick another listener!';

  @override
  void initState() {
    super.initState();
    _checkStatus();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final status = await _controller.getRequestStatus(widget.conversationId);

    if (!mounted) return;

    if (status == null) return;

    setState(() {
      _status = status;
    });

    if (status == 'accepted' && !_isOpeningChat) {
      _isOpeningChat = true;
      _timer?.cancel();

      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ListenerChatPage(
            listener: widget.listener,
            conversationId: widget.conversationId,
          ),
        ),
      );

      if (!mounted) return;

      if (changed == true) {
        Navigator.pop(context, true);
        return;
      }

      setState(() {
        _isOpeningChat = false;
      });
    } else if (status == 'rejected') {
      _timer?.cancel();
      setState(() => _status = 'rejected');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_listenerDeniedMessage)));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _cancelRequest() async {
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

    final error = await _controller.cancelListenerRequest(
      widget.conversationId,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _timer?.cancel();
    setState(() => _status = 'cancelled');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listener request cancelled.')),
    );
    Navigator.pop(context, true);
  }

  String _statusText() {
    switch (_status) {
      case 'accepted':
        return '${widget.listener.name} accepted your request.';
      case 'rejected':
        return '${widget.listener.name} is unavailable right now.';
      case 'cancelled':
        return 'This request was cancelled.';
      default:
        return 'Waiting for ${widget.listener.name} to accept your request...';
    }
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
            'Listener Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎧', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  Text(
                    widget.listener.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_status == 'pending') ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _cancelRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
