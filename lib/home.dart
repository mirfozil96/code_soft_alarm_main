import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cod_soft_alarm/edit_page.dart';
import 'package:cod_soft_alarm/ring.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'alarm_servise.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<AlarmSettings> alarms;
  late List<bool> alarmOnOff;

  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }
    loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(
      (alarmSettings) => navigateToRingScreen(alarmSettings),
    );
  }

  Future<void> loadAlarms() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      alarms = Alarm.getAlarms();
      alarmOnOff = List<bool>.filled(alarms.length, true);
      for (int i = 0; i < alarms.length; i++) {
        if (alarms[i].dateTime.year == 2050) {
          alarmOnOff[i] = false;
        } else {
          AlarmService.addToAlarmHistory(alarms[i].dateTime);
        }
      }
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExampleAlarmRingScreen(alarmSettings: alarmSettings),
      ),
    );
    loadAlarms();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExampleAlarmEditScreen(alarmSettings: settings),
      ),
    );

    if (res != null && res == true) loadAlarms();
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint('Requesting external storage permission...');
      final res = await Permission.storage.request();
      alarmPrint(
        'External storage permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Center(child: Realtime()),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => navigateToAlarmScreen(null),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            alarms.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        return _buildAlarmCard(alarms[index], index);
                      },
                    ),
                  )
                : Expanded(
                    child: Center(
                      child: Text(
                        "No alarms set",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(AlarmSettings alarm, int index) {
    TimeOfDay time = TimeOfDay.fromDateTime(alarm.dateTime);
    String formattedDate = DateFormat('EEE, d MMM').format(alarm.dateTime);
    return GestureDetector(
      onTap: () => navigateToAlarmScreen(alarms[index]),
      child: Slidable(
        closeOnScroll: true,
        endActionPane: ActionPane(
          extentRatio: 0.4,
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(12),
              onPressed: (context) {
                Alarm.stop(alarm.id);
                loadAlarms();
                AlarmService.removeFromAlarmHistory(alarm.dateTime);
              },
              icon: Icons.delete_forever,
              backgroundColor: Colors.red.shade700,
            )
          ],
        ),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(""),
              ListTile(
                splashColor: null,
                dense: true,
                minVerticalPadding: 10,
                horizontalTitleGap: 10,
                enabled: false,
                title: Row(
                  children: [
                    Text(
                      "${time.hour}:${time.minute.toString().padLeft(2, '0')} ",
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.start,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(time.period == DayPeriod.am ? 'AM' : 'PM'),
                    ),
                    const Expanded(child: Text("")),
                    Text(formattedDate),
                  ],
                ),
                trailing: Switch(
                  value: alarmOnOff[index],
                  onChanged: (bool value) {
                    if (value == false) {
                      Alarm.set(
                        alarmSettings: alarm.copyWith(
                          dateTime: alarm.dateTime.copyWith(year: 2050),
                        ),
                      );
                    } else {
                      Alarm.set(
                        alarmSettings: alarm.copyWith(
                          dateTime: alarm.dateTime.copyWith(
                            year: DateTime.now().year,
                          ),
                        ),
                      );
                    }
                    setState(() {
                      alarmOnOff[index] = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

//!

class Realtime extends StatefulWidget {
  const Realtime({super.key});

  @override
  RealtimeState createState() => RealtimeState();
}

class RealtimeState extends State<Realtime> {
  late StreamController<DateTime> _clockStreamController;
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockStreamController = StreamController<DateTime>();
    _startClock();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      _clockStreamController.add(_currentTime);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _clockStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _clockStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String formattedTime =
              DateFormat('hh:mm:ss a').format(snapshot.data!);

          return Text(
            formattedTime,
            style: Theme.of(context).textTheme.headlineLarge,
          );
        } else {
          return Text(
            "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
            style: Theme.of(context).textTheme.headlineLarge,
          );
        }
      },
    );
  }
}

// class AlarmService {
//   static const String alarmKey = 'alarms';

//   static Future<List<DateTime>> getAlarmHistory() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? alarmList = prefs.getStringList(alarmKey);
//     if (alarmList != null) {
//       return alarmList.map((String alarm) => DateTime.parse(alarm)).toList();
//     } else {
//       return [];
//     }
//   }

//   static Future<void> addToAlarmHistory(DateTime alarmTime) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<DateTime> alarms = await getAlarmHistory();
//     alarms.add(alarmTime);
//     List<String> alarmStrings =
//         alarms.map((DateTime alarm) => alarm.toIso8601String()).toList();
//     await prefs.setStringList(alarmKey, alarmStrings);
//   }

//   static Future<void> removeFromAlarmHistory(DateTime alarmTime) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<DateTime> alarms = await getAlarmHistory();
//     alarms.remove(alarmTime);
//     List<String> alarmStrings =
//         alarms.map((DateTime alarm) => alarm.toIso8601String()).toList();
//     await prefs.setStringList(alarmKey, alarmStrings);
//   }

//   static Future<void> clearAlarmHistory() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(alarmKey);
//   }
// }
