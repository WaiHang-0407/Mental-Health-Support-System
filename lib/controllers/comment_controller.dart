// controllers/comment_controller.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../repositories/comment_table_repository.dart';

class CommentController extends ChangeNotifier {
  final CommentRepository _repo = CommentRepository();
  List<Comment> comments = [];
  bool isLoading = false;

  Future<void> loadComments(String postId) async {
    isLoading = true;
    notifyListeners();
    comments = await _repo.getComments(postId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    await _repo.addComment(postId, content, parentId: parentId);
    await loadComments(postId);
  }

  Future<void> deleteComment(String commentId, String postId) async {
    await _repo.softDeleteComment(commentId);
    await loadComments(postId);
  }

  Future<void> toggleLike(String commentId, bool isLiked, String postId) async {
    await _repo.toggleLike(commentId, isLiked);
    await loadComments(postId);
  }

  Future<bool> reportComment(Comment comment, String reason) async {
    try {
      await _repo.reportComment(
        commentId: comment.id,
        commentOwnerId: comment.patientId,
        reason: reason,
      );
      return true;
    } catch (e) {
      debugPrint('reportComment error: $e');
      return false;
    }
  }

  Future<void> hideComment(Comment comment, String postId) async {
    try {
      await _repo.hideComment(comment.id);
      await loadComments(postId);
    } catch (e) {
      debugPrint('hideComment error: $e');
    }
  }
}
