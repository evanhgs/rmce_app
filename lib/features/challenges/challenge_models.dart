class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.routeId,
    required this.challengerId,
    required this.challengedId,
    required this.status,
    required this.challengerTime,
    required this.challengedTime,
    required this.winnerId,
    required this.createdAt,
    required this.completedAt,
  });

  final int id;
  final int routeId;
  final int challengerId;
  final int? challengedId;
  final String status;
  final double? challengerTime;
  final double? challengedTime;
  final int? winnerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as int,
      routeId: json['route_id'] as int,
      challengerId: json['challenger_id'] as int,
      challengedId: json['challenged_id'] as int?,
      status: json['status'] as String? ?? 'pending',
      challengerTime: (json['challenger_time'] as num?)?.toDouble(),
      challengedTime: (json['challenged_time'] as num?)?.toDouble(),
      winnerId: json['winner_id'] as int?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }
}
