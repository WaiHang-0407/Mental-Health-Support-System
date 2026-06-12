import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_session.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import 'chat_ai.dart';

class ChatMainPage extends StatefulWidget {
  const ChatMainPage({super.key});

  @override
  State<ChatMainPage> createState() => _ChatMainPageState();
}

class _ChatMainPageState extends State<ChatMainPage> {
  final ChatController _controller = ChatController();

  // All available animals — matches your assets
  final List<String> _allAnimals = [
    'dog', 'cat', 'rabbit', 'duck', 'parrot', 'guinea-pig'
  ];

  @override
  void initState() {
    super.initState();
    _controller.loadChatPage();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
                  fontWeight: FontWeight.bold),
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
                final hasSession =
                    _controller.sessions.any((s) => s.animal == animal);
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
                              color: Colors.white, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        if (isFav)
                          const Text('⭐',
                              style: TextStyle(fontSize: 10)),
                        if (hasSession)
                          const Text('• active',
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9)),
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
          title: const Text('Chats',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
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
                                color: Colors.white.withOpacity(0.25)),
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
                                              fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('⭐ Fav',
                                              style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Your favourite companion',
                                      style: TextStyle(
                                          color: Colors.white60, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Listener card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Text('🎧', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Talk to a Listener',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('Connect with a real person',
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Soon',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                              fontSize: 14),
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
                                  color: Colors.white54, fontSize: 15),
                            ),
                            const Text(
                              'Tap + to start chatting',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13),
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
            title: const Text('Delete conversation?',
                style: TextStyle(color: Colors.white)),
            content: Text(
                'Your chat with ${_labelForAnimal(animal)} will be deleted.',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
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
            border:
                Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Image.asset(
                _assetForAnimal(animal),
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mindly ${_labelForAnimal(animal)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(session.createdAt),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.white38, size: 20),
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