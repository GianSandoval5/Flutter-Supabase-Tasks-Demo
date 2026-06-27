import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/task.dart';
import '../domain/task_automation_run.dart';
import '../domain/task_suggestion.dart';

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

  Future<TaskAutomationRun> runTaskAutomation() async {
    final response = await _client.functions.invoke(
      'task-automation',
      body: {
        'run_type': 'manual',
        'source': 'flutter-emulator',
        'notes': 'Ejecucion manual desde la app Flutter',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('Respuesta inesperada de la Function.');
    }

    final payload = Map<String, dynamic>.from(data);
    if (payload['ok'] != true) {
      throw StateError(payload['error']?.toString() ?? 'Function fallo.');
    }

    final run = payload['run'];
    if (run is! Map) {
      throw StateError('La Function no devolvio el registro de ejecucion.');
    }

    return TaskAutomationRun.fromMap(Map<String, dynamic>.from(run));
  }

  Future<List<TaskSuggestion>> getTaskSuggestions() async {
    final response = await _client.functions.invoke(
      'task-suggestions',
      body: {'limit': 4},
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('Respuesta inesperada de la Function.');
    }

    final payload = Map<String, dynamic>.from(data);
    if (payload['ok'] != true) {
      throw StateError(payload['error']?.toString() ?? 'Function fallo.');
    }

    final suggestions = payload['suggestions'];
    if (suggestions is! List) {
      throw StateError('La Function no devolvio sugerencias.');
    }

    return suggestions
        .whereType<Map>()
        .map((item) => TaskSuggestion.fromMap(Map<String, dynamic>.from(item)))
        .where((suggestion) => suggestion.title.trim().isNotEmpty)
        .toList(growable: false);
  }
}
