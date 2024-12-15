import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/clock_page.dart';
import 'utils/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  // 在 Windows 和 Linux 上初始化 FFI
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namer App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseHelper.instance.getUnfinishedTask(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 数据加载中，展示加载指示器
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            // 处理错误情况
            return Scaffold(
              body: Center(child: Text('加载失败: ${snapshot.error}')),
            );
          } else {
            // 数据加载完成，展示主界面
            final unfinishedTask = snapshot.data;
            Widget home;
            if (unfinishedTask != null) {
              final taskName = unfinishedTask['name'];
              final startTime = DateTime.parse(unfinishedTask['startTime']);
              home = ClockPage(
                task: taskName,
                resumeStartTime: startTime,
              );
            } else {
              home = MainScreen();
            }
            return home;
          }
        },
      ),
    );
  }
}
