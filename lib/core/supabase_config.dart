class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void ensureConfigured() {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Faltan variables de entorno. Ejecuta el proyecto con:\n'
        'flutter run -d chrome '
        '--dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY',
      );
    }
  }
}
