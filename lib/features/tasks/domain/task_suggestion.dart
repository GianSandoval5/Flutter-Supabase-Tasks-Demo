class TaskSuggestion {
  const TaskSuggestion({
    required this.title,
    required this.type,
    required this.reason,
  });

  final String title;
  final String type;
  final String reason;

  factory TaskSuggestion.fromMap(Map<String, dynamic> map) {
    return TaskSuggestion(
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'task',
      reason: map['reason'] as String? ?? '',
    );
  }

  bool get isEvent => type == 'event';
}
