import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/database_helper.dart';
import '../utils/time_formatter.dart';

class TodayRecordsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getTodayTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('载失败: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(child: Text('今天还没有完成任何任务'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final startTime = DateTime.parse(task['startTime']);
              final endTime = DateTime.parse(task['endTime']);
              final duration = task['duration'];

              return Card(
                child: ListTile(
                  title: Text(task['name']),
                  subtitle: Text(
                    '${TimeFormatter.formatTime(startTime)}~${TimeFormatter.formatTime(endTime)}',
                  ),
                  trailing: Text('$duration分钟'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final tasks = await DatabaseHelper.instance.getTodayTasks();

          // 计算总时间
          int totalMinutes =
              tasks.fold(0, (sum, task) => sum + (task['duration'] as int));
          final totalHours = totalMinutes ~/ 60;
          final remainingMinutes = totalMinutes % 60;

          // 格式化任务列表
          final formattedText = tasks.map((task) {
            final startTime = DateTime.parse(task['startTime']);
            final endTime = DateTime.parse(task['endTime']);
            return '${TimeFormatter.formatTime(startTime)}~${TimeFormatter.formatTime(endTime)} [${task['duration']}分钟] ${task['name']}';
          }).join('\n');

          // 添加总时间统计
          final textWithTotal = '''$formattedText
----------------------------------------
今日总计：$totalHours小时$remainingMinutes分钟''';

          await Clipboard.setData(ClipboardData(text: textWithTotal));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('日志已复制到剪贴板')),
          );
        },
        backgroundColor: Colors.orange,
        child: Icon(Icons.copy),
      ),
    );
  }
}
