import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../widgets/gradient_background.dart';

class ChatAiPage extends StatefulWidget {
  final ChatSession session;
  final ChatController controller;
  final String animal;

  const ChatAiPage({
    super.key,
    required this.session,
    required this.controller,
    required this.animal,
  });

  @override
  State<ChatAiPage> createState() => _ChatAiPageState();
}

class _ChatAiPageState extends State<ChatAiPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _showEmoji = false;

  String get _animalLabel {
    if (widget.animal == 'guinea-pig') return 'Guinea Pig';
    return widget.animal[0].toUpperCase() + widget.animal.substring(1);
  }

  String get _animalAsset => 'assets/images/${widget.animal}.png';

  @override
  void initState() {
    super.initState();
    widget.controller.loadMessages(widget.session.id);
    widget.controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.controller.isSending) return;
    _textController.clear();
    setState(() => _showEmoji = false);
    widget.controller.sendMessage(widget.session.id, text, widget.animal);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;
    await widget.controller.sendImage(
      widget.session.id,
      File(picked.path),
      widget.animal,
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
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
          title: Row(
            children: [
              Image.asset(_animalAsset, height: 36, width: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mindly $_animalLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Always here for you',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Messages
            Expanded(
              child: widget.controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.controller.messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = widget.controller.messages[index];
                        return _buildMessageBubble(
                          msg: msg,
                        ); // 👈 pass whole msg
                      },
                    ),
            ),

            // Typing indicator
            if (widget.controller.isSending)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Image.asset(_animalAsset, height: 24, width: 24),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_animalLabel is typing...',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Emoji picker
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
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: const Color(0xFF1A2340),
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

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              color: Colors.transparent,
              child: Row(
                children: [
                  // Emoji button
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

                  // Image button
                  IconButton(
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: _showImageOptions,
                  ),

                  // Text field
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

                  // Send button
                  GestureDetector(
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.controller.isSending
                            ? Colors.white24
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: widget.controller.isSending
                            ? Colors.white54
                            : Colors.black87,
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
    );
  }

  // Replace _buildMessageBubble with this:
  Widget _buildMessageBubble({required ChatMessage msg}) {
    final isUser = msg.role == 'user';

    // Deleted message placeholder
    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, color: Colors.white30, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Message deleted',
                    style: TextStyle(
                      color: Colors.white30,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Image.asset(_animalAsset, height: 28, width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(msg), // 👈 long press
              child: Container(
                padding: msg.imageUrl != null
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isUser
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: msg.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          msg.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const SizedBox(
                                  width: 200,
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                        ),
                      )
                    : Text(
                        msg.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to _ChatAiPageState:
  void _showMessageOptions(ChatMessage msg) {
    final isUser = msg.role == 'user';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isUser)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete message',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(msg);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Hide this reply',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: const Text(
                  'Only hidden from view, not deleted',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.hideMessage(msg.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text(
          'Delete message?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This message will be marked as deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.controller.deleteMessage(msg.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
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
          Image.asset(_animalAsset, height: 80, width: 80),
          const SizedBox(height: 16),
          Text(
            "Hi! I'm your $_animalLabel",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to listen and support you.\nFeel free to share anything.",
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
}
