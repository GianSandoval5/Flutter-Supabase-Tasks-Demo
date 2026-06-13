class Task {
  const Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    this.userId,
  });

  final int id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final String? userId;

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: _readInt(map['id']),
      title: map['title'] as String? ?? '',
      isDone: map['is_done'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      userId: map['user_id']?.toString(),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }
}
