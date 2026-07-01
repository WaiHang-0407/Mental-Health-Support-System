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

    if (status == 'accepted') {
      _timer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListenerChatPage(
            listener: widget.listener,
            conversationId: widget.conversationId,
          ),
        ),
      );
    }
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
                  if (_status == 'pending')
                    const CircularProgressIndicator()
                  else
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
