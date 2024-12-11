import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/database_helper.dart';
import '../utils/time_formatter.dart';

class DayRecordsPage extends StatelessWidget {
  final DateTime selectedDate;

  const DayRecordsPage({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日的记录'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getDayTasks(selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          
          if (tasks.isEmpty) {
            return Center(child: Text('这一天没有任何任务记录'));
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
                    '${_formatTime(startTime)}~${_formatTime(endTime)}',
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
          final tasks = await DatabaseHelper.instance.getDayTasks(selectedDate);
          
          // 计算总时间
          int totalMinutes = tasks.fold(0, (sum, task) => sum + (task['duration'] as int));
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
当日总计：$totalHours小时$remainingMinutes分钟''';

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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 