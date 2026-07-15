import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/comment_controller.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import 'public_profile.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final PostController postController;
  final bool focusCommentOnOpen;
  const PostDetailPage({
    super.key,
    required this.post,
    required this.postController,
    this.focusCommentOnOpen = false,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final CommentController _commentController = CommentController();
  final TextEditingController _commentInput = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  String? _replyingToId;
  String? _replyingToName;

  Post get _currentPost {
    for (final post in [
      ...widget.postController.posts,
      ...widget.postController.myPosts,
    ]) {
      if (post.id == widget.post.id) return post;
    }
    return widget.post;
  }

  @override
  void initState() {
    super.initState();
    _commentController.loadComments(widget.post.id);
    _commentController.addListener(() => setState(() {}));
    widget.postController.addListener(_refreshPostState);
    if (widget.focusCommentOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _commentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.postController.removeListener(_refreshPostState);
    _commentController.dispose();
    _commentInput.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _refreshPostState() {
    if (mounted) setState(() {});
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
              ...reasons.map((r) {
                final isSelected = selected == r;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setS(() => selected = r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.white : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: _commentController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        children: [
                          _buildPostHeader(),
                          const SizedBox(height: 18),
                          _buildCommentsHeader(),
                          const SizedBox(height: 12),
                          ..._commentController.comments.map(_buildCommentTile),
                          if (_commentController.comments.isEmpty)
                            _buildEmptyComments(),
                        ],
                      ),
              ),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    final post = _currentPost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openProfile(post.patientId, post.authorName),
                child: _authorAvatar(post, radius: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () =>
                                _openProfile(post.patientId, post.authorName),
                            child: Text(
                              post.authorName ?? 'Anonymous',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (post.authorRole == 'listener' ||
                            post.authorRole == 'patient_listener') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blueAccent.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Listener',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildPostImages(post),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _postMetric(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                text: '${post.likeCount}',
                color: post.isLiked
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.72),
                onTap: () => widget.postController.toggleLike(post),
              ),
              const SizedBox(width: 12),
              _postMetric(
                icon: Icons.chat_bubble_outline,
                text: '${_visibleCommentCount()}',
                color: Colors.white.withValues(alpha: 0.72),
                onTap: () => _commentFocusNode.requestFocus(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostImages(Post post) {
    if (post.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ImageViewer(imageUrls: post.imageUrls, initialIndex: 0),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            post.imageUrls[0],
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: post.imageUrls.length == 2 ? 2 : 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: post.imageUrls.length > 5 ? 5 : post.imageUrls.length,
        itemBuilder: (_, i) {
          final isLast = i == 4 && post.imageUrls.length > 5;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ImageViewer(imageUrls: post.imageUrls, initialIndex: i),
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
    );
  }

  Widget _postMetric({
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsHeader() {
    final count = _visibleCommentCount();
    return Row(
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyComments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white.withValues(alpha: 0.55),
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'No comments yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the conversation with something kind or helpful.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10182E).withValues(alpha: 0.58),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    color: Colors.white.withValues(alpha: 0.62),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyingToName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _replyingToId = null;
                      _replyingToName = null;
                    }),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.52),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _commentInput,
                    focusNode: _commentFocusNode,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _replyingToName != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
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
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _submitComment,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.send_rounded,
                      color: Color(0xFF10182E),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(String? name, {required double radius}) {
    return CircleAvatar(
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      radius: radius,
      child: Text(
        (name == null || name.isEmpty ? 'A' : name[0]).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }

  Widget _authorAvatar(Post post, {required double radius}) {
    final avatarUrl = post.authorAvatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    return _initialAvatar(post.authorName, radius: radius);
  }

  Widget _commentAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? Colors.white.withValues(alpha: 0.48);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actionColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: actionColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: isDeleted ? null : () => _showCommentOptions(comment),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isDeleted
                        ? null
                        : () => _openProfile(
                            comment.patientId,
                            comment.authorName,
                          ),
                    child: _initialAvatar(
                      isDeleted ? null : comment.authorName,
                      radius: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: isDeleted
                                  ? Text(
                                      'Deleted comment',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => _openProfile(
                                        comment.patientId,
                                        comment.authorName,
                                      ),
                                      child: Text(
                                        comment.authorName ?? 'Anonymous',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                            ),
                            Text(
                              _timeAgo(comment.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDeleted
                              ? 'This comment was deleted'
                              : comment.content,
                          style: TextStyle(
                            color: isDeleted
                                ? Colors.white.withValues(alpha: 0.34)
                                : Colors.white.withValues(alpha: 0.78),
                            fontStyle: isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontSize: 14,
                            height: 1.34,
                          ),
                        ),
                        if (!isDeleted) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _commentAction(
                                icon: comment.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: '${comment.likeCount}',
                                color: comment.isLiked
                                    ? Colors.redAccent
                                    : null,
                                onTap: () => _commentController.toggleLike(
                                  comment.id,
                                  comment.isLiked,
                                  widget.post.id,
                                ),
                              ),
                              const SizedBox(width: 14),
                              _commentAction(
                                icon: Icons.reply_rounded,
                                label: 'Reply',
                                onTap: () {
                                  setState(() {
                                    _replyingToId = comment.id;
                                    _replyingToName = comment.authorName;
                                  });
                                },
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
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: comment.replies
                        .map((reply) => _buildReplyTile(reply, depth: 1))
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyTile(Comment reply, {required int depth}) {
    final childIndent = depth >= 2 ? 16.0 : 28.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: reply.isDeleted
                ? null
                : () => _showCommentOptions(reply),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _initialAvatar(
                    reply.isDeleted ? null : reply.authorName,
                    radius: 13,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: reply.isDeleted
                                  ? Text(
                                      'Deleted reply',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.32,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    )
                                  : Text(
                                      reply.authorName ?? 'Anonymous',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                            Text(
                              _timeAgo(reply.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.32),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.isDeleted
                              ? 'This reply was deleted'
                              : reply.content,
                          style: TextStyle(
                            color: reply.isDeleted
                                ? Colors.white.withValues(alpha: 0.32)
                                : Colors.white.withValues(alpha: 0.72),
                            fontStyle: reply.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontSize: 13,
                            height: 1.32,
                          ),
                        ),
                        if (!reply.isDeleted) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _commentAction(
                                icon: reply.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: '${reply.likeCount}',
                                color: reply.isLiked ? Colors.redAccent : null,
                                onTap: () => _commentController.toggleLike(
                                  reply.id,
                                  reply.isLiked,
                                  widget.post.id,
                                ),
                              ),
                              const SizedBox(width: 14),
                              _commentAction(
                                icon: Icons.reply_rounded,
                                label: 'Reply',
                                onTap: () {
                                  setState(() {
                                    _replyingToId = reply.id;
                                    _replyingToName = reply.authorName;
                                  });
                                },
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
          if (reply.replies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: childIndent, top: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      ...reply.replies.map(
                        (child) => _buildReplyTile(child, depth: depth + 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openProfile(String patientId, String? fallbackName) {
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
