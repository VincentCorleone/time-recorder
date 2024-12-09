import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'clock_page.dart';
import 'database_helper.dart';
import 'day_records_page.dart';
import 'package:table_calendar/table_calendar.dart';

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

    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        debugShowCheckedModeBanner: false,
        home: home,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    MyHomePage(),
    TodayRecordsPage(),
    HistoryRecordsPage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // 关闭抽屉
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['开始记录', '今日记录', '历史记录'][_selectedIndex]),
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              '时间记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.play_circle_outline),
            label: Text('开始记录'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.today),
            label: Text('今日记录'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.history),
            label: Text('历史记录'),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class MyHomePage extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '您接下来要做什么?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '请输入您的计划',
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(35),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  String task = _controller.text;
                  if (task.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClockPage(task: task),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('提示'),
                        content: Text('请输入您要做的事情'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('确定'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text(
                  '开始',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          final tasks = await DatabaseHelper.instance.getTodayTasks();
          final formattedText = tasks.map((task) {
            final startTime = DateTime.parse(task['startTime']);
            final endTime = DateTime.parse(task['endTime']);
            return '${_formatTime(startTime)}~${_formatTime(endTime)} [${task['duration']}分钟] ${task['name']}';
          }).join('\n');

          await Clipboard.setData(ClipboardData(text: formattedText));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('日志已复制到剪贴板')),
          );
        },
        child: Icon(Icons.copy),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class HistoryRecordsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: DateTime.now(),
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DayRecordsPage(
                  selectedDate: selectedDay,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // 可以在这里添加需要的状态
}
