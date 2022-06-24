import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:mtkp/utils/notification_utils.dart';
import 'package:mtkp/workers/background_worker.dart';
import 'adminPanel/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  DatabaseWorker();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (!kIsWeb && Platform.isAndroid) {
    NotificationHandler().initializePlugin();
    initAlarmManager();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.rubik();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
              color: Colors.white, foregroundColor: Colors.black, elevation: 1),
          primaryColorLight: const Color(0xFF00bbf9),
          textTheme: TextTheme(
              headline6: font,
              headline5: font,
              bodyText2: font,
              button: font.copyWith(color: Colors.black, fontSize: 16))),
    );
  }
}
