import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/config/supabase_bootstrap.dart';
import 'package:waiting_room_app/queue_provider.dart';
import 'package:waiting_room_app/screens/queue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseReady = await SupabaseBootstrap.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => QueueProvider(
        supabase: supabaseReady ? Supabase.instance.client : null,
        isDemo: !supabaseReady,
      )..initialize(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Waiting Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const QueueScreen(),
    );
  }
}
