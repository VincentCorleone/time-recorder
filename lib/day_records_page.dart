import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

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
          final formattedText = tasks.map((task) {
            final startTime = DateTime.parse(task['startTime']);
            final endTime = DateTime.parse(task['endTime']);
            return '${_formatTime(startTime)}~${_formatTime(endTime)} [${task['duration']}分钟] ${task['name']}';
          }).join('\n');

          await Clipboard.setData(ClipboardData(text: formattedText));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('日志已复制到��贴板')),
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