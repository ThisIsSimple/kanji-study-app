class FavoriteCrdtState {
  const FavoriteCrdtState({
    required this.userId,
    required this.type,
    required this.targetId,
    required this.isFavorite,
    required this.operationTimestamp,
    required this.operationId,
    required this.deviceId,
    this.note,
    this.createdAt,
  });

  final String userId;
  final String type;
  final int targetId;
  final bool isFavorite;
  final DateTime operationTimestamp;
  final String operationId;
  final String deviceId;
  final String? note;
  final DateTime? createdAt;

  String get key => '$type-$targetId';

  bool isNewerThan(FavoriteCrdtState other) {
    final timestampComparison = operationTimestamp.compareTo(
      other.operationTimestamp,
    );
    if (timestampComparison != 0) {
      return timestampComparison > 0;
    }
    return operationId.compareTo(other.operationId) > 0;
  }
}

FavoriteCrdtState mergeFavoriteStates(
  FavoriteCrdtState first,
  FavoriteCrdtState second,
) {
  return first.isNewerThan(second) ? first : second;
}
