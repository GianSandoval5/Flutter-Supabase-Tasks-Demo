import 'package:flutter_supabase_tasks_demo/features/tasks/domain/task.dart';
import 'package:flutter_supabase_tasks_demo/features/tasks/domain/task_automation_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task.fromMap reads Supabase task rows', () {
    final createdAt = DateTime.utc(2026, 6, 12, 18, 30);

    final task = Task.fromMap({
      'id': '42',
      'title': 'Preparar demo de Supabase',
      'is_done': true,
      'created_at': createdAt.toIso8601String(),
      'user_id': 'user-123',
    });

    expect(task.id, 42);
    expect(task.title, 'Preparar demo de Supabase');
    expect(task.isDone, isTrue);
    expect(task.createdAt, createdAt);
    expect(task.userId, 'user-123');
  });

  test('Task.fromMap keeps safe defaults for optional values', () {
    final task = Task.fromMap({
      'id': 7,
      'title': null,
      'is_done': null,
      'created_at': 'not-a-date',
    });

    expect(task.id, 7);
    expect(task.title, isEmpty);
    expect(task.isDone, isFalse);
    expect(task.createdAt, isA<DateTime>());
    expect(task.userId, isNull);
  });

  test('TaskAutomationRun.fromMap reads function run rows', () {
    final createdAt = DateTime.utc(2026, 6, 26, 13);

    final run = TaskAutomationRun.fromMap({
      'id': '9',
      'run_type': 'manual',
      'source': 'flutter-emulator',
      'total_tasks': '5',
      'pending_tasks': 2,
      'completed_tasks': 3,
      'notes': 'Demo',
      'created_at': createdAt.toIso8601String(),
    });

    expect(run.id, 9);
    expect(run.runType, 'manual');
    expect(run.source, 'flutter-emulator');
    expect(run.totalTasks, 5);
    expect(run.pendingTasks, 2);
    expect(run.completedTasks, 3);
    expect(run.notes, 'Demo');
    expect(run.createdAt, createdAt);
  });
}
