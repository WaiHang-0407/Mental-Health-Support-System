// controllers/comment_controller.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../repositories/comment_repository.dart';

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

  Future<void> addComment(String postId, String content, {String? parentId}) async {
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

  Future<void> reportComment(String commentId, String reason) async {
    await _repo.reportComment(commentId, reason);
  }
}