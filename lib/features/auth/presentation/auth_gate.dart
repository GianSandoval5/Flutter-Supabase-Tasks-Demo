import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../tasks/presentation/tasks_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  late final Stream<AuthState> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _authStateChanges = _supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : _supabase.auth.currentSession;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: session == null
              ? const LoginPage(key: ValueKey('login'))
              : const TasksPage(key: ValueKey('tasks')),
        );
      },
    );
  }
}
