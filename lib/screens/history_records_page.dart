import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'day_records_page.dart';

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