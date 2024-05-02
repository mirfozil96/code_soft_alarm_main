import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<DateTime> _alarmHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAlarmHistory();
  }

  Future<void> _loadAlarmHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? alarmList = prefs.getStringList('alarms');
    if (alarmList != null) {
      setState(() {
        _alarmHistory =
            alarmList.map((String alarm) => DateTime.parse(alarm)).toList();
      });
    }
  }

  Future<void> _stopAlarm(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? alarmList = prefs.getStringList('alarms');
    if (alarmList != null &&
        alarmList.isNotEmpty &&
        index >= 0 &&
        index < alarmList.length) {
      alarmList.removeAt(index);
      await prefs.setStringList('alarms', alarmList);
      _loadAlarmHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _alarmHistory.isEmpty
          ? Center(
              child: Text(
                'No alarm history found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              itemCount: _alarmHistory.length,
              itemBuilder: (context, index) {
                DateTime alarmTime = _alarmHistory[index];
                return ListTile(
                  title: Text(
                    '${alarmTime.hour}:${alarmTime.minute} - ${alarmTime.day}/${alarmTime.month}/${alarmTime.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _stopAlarm(index),
                    child: const Text('Stop'),
                  ),
                );
              },
            ),
    );
  }
}
