import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'navigator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Alarm.init(showDebugLogs: true);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          scaffoldBackgroundColor: Colors.blueGrey,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey, brightness: Brightness.dark)),
      home: const TabBarNavigation(),
      //  home: const ExampleAlarmHomeScreen(),
    ),
  );
}
