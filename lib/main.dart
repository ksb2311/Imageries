// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:simple_gallery/constants/strings.dart';
import 'package:simple_gallery/pages/about.dart';
import 'package:simple_gallery/pages/home.dart';
import 'package:simple_gallery/pages/settings.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  

  @override
  Widget build(BuildContext context) {
    String _selectedTheme = 'System Default';
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
      ),
    );

    ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
      ),
    );

    ThemeData getThemeData(String theme) {
      switch (theme) {
        case 'Light':
          return lightTheme;
        case 'Dark':
          return darkTheme;
        default:
          bool isDarkMode = brightness == Brightness.dark;
          if (!isDarkMode) {
            return lightTheme;
          } else {
            return darkTheme;
          }
      }
    }

    return MaterialApp(
      theme: getThemeData(_selectedTheme),
      // darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      title: "Photo Gallery",
      // themeMode: ThemeMode.dark, //or dark / system
      // theme: ThemeData(
      //   useMaterial3: true,
      // ),
      home: HomeScreen()
    );
  }
}


