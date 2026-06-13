import 'package:flutter_supabase_tasks_demo/features/tasks/domain/task.dart';
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
}
