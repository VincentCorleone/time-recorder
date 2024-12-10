import 'package:flutter/material.dart';
import 'dart:async';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ClockPage extends StatefulWidget {
  final String task;
  final DateTime? resumeStartTime;

  const ClockPage({
    super.key,
    required this.task,
    this.resumeStartTime,
  });

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  int hours = 0;
  int elapsedMinutes = 0;
  int seconds = 0;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late DateTime startTime;

  @override
  void initState() {
    super.initState();
    // 使用恢复时间或当前时间
    startTime = widget.resumeStartTime ?? DateTime.now();

    // 如果是恢复的任务，计算已经过的时间
    if (widget.resumeStartTime != null) {
      final elapsed = DateTime.now().difference(widget.resumeStartTime!);
      hours = elapsed.inHours;
      elapsedMinutes = (elapsed.inMinutes % 60);
      seconds = (elapsed.inSeconds % 60);
    }

    // 保存未完成任务
    DatabaseHelper.instance.saveUnfinishedTask(widget.task, startTime);

    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _animationController.repeat();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // 检查是否到达23:59
      if (now.hour == 23 && now.minute == 59) {
        _autoComplete();
        return;
      }

      setState(() {
        final elapsed = DateTime.now().difference(widget.resumeStartTime!);
        hours = elapsed.inHours;
        elapsedMinutes = (elapsed.inMinutes % 60);
        seconds = (elapsed.inSeconds % 60);
      });
    });
  }

  // 添加自动完成方法
  void _autoComplete() async {
    final navigatorContext = context as BuildContext;
    _timer.cancel();
    _animationController.stop();

    // 显示提示信息
    ScaffoldMessenger.of(navigatorContext).showSnackBar(
      SnackBar(
        content: Text('一天已结束，自动完成任务'),
        duration: Duration(seconds: 2),
      ),
    );

    await _saveTaskToDatabase();

    // 等待 2 秒让用户看提示
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      Navigator.of(navigatorContext).pop();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveTaskToDatabase() async {
    final endTime = DateTime.now();
    try {
      await DatabaseHelper.instance.clearUnfinishedTask();
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tasks.db');
      print('SQLite数据库文件路径: $path');

      await DatabaseHelper.instance.insertTask(
        widget.task,
        startTime,
        endTime,
      );
      print('任务已保存到数据库');
    } catch (e) {
      print('保存任务时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('任务详情'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '您的任务是：${widget.task}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              '已专注时间',
              style: TextStyle(fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _animation,
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  '$hours小时$elapsedMinutes分钟',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(35),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                _timer.cancel();
                _animationController.stop();
                await _saveTaskToDatabase();
                Navigator.of(context).pop();
              },
              child: Text(
                '完成',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}