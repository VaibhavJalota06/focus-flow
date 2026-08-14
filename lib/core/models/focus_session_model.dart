class FocusSessionModel {
  final String id;
  final String? taskId;
  final String taskTitle;
  final int durationMinutes;
  final bool completed;
  final DateTime startedAt;
  final DateTime endedAt;

  const FocusSessionModel({
    required this.id,
    this.taskId,
    required this.taskTitle,
    required this.durationMinutes,
    required this.completed,
    required this.startedAt,
    required this.endedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'durationMinutes': durationMinutes,
      'completed': completed ? 1 : 0,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String,
      taskId: map['taskId'] as String?,
      taskTitle: map['taskTitle'] as String,
      durationMinutes: map['durationMinutes'] as int,
      completed: (map['completed'] as int? ?? 0) == 1,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: DateTime.parse(map['endedAt'] as String),
    );
  }
}
