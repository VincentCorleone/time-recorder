import 'package:flutter/material.dart';
import 'home_page.dart';
import 'today_records_page.dart';
import 'history_records_page.dart';

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
    Navigator.pop(context);
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