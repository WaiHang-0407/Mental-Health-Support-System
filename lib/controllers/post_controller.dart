// controllers/post_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

class PostController extends ChangeNotifier {
  final PostRepository _repo = PostRepository();
  List<Post> posts = [];
  List<Post> myPosts = []; // includes archived
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> loadFeed() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      posts = await _repo.getFeed();
    } catch (e) {
      error = e.toString();
      debugPrint('loadFeed error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyPosts() async {
    isLoading = true;
    notifyListeners();
    try {
      myPosts = await _repo.getMyPosts();
    } catch (e) {
      debugPrint('loadMyPosts error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost(
    String content, {
    List<File> images = const [],
  }) async {
    isSaving = true;
    notifyListeners();
    try {
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _repo.uploadPostImages(images);
      }
      await _repo.createPost(content, imageUrls: imageUrls);
      await loadFeed();
      return true;
    } catch (e) {
      debugPrint('createPost error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.softDeletePost(postId);
      posts = posts.where((p) => p.id != postId).toList();
      myPosts = myPosts.where((p) => p.id != postId).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('deletePost error: $e');
    }
  }

  Future<void> toggleArchive(Post post) async {
    try {
      await _repo.toggleArchive(post.id, post.isArchived);
      // Remove from public feed if archiving
      if (!post.isArchived) {
        posts = posts.where((p) => p.id != post.id).toList();
      }
      // Update in myPosts
      final i = myPosts.indexWhere((p) => p.id == post.id);
      if (i != -1) {
        myPosts[i] = Post(
          id: post.id,
          patientId: post.patientId,
          content: post.content,
          imageUrls: post.imageUrls,
          isDeleted: post.isDeleted,
          isArchived: !post.isArchived, // 👈 flip
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          isLiked: post.isLiked,
          isSaved: post.isSaved,
          authorName: post.authorName,
          createdAt: post.createdAt,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggleArchive error: $e');
    }
  }

  Future<void> toggleLike(Post post) async {
    final i = posts.indexWhere((p) => p.id == post.id);
    if (i == -1) return;
    posts[i] = Post(
      id: post.id,
      patientId: post.patientId,
      content: post.content,
      imageUrls: post.imageUrls,
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
      commentCount: post.commentCount,
      isSaved: post.isSaved,
      authorName: post.authorName,
      createdAt: post.createdAt,
    );
    notifyListeners();
    try {
      await _repo.toggleLike(post.id, post.isLiked);
    } catch (e) {
      posts[i] = post;
      notifyListeners();
    }
  }

  Future<void> toggleSave(Post post) async {
    final i = posts.indexWhere((p) => p.id == post.id);
    if (i == -1) return;
    posts[i] = Post(
      id: post.id,
      patientId: post.patientId,
      content: post.content,
      imageUrls: post.imageUrls,
      isLiked: post.isLiked,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isSaved: !post.isSaved,
      authorName: post.authorName,
      createdAt: post.createdAt,
    );
    notifyListeners();
    try {
      await _repo.toggleSave(post.id, post.isSaved);
    } catch (e) {
      posts[i] = post;
      notifyListeners();
    }
  }

  Future<bool> reportPost(Post post, String reason) async {
    try {
      await _repo.reportPost(
        postId: post.id,
        postOwnerId: post.patientId,
        reason: reason,
      );
      return true;
    } catch (e) {
      debugPrint('reportPost error: $e');
      return false;
    }
  }
}
