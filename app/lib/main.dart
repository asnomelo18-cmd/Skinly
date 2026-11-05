import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/routine_provider.dart';
import 'providers/photo_provider.dart';
import 'screens/home_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const SkinlyApp());
}

class SkinlyApp extends StatelessWidget {
  const SkinlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoutineProvider()..load()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Skinly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
