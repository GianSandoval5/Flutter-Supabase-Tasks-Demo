import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/task.dart';

class TasksRepository {
  TasksRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<List<Task>> watchTasks() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Task.fromMap).toList());
  }

  Future<void> addTask(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    await _client.from('tasks').insert({'title': cleanTitle});
  }

  Future<void> updateTaskStatus({required int id, required bool isDone}) async {
    await _client.from('tasks').update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deleteTask(int id) async {
    await _client.from('tasks').delete().eq('id', id);
  }
}
