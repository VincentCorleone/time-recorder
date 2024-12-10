import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/clock_page.dart';
import 'utils/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final unfinishedTask = await DatabaseHelper.instance.getUnfinishedTask();
  runApp(MyApp(unfinishedTask: unfinishedTask));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? unfinishedTask;

  const MyApp({super.key, this.unfinishedTask});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (unfinishedTask != null) {
      final taskName = unfinishedTask!['name'];
      final startTime = DateTime.parse(unfinishedTask!['startTime']);
      home = ClockPage(
        task: taskName,
        resumeStartTime: startTime,
      );
    } else {
      home = MainScreen();
    }

    return MaterialApp(
      title: 'Namer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
