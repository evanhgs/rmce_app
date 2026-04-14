class FriendModel {
  const FriendModel({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
  });

  final int id;
  final String username;
  final String email;
  final String status;

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'accepted',
    );
  }
}

class FriendRequestModel {
  const FriendRequestModel({
    required this.friendshipId,
    required this.id,
    required this.username,
    required this.email,
    required this.status,
  });

  final int friendshipId;
  final int id;
  final String username;
  final String email;
  final String status;

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      friendshipId: json['friendship_id'] as int,
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}
