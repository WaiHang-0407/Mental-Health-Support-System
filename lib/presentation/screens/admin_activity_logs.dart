import 'package:flutter/material.dart';

import '../../controllers/admin_activity_logs_controller.dart';
import '../../models/admin_activity_log.dart';
import '../../models/admin_community_post.dart';

class AdminActivityLogsPage extends StatefulWidget {
  AdminActivityLogsPage({super.key, AdminActivityLogsController? controller})
    : controller = controller ?? AdminActivityLogsController();

  final AdminActivityLogsController controller;

  @override
  State<AdminActivityLogsPage> createState() => _AdminActivityLogsPageState();
}

class _AdminActivityLogsPageState extends State<AdminActivityLogsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    widget.controller.loadLogs();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Logs',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Review recent admin actions across the dashboard.',
                        style: TextStyle(
                          color: Color(0xFF66736F),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading ? null : controller.loadLogs,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                controller.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: controller.isLoading && controller.logs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.logs.isEmpty
                    ? const Center(child: Text('No admin activity logs yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: controller.logs.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          return _AdminActivityLogRow(
                            log: controller.logs[index],
                            controller: controller,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActivityLogRow extends StatelessWidget {
  const _AdminActivityLogRow({required this.log, required this.controller});

  final AdminActivityLog log;
  final AdminActivityLogsController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showDetails(context, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFBFE8D8),
                child: Icon(
                  _iconFor(log.action),
                  color: const Color(0xFF14211D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _actionLabel(log.action),
                      style: const TextStyle(
                        color: Color(0xFF17201D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (log.targetType?.trim().isNotEmpty == true)
                          _LogChip(log.targetType!.replaceAll('_', ' ')),
                        if (log.targetId?.trim().isNotEmpty == true)
                          _LogChip(_shortId(log.targetId!)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDate(log.createdAt),
                style: const TextStyle(color: Color(0xFF66736F), fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9AA7A2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    AdminActivityLogsController controller,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Activity Log Details'),
          content: SizedBox(
            width: 760,
            height: 680,
            child: FutureBuilder<AdminActivityLogTargetDetails?>(
              future: controller.loadTargetDetails(log),
              builder: (context, snapshot) {
                return _ActivityLogDetailsContent(
                  log: log,
                  targetDetails: snapshot.data,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  hasError: snapshot.hasError,
                  actionLabel: _actionLabel(log.action),
                  formattedDate: _formatDate(log.createdAt),
                );
              },
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  IconData _iconFor(String action) {
    if (action.contains('deleted') || action.contains('deactivated')) {
      return Icons.delete_outline;
    }
    if (action.contains('archived')) return Icons.archive_outlined;
    if (action.contains('updated')) return Icons.edit_outlined;
    if (action.contains('restored') || action.contains('unarchived')) {
      return Icons.restore_outlined;
    }
    if (action.contains('user')) return Icons.people_alt_outlined;
    return Icons.history_outlined;
  }

  String _actionLabel(String action) {
    return action
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _ActivityLogDetailsContent extends StatelessWidget {
  const _ActivityLogDetailsContent({
    required this.log,
    required this.targetDetails,
    required this.isLoading,
    required this.hasError,
    required this.actionLabel,
    required this.formattedDate,
  });

  final AdminActivityLog log;
  final AdminActivityLogTargetDetails? targetDetails;
  final bool isLoading;
  final bool hasError;
  final String actionLabel;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailsSection(
            title: 'Log',
            children: [
              _DetailRow(label: 'Action', value: actionLabel),
              _DetailRow(label: 'Raw action', value: log.action),
              _DetailRow(label: 'Admin ID', value: log.adminId),
              _DetailRow(
                label: 'Target type',
                value: log.targetType?.replaceAll('_', ' ') ?? '-',
              ),
              _DetailRow(label: 'Target ID', value: log.targetId ?? '-'),
              _DetailRow(label: 'Created at', value: formattedDate),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (hasError)
            const _EmptyDetailsMessage('Unable to load target details.')
          else if (targetDetails == null)
            const _EmptyDetailsMessage(
              'This log does not have a target record.',
            )
          else
            _TargetDetailsView(details: targetDetails!),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}

class _TargetDetailsView extends StatelessWidget {
  const _TargetDetailsView({required this.details});

  final AdminActivityLogTargetDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.postDetails != null) {
      return _LogPostDetails(details: details.postDetails!);
    }
    if (details.comment != null) {
      return _LogCommentDetails(
        comment: details.comment!,
        relatedPost: details.relatedPost,
        fields: details.fields,
      );
    }

    return _DetailsSection(
      title: details.title,
      children: [
        for (final entry in details.fields.entries)
          _DetailRow(label: entry.key, value: entry.value),
      ],
    );
  }
}

class _LogPostDetails extends StatelessWidget {
  const _LogPostDetails({required this.details});

  final AdminCommunityPostDetails details;

  @override
  Widget build(BuildContext context) {
    final post = details.post;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailsSection(
          title: 'Post Details',
          children: [
            _DetailRow(label: 'Post ID', value: post.id),
            _DetailRow(label: 'Author', value: post.displayAuthor),
            _DetailRow(label: 'Patient ID', value: post.patientId),
            _DetailRow(label: 'Status', value: post.status),
            _DetailRow(label: 'Likes', value: details.likes.length.toString()),
            _DetailRow(
              label: 'Comments',
              value: details.comments.length.toString(),
            ),
            _DetailRow(
              label: 'Images',
              value: post.imageUrls.length.toString(),
            ),
            _DetailRow(label: 'Created at', value: _formatDate(post.createdAt)),
          ],
        ),
        const SizedBox(height: 12),
        _ContentBlock(title: 'Content', value: post.content),
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ImageGrid(imageUrls: post.imageUrls),
        ],
        const SizedBox(height: 18),
        _DetailsSection(
          title: 'Liked by',
          children: details.likes.isEmpty
              ? const [_EmptyDetailsMessage('No likes.')]
              : [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final like in details.likes)
                        _PersonChip(
                          name: like.displayAuthor,
                          imageUrl: like.authorAvatarUrl,
                        ),
                    ],
                  ),
                ],
        ),
        const SizedBox(height: 18),
        _DetailsSection(
          title: 'Comments',
          children: details.comments.isEmpty
              ? const [_EmptyDetailsMessage('No comments.')]
              : [_CommentThreadList(comments: details.comments)],
        ),
      ],
    );
  }
}

class _LogCommentDetails extends StatelessWidget {
  const _LogCommentDetails({
    required this.comment,
    required this.relatedPost,
    required this.fields,
  });

  final AdminCommunityComment comment;
  final AdminCommunityPost? relatedPost;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailsSection(
          title: 'Comment Details',
          children: [
            for (final entry in fields.entries)
              _DetailRow(label: entry.key, value: entry.value),
          ],
        ),
        const SizedBox(height: 12),
        _CommentCard(comment: comment),
        if (relatedPost != null) ...[
          const SizedBox(height: 18),
          _DetailsSection(
            title: 'Related Post',
            children: [
              _DetailRow(label: 'Post ID', value: relatedPost!.id),
              _DetailRow(label: 'Author', value: relatedPost!.displayAuthor),
              _DetailRow(label: 'Status', value: relatedPost!.status),
              _DetailRow(
                label: 'Created at',
                value: _formatDate(relatedPost!.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContentBlock(title: 'Post content', value: relatedPost!.content),
          if (relatedPost!.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImageGrid(imageUrls: relatedPost!.imageUrls),
          ],
        ],
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: const TextStyle(color: Color(0xFF17201D), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imageUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE7ECE9),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFBFE8D8),
            backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                    style: const TextStyle(fontSize: 11),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentThreadList extends StatelessWidget {
  const _CommentThreadList({required this.comments});

  final List<AdminCommunityComment> comments;

  @override
  Widget build(BuildContext context) {
    final commentIds = comments.map((comment) => comment.id).toSet();
    final commentsByParentId = <String?, List<AdminCommunityComment>>{};

    for (final comment in comments) {
      final parentId = commentIds.contains(comment.parentId)
          ? comment.parentId
          : null;
      commentsByParentId.putIfAbsent(parentId, () => []).add(comment);
    }

    return Column(
      children: [
        for (final comment in commentsByParentId[null] ?? const [])
          _CommentThreadTile(
            comment: comment,
            commentsByParentId: commentsByParentId,
          ),
      ],
    );
  }
}

class _CommentThreadTile extends StatelessWidget {
  const _CommentThreadTile({
    required this.comment,
    required this.commentsByParentId,
    this.depth = 0,
  });

  final AdminCommunityComment comment;
  final Map<String?, List<AdminCommunityComment>> commentsByParentId;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final replies = commentsByParentId[comment.id] ?? const [];
    final clampedDepth = depth > 3 ? 3 : depth;

    return Padding(
      padding: EdgeInsets.only(left: clampedDepth * 18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (depth > 0)
              Container(
                width: 2,
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E4DE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _CommentCard(comment: comment),
                  for (final reply in replies)
                    _CommentThreadTile(
                      comment: reply,
                      commentsByParentId: commentsByParentId,
                      depth: depth + 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final AdminCommunityComment comment;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.authorAvatarUrl;
    final hasImage = avatarUrl?.trim().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECE9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFBFE8D8),
            backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    comment.displayAuthor.trim().isEmpty
                        ? '?'
                        : comment.displayAuthor.trim()[0].toUpperCase(),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.displayAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17201D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (comment.isDeleted) ...[
                      const SizedBox(width: 8),
                      const _CommentStatusBadge(label: 'Deleted'),
                    ],
                    if (comment.isArchived) ...[
                      const SizedBox(width: 8),
                      const _CommentStatusBadge(label: 'Archived'),
                    ],
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF66736F),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  comment.content,
                  style: const TextStyle(
                    color: Color(0xFF46534F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentStatusBadge extends StatelessWidget {
  const _CommentStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDeleted = label == 'Deleted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDeleted ? const Color(0xFFFFECEC) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDeleted ? const Color(0xFFB3261E) : const Color(0xFF8A5A00),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyDetailsMessage extends StatelessWidget {
  const _EmptyDetailsMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: Color(0xFF66736F),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66736F),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Color(0xFF17201D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogChip extends StatelessWidget {
  const _LogChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF66736F),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
