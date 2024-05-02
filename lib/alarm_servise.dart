import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static const String alarmKey = 'alarms';

  static Future<List<DateTime>> getAlarmHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? alarmList = prefs.getStringList(alarmKey);
    if (alarmList != null) {
      return alarmList.map((String alarm) => DateTime.parse(alarm)).toList();
    } else {
      return [];
    }
  }

  static Future<void> addToAlarmHistory(DateTime alarmTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<DateTime> alarms = await getAlarmHistory();
    alarms.add(alarmTime);
    List<String> alarmStrings =
        alarms.map((DateTime alarm) => alarm.toIso8601String()).toList();
    await prefs.setStringList(alarmKey, alarmStrings);
  }

  static Future<void> removeFromAlarmHistory(DateTime alarmTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<DateTime> alarms = await getAlarmHistory();
    alarms.remove(alarmTime);
    List<String> alarmStrings =
        alarms.map((DateTime alarm) => alarm.toIso8601String()).toList();
    await prefs.setStringList(alarmKey, alarmStrings);
  }

  static Future<void> clearAlarmHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(alarmKey);
  }
}
