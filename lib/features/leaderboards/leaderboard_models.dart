class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.timeSeconds,
    required this.maxSpeedKmh,
    required this.createdAt,
  });

  final int userId;
  final String username;
  final double? timeSeconds;
  final double? maxSpeedKmh;
  final DateTime createdAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as int,
      username: json['username'] as String? ?? 'Utilisateur',
      timeSeconds: (json['time_seconds'] as num?)?.toDouble(),
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
