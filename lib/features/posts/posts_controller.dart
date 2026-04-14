import 'package:flutter/foundation.dart';

import 'post_models.dart';
import 'posts_repository.dart';

class PostsState {
  const PostsState({
    required this.isLoading,
    required this.posts,
    this.feedbackMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final List<PostModel> posts;
  final String? feedbackMessage;
  final String? errorMessage;

  const PostsState.initial()
      : isLoading = false,
        posts = const [],
        feedbackMessage = null,
        errorMessage = null;

  PostsState copyWith({
    bool? isLoading,
    List<PostModel>? posts,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return PostsState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      feedbackMessage:
          clearFeedback ? null : feedbackMessage ?? this.feedbackMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PostsController {
  PostsController({required PostsRepository repository})
      : _repository = repository;

  final PostsRepository _repository;
  final ValueNotifier<PostsState> state =
      ValueNotifier(const PostsState.initial());

  Future<void> load() async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await _repository.getPosts();
      state.value = state.value.copyWith(isLoading: false, posts: posts);
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> create({
    required int userId,
    required String title,
    required String body,
  }) async {
    try {
      await _repository.createPost(
        userId: userId,
        title: title,
        body: body,
      );
      state.value = state.value.copyWith(
        feedbackMessage: 'Publication envoyée.',
        clearError: true,
      );
      await load();
    } catch (error) {
      state.value = state.value.copyWith(errorMessage: error.toString());
    }
  }
}
