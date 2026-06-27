import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/empty_state.dart';
import '../data/tasks_repository.dart';
import '../domain/task.dart';
import '../domain/task_suggestion.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _supabase = Supabase.instance.client;
  final _taskController = TextEditingController();
  late final TasksRepository _repository;
  late final Stream<List<Task>> _tasksStream;

  bool _saving = false;
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _repository = TasksRepository(client: _supabase);
    _tasksStream = _repository.watchTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _taskController.text;
    if (title.trim().isEmpty) return;

    setState(() => _saving = true);

    try {
      await _repository.addTask(title);
      _taskController.clear();
    } catch (error) {
      _showMessage('No se pudo crear la tarea: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      await _repository.updateTaskStatus(id: task.id, isDone: !task.isDone);
    } catch (error) {
      _showMessage('No se pudo actualizar la tarea: $error', isError: true);
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _repository.deleteTask(task.id);
      _showMessage('Tarea eliminada.');
    } catch (error) {
      _showMessage('No se pudo eliminar la tarea: $error', isError: true);
    }
  }

  Future<void> _showSuggestions() async {
    setState(() => _loadingSuggestions = true);

    try {
      final suggestions = await _repository.getTaskSuggestions();
      if (!mounted) return;
      await _openSuggestionsSheet(suggestions);
    } catch (error) {
      _showMessage('No se pudieron cargar sugerencias: $error', isError: true);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _openSuggestionsSheet(List<TaskSuggestion> suggestions) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sugerencias',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No hay sugerencias disponibles.'),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return _SuggestionTile(
                            suggestion: suggestion,
                            onAccept: () => _acceptSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptSuggestion(TaskSuggestion suggestion) async {
    try {
      await _repository.addTask(suggestion.title);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Sugerencia agregada como tarea.');
    } catch (error) {
      _showMessage('No se pudo agregar la sugerencia: $error', isError: true);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Sugerir tareas',
              onPressed: _loadingSuggestions ? null : _showSuggestions,
              icon: _loadingSuggestions
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Cerrar sesión',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flutter + Supabase Tasks',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Usuario: ${user?.email ?? user?.id ?? 'sesión activa'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 560;
                              final input = TextField(
                                controller: _taskController,
                                enabled: !_saving,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addTask(),
                                decoration: const InputDecoration(
                                  labelText: 'Nueva tarea',
                                  hintText: 'Ej: Preparar demo de Supabase',
                                  prefixIcon: Icon(Icons.task_alt),
                                ),
                              );

                              final button = FilledButton.icon(
                                onPressed: _saving ? null : _addTask,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add),
                                label: const Text('Agregar'),
                              );

                              if (isCompact) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    input,
                                    const SizedBox(height: 12),
                                    button,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: input),
                                  const SizedBox(width: 12),
                                  button,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Task>>(
                      stream: _tasksStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return EmptyState(
                            icon: Icons.error_outline,
                            title: 'No se pudieron cargar las tareas',
                            message: snapshot.error.toString(),
                          );
                        }

                        final tasks = snapshot.data ?? [];

                        if (tasks.isEmpty) {
                          return const EmptyState(
                            icon: Icons.playlist_add_check_circle_outlined,
                            title: 'Aún no tienes tareas',
                            message:
                                'Crea una tarea para ver CRUD + Realtime funcionando.',
                          );
                        }

                        return ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _TaskTile(
                              task: task,
                              onToggle: () => _toggleTask(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.onAccept,
  });

  final TaskSuggestion suggestion;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  suggestion.isEvent
                      ? Icons.event_available
                      : Icons.task_alt,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.add),
                label: Text(
                  suggestion.isEvent ? 'Agregar como tarea' : 'Agregar tarea',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Checkbox(value: task.isDone, onChanged: (_) => onToggle()),
        title: Text(
          task.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Creada: ${_formatDate(task.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Eliminar',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    final day = twoDigits(date.day);
    final month = twoDigits(date.month);
    final hour = twoDigits(date.hour);
    final minute = twoDigits(date.minute);

    return '$day/$month/${date.year} $hour:$minute';
  }
}
