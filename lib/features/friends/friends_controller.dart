import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/geo_websocket_service.dart';
import 'friends_models.dart';
import 'friends_repository.dart';

class FriendsState {
  const FriendsState({
    required this.isLoading,
    required this.friends,
    required this.pendingRequests,
    required this.locations,
    required this.isSocketConnected,
    this.feedbackMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final List<FriendModel> friends;
  final List<FriendRequestModel> pendingRequests;
  final Map<int, FriendLocation> locations;
  final bool isSocketConnected;
  final String? feedbackMessage;
  final String? errorMessage;

  const FriendsState.initial()
      : isLoading = false,
        friends = const [],
        pendingRequests = const [],
        locations = const {},
        isSocketConnected = false,
        feedbackMessage = null,
        errorMessage = null;

  FriendsState copyWith({
    bool? isLoading,
    List<FriendModel>? friends,
    List<FriendRequestModel>? pendingRequests,
    Map<int, FriendLocation>? locations,
    bool? isSocketConnected,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      locations: locations ?? this.locations,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      feedbackMessage:
          clearFeedback ? null : feedbackMessage ?? this.feedbackMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FriendsController {
  FriendsController({
    required FriendsRepository repository,
    GeoWebSocketService? geoService,
  })  : _repository = repository,
        _geoService = geoService ?? GeoWebSocketService();

  final FriendsRepository _repository;
  final GeoWebSocketService _geoService;
  final ValueNotifier<FriendsState> state =
      ValueNotifier(const FriendsState.initial());

  StreamSubscription<FriendLocation>? _locationSubscription;
  StreamSubscription<bool>? _socketSubscription;

  Future<void> initialize({required bool isLoggedIn}) async {
    if (!isLoggedIn) {
      _geoService.disconnect();
      state.value = const FriendsState.initial();
      return;
    }

    await _connectSocket();
    await load();
  }

  Future<void> _connectSocket() async {
    await _geoService.connect();
    await _locationSubscription?.cancel();
    await _socketSubscription?.cancel();

    _locationSubscription = _geoService.locationStream.listen((location) {
      final updated = Map<int, FriendLocation>.from(state.value.locations);
      updated[location.userId] = location;
      state.value = state.value.copyWith(locations: updated);
    });
    _socketSubscription = _geoService.connectionStream.listen((connected) {
      state.value = state.value.copyWith(isSocketConnected: connected);
    });
  }

  Future<void> load() async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);
    try {
      final friends = await _repository.getFriends();
      final pending = await _repository.getPendingRequests();
      state.value = state.value.copyWith(
        isLoading: false,
        friends: friends,
        pendingRequests: pending,
        isSocketConnected: _geoService.isConnected,
      );
    } catch (error) {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> addFriend(String username) async {
    try {
      await _repository.addFriend(username);
      state.value = state.value.copyWith(
        feedbackMessage: 'Invitation envoyée.',
        clearError: true,
      );
      await load();
    } catch (error) {
      state.value = state.value.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> accept(int friendshipId) async {
    try {
      await _repository.accept(friendshipId);
      await load();
    } catch (error) {
      state.value = state.value.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> reject(int friendshipId) async {
    try {
      await _repository.reject(friendshipId);
      await load();
    } catch (error) {
      state.value = state.value.copyWith(errorMessage: error.toString());
    }
  }

  void dispose() {
    _locationSubscription?.cancel();
    _socketSubscription?.cancel();
    _geoService.disconnect();
    state.dispose();
  }
}
