import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/comment_controller.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import 'profile.dart';
import 'public_profile.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final PostController postController;
  const PostDetailPage({
    super.key,
    required this.post,
    required this.postController,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final CommentController _commentController = CommentController();
  final TextEditingController _commentInput = TextEditingController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _commentController.loadComments(widget.post.id);
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentInput.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentInput.text.trim();
    if (text.isEmpty) return;
    _commentInput.clear();
    await _commentController.addComment(
      widget.post.id,
      text,
      parentId: _replyingToId,
    );
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  void _showCommentOptions(Comment comment) {
    final isOwn = comment.patientId == _uid;
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
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.white70),
              title: const Text(
                'Reply',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingToId = comment.id;
                  _replyingToName = comment.authorName;
                });
              },
            ),
            if (isOwn)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _commentController.deleteComment(comment.id, widget.post.id);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white70),
                title: const Text(
                  'Report',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportCommentDialog(comment);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportCommentDialog(Comment comment) async {
    final reasons = ['Inappropriate', 'Spam', 'Harassment', 'Other'];
    String? selected;
    final otherReasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A2340),
          title: const Text(
            'Report Comment',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setS(() => selected = v),
                  title: Text(
                    r,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  activeColor: Colors.white,
                ),
              ),
              if (selected == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherReasonController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type your reason...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (_) => setS(() {}),
                ),
              ],
            ],
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
              onPressed:
                  selected == null ||
                      (selected == 'Other' &&
                          otherReasonController.text.trim().isEmpty)
                  ? null
                  : () async {
                      final reason = selected == 'Other'
                          ? otherReasonController.text.trim()
                          : selected!;
                      Navigator.pop(context);
                      final reported = await _commentController.reportComment(
                        comment,
                        reason,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            reported
                                ? 'Report submitted'
                                : 'Unable to submit report',
                          ),
                        ),
                      );
                      if (reported) {
                        await _askHideReportedComment(comment);
                      }
                    },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
    otherReasonController.dispose();
  }

  Future<void> _askHideReportedComment(Comment comment) async {
    final hide = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text(
          'Hide this comment?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You reported this comment. Do you also want to hide it from this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hide',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (hide == true) {
      await _commentController.hideComment(comment, widget.post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment hidden from this post')),
      );
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
            icon: Image.asset('assets/images/back.png', height: 24, width: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _commentController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Post content
                        _buildPostHeader(),
                        const Divider(color: Colors.white12, height: 24),
                        // Comments
                        ..._commentController.comments.map(_buildCommentTile),
                        if (_commentController.comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No comments yet.',
                              style: TextStyle(color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
            ),
            // Reply indicator
            if (_replyingToName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white.withOpacity(0.05),
                child: Row(
                  children: [
                    Text(
                      'Replying to $_replyingToName',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingToId = null;
                        _replyingToName = null;
                      }),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white38,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            // Comment input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              color: Colors.transparent,
              child: Row(
                children: [
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
                        controller: _commentInput,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _replyingToName != null
                              ? 'Reply to $_replyingToName...'
                              : 'Add a comment...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitComment,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black87,
                        size: 18,
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

  Widget _buildPostHeader() {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _openProfile(post.patientId, post.authorName),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 20,
                child: Text(
                  (post.authorName ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(post.patientId, post.authorName),
                  child: Text(
                    post.authorName ?? 'Anonymous',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _timeAgo(post.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          post.content,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 10),
          if (post.imageUrls.length == 1)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImageViewer(imageUrls: post.imageUrls, initialIndex: 0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls[0],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: post.imageUrls.length == 2 ? 2 : 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: post.imageUrls.length > 5 ? 5 : post.imageUrls.length,
              itemBuilder: (_, i) {
                final isLast = i == 4 && post.imageUrls.length > 5;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewer(
                        imageUrls: post.imageUrls,
                        initialIndex: i,
                      ),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(post.imageUrls[i], fit: BoxFit.cover),
                      if (isLast)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${post.imageUrls.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            GestureDetector(
              onTap: () => widget.postController.toggleLike(post),
              child: Row(
                children: [
                  Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.redAccent : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${_visibleCommentCount()}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  int _visibleCommentCount() {
    int countComment(Comment comment) {
      if (comment.isDeleted) return 0;
      return 1 +
          comment.replies.fold<int>(0, (sum, reply) {
            return sum + countComment(reply);
          });
    }

    return _commentController.comments.fold<int>(0, (sum, comment) {
      return sum + countComment(comment);
    });
  }

  Widget _buildCommentTile(Comment comment) {
    final isDeleted = comment.isDeleted;
    return Column(
      children: [
        GestureDetector(
          onLongPress: isDeleted ? null : () => _showCommentOptions(comment),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: isDeleted
                      ? null
                      : () =>
                            _openProfile(comment.patientId, comment.authorName),
                  child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 14,
                    child: Text(
                      isDeleted
                          ? '?'
                          : (comment.authorName ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isDeleted)
                        GestureDetector(
                          onTap: () => _openProfile(
                            comment.patientId,
                            comment.authorName,
                          ),
                          child: Text(
                            comment.authorName ?? 'Anonymous',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Text(
                        isDeleted
                            ? 'This comment was deleted'
                            : comment.content,
                        style: TextStyle(
                          color: isDeleted ? Colors.white30 : Colors.white70,
                          fontStyle: isDeleted
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (!isDeleted) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _commentController.toggleLike(
                                comment.id,
                                comment.isLiked,
                                widget.post.id,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    comment.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: comment.isLiked
                                        ? Colors.redAccent
                                        : Colors.white38,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${comment.likeCount}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _timeAgo(comment.createdAt),
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Replies
        ...comment.replies.map(
          (reply) => Padding(
            padding: const EdgeInsets.only(left: 38),
            child: GestureDetector(
              onLongPress: reply.isDeleted
                  ? null
                  : () => _showCommentOptions(reply),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      radius: 12,
                      child: Text(
                        reply.isDeleted
                            ? '?'
                            : (reply.authorName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!reply.isDeleted)
                            Text(
                              reply.authorName ?? 'Anonymous',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            reply.isDeleted
                                ? 'This reply was deleted'
                                : reply.content,
                            style: TextStyle(
                              color: reply.isDeleted
                                  ? Colors.white30
                                  : Colors.white70,
                              fontStyle: reply.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openProfile(String patientId, String? fallbackName) {
    if (patientId == _uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfilePage(
          patientId: patientId,
          fallbackName: fallbackName ?? 'Anonymous',
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
