class TaskAutomationRun {
  const TaskAutomationRun({
    required this.id,
    required this.runType,
    required this.source,
    required this.totalTasks,
    required this.pendingTasks,
    required this.completedTasks,
    required this.createdAt,
    this.notes,
  });

  final int id;
  final String runType;
  final String source;
  final int totalTasks;
  final int pendingTasks;
  final int completedTasks;
  final DateTime createdAt;
  final String? notes;

  factory TaskAutomationRun.fromMap(Map<String, dynamic> map) {
    return TaskAutomationRun(
      id: _readInt(map['id']),
      runType: map['run_type'] as String? ?? 'manual',
      source: map['source'] as String? ?? 'edge-function',
      totalTasks: _readInt(map['total_tasks']),
      pendingTasks: _readInt(map['pending_tasks']),
      completedTasks: _readInt(map['completed_tasks']),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      notes: map['notes']?.toString(),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return 0;
    return int.parse(value.toString());
  }
}
