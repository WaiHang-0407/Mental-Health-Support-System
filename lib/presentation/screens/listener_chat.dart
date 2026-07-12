import 'dart:async';

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/listener_controller.dart';
import '../../../models/listener.dart';
import '../../../models/listener_message.dart';
import '../../../widgets/gradient_background.dart';

class ListenerChatPage extends StatefulWidget {
  final ListenerModel listener;
  final String conversationId;
  final bool isListenerSide;
  final bool readOnly;

  const ListenerChatPage({
    super.key,
    required this.listener,
    required this.conversationId,
    this.isListenerSide = false,
    this.readOnly = false,
  });

  @override
  State<ListenerChatPage> createState() => _ListenerChatPageState();
}

class _ListenerChatPageState extends State<ListenerChatPage> {
  final ListenerController _controller = ListenerController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final supabase = Supabase.instance.client;
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _conversationChannel;

  bool _isLoading = true;
  bool _isSending = false;
  bool _showEmoji = false;
  bool _isClosed = false;
  bool _reviewPrompted = false;

  List<ListenerMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadConversationStatus();
    _listenToMessages();
    _listenToConversationUpdates();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _conversationChannel?.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToMessages() {
    _messageChannel = supabase
        .channel('listener_chat_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'listener_message',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (_) {
            _loadMessages();
          },
        )
        .subscribe();
  }

  void _listenToConversationUpdates() {
    _conversationChannel = supabase
        .channel('listener_conversation_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'listener_conversation',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.conversationId,
          ),
          callback: (_) async {
            await _handleConversationUpdate();
          },
        )
        .subscribe();
  }

  Future<void> _handleConversationUpdate() async {
    final status = await _controller.getConversationStatus(
      widget.conversationId,
    );

    if (!mounted) return;

    if (status != 'closed' || _reviewPrompted) return;

    setState(() {
      _isClosed = true;
      _reviewPrompted = true;
      _showEmoji = false;
    });

    if (widget.isListenerSide) {
      if (!widget.readOnly && mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    // Patient must acknowledge that the listener ended the session.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2340),
          title: const Text(
            'Session ended',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${widget.listener.name} has ended the listener session.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Review is optional. Closing with X still continues.
    await _showRatingPopup();

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _loadMessages() async {
    final messages = await _controller.getMessages(widget.conversationId);

    if (!mounted) return;

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _showEmoji = false;
    });

    _textController.clear();

    final error = await _controller.sendMessage(
      conversationId: widget.conversationId,
      message: text,
      senderType: widget.isListenerSide ? 'listener' : 'patient',
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await _loadMessages();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text('Leave chat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this chat?',
          style: TextStyle(color: Colors.white70),
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
              'Leave',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmEndSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text(
          'End session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will close the listener session. The patient will need to request a new session next time.',
          style: TextStyle(color: Colors.white70),
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
            child: const Text('End', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!widget.isListenerSide) {
      setState(() => _reviewPrompted = true);
    }

    final error = await _controller.endSession(widget.conversationId);

    if (!mounted) return;

    if (error != null) {
      if (!widget.isListenerSide) {
        setState(() => _reviewPrompted = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!widget.isListenerSide) {
      // The patient may submit the review or close the dialog to skip it.
      await _showRatingPopup();
    }

    if (!mounted) return;

    setState(() {
      _isClosed = true;
      _reviewPrompted = true;
    });

    // Returning true tells the previous page to refresh its chat list.
    Navigator.pop(context, true);
  }

  Future<void> _loadConversationStatus() async {
    final status = await _controller.getConversationStatus(
      widget.conversationId,
    );

    if (!mounted) return;

    setState(() {
      _isClosed = status == 'closed';
    });
  }

  Widget _buildMessageBubble(ListenerMessageModel msg) {
    final isMine = widget.isListenerSide
        ? msg.senderType == 'listener'
        : msg.senderType == 'patient';

    final oppositeAvatarText = widget.isListenerSide
        ? 'P'
        : widget.listener.name.isNotEmpty
        ? widget.listener.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Text(
                oppositeAvatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: Border.all(
                  color: isMine
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                msg.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎧', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            widget.isListenerSide
                ? 'You accepted this request'
                : 'You are now connected with ${widget.listener.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isListenerSide
                ? 'Start the conversation when you are ready.'
                : 'Feel free to share what is on your mind.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isListenerSide
        ? 'Patient Chat'
        : widget.listener.name;

    final avatarText = widget.isListenerSide
        ? 'P'
        : widget.listener.name.isNotEmpty
        ? widget.listener.name[0].toUpperCase()
        : '?';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmLeave();
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Image.asset(
                'assets/images/back.png',
                height: 24,
                width: 24,
              ),
              onPressed: _confirmLeave,
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Active listener session',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (!_isClosed && !widget.readOnly)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1A2340),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => SafeArea(
                        child: ListTile(
                          leading: const Icon(
                            Icons.call_end,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            'End Session',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _confirmEndSession();
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
              ),

              if (_showEmoji)
                SizedBox(
                  height: 280,
                  child: EmojiPicker(
                    onEmojiSelected: (_, emoji) {
                      _textController.text += emoji.emoji;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length),
                      );
                    },
                    config: Config(
                      height: 280,
                      emojiViewConfig: const EmojiViewConfig(
                        backgroundColor: Color(0xFF1A2340),
                      ),
                      categoryViewConfig: const CategoryViewConfig(
                        backgroundColor: Color(0xFF1A2340),
                        iconColor: Colors.white54,
                        iconColorSelected: Colors.white,
                        indicatorColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (_isClosed || widget.readOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: const Text(
                    'This session has ended.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showEmoji
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _showEmoji = !_showEmoji);
                          if (_showEmoji) FocusScope.of(context).unfocus();
                        },
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onTap: () => setState(() => _showEmoji = false),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _send,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isSending ? Colors.white24 : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: _isSending ? Colors.white54 : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showRatingPopup() async {
    int selectedRating = 0;
    final remarkController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2340),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rate your listener',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNumber = index + 1;
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = starNumber;
                        });
                      },
                      icon: Icon(
                        selectedRating >= starNumber
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: remarkController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Optional remark...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: selectedRating == 0
                    ? null
                    : () async {
                        final error = await _controller.submitSessionRating(
                          conversationId: widget.conversationId,
                          rating: selectedRating,
                          remark: remarkController.text,
                        );

                        if (!context.mounted) return;

                        if (error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }

                        Navigator.pop(context, true);
                      },
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    remarkController.dispose();
    return submitted ?? false;
  }
}
