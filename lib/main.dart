import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_app/core/router/app_router.dart';
import 'package:erp_app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yhhnawlhcjbgliramtyc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InloaG5hd2xoY2piZ2xpcmFtdHljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNjg3NTgsImV4cCI6MjA5Njk0NDc1OH0.nau9Qp9MdtwPjpWQzJnzVrn6cG8BPYCNu59zY0LG8KA',
  );

  runApp(const ProviderScope(child: ErpApp()));
}

class ErpApp extends ConsumerWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FeedERP',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.system,
      routerConfig: router,
    );
  }
}
