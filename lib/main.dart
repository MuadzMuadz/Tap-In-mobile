import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://uzyzqjwxaqellztmgxxy.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eXpxand4YXFlbGx6dG1neHh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MjgzOTAsImV4cCI6MjA4NzQwNDM5MH0.IamIeYZQUHAjagmcT_cpnxww3elEtb3AVBpGHeMcRJU',
    ),
  );

  runApp(
    const ProviderScope(
      child: TapInApp(),
    ),
  );
}
