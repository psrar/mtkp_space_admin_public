import 'dart:developer';

import 'package:mtkp/adminPanel/login_page.dart';
import 'package:mtkp/adminPanel/registration_page.dart';
import 'package:mtkp/adminPanel/subjects_view.dart';
import 'package:mtkp/adminPanel/teachers_view.dart';
import 'package:mtkp/adminPanel/timetable_editor.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mtkp/workers/shedule_worker.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Панель администратора',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
                splashRadius: 18,
                onPressed: () {
                  DatabaseWorker.currentUserNotifier.value = null;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false);
                },
                icon: const Icon(
                  Icons.logout_outlined,
                  color: Colors.orange,
                )),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredTextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'ВНИМАНИЕ',
                        style: TextStyle(color: Colors.red),
                      ),
                      content: const Text(
                          'Данное действие приведет к очистке текущего расписания из базы данных. Продолжить?'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  compute(_openShedules,
                                      DatabaseWorker.currentDatabaseWorker);
                                },
                                child: const Text(
                                  'Да',
                                  style: TextStyle(color: Colors.red),
                                )),
                            TextButton(
                                onPressed: () => {Navigator.of(context).pop()},
                                child: const Text('Нет'))
                          ],
                        ),
                      ],
                    ),
                  );
                },
                text: 'Разместить новое расписание',
                foregroundColor: Colors.white,
                boxColor: Colors.red),
            const SizedBox(height: 12),
            ColoredTextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const TimetableEditor(),
                    )),
                text: 'Редактировать график',
                foregroundColor: Colors.white,
                boxColor: Colors.orange),
            const SizedBox(height: 12),
            ColoredTextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const RegistrationPage(),
                    )),
                text: 'Создать нового пользователя',
                foregroundColor: Colors.white,
                boxColor: Colors.pink),
            const SizedBox(height: 12),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredTextButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const TeachersView(),
                        )),
                    text: 'Преподаватели',
                    foregroundColor: Colors.white,
                    boxColor: const Color(0xFF2ec4b6)),
                const SizedBox(height: 8),
                ColoredTextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SubjectsView())),
                    text: 'Предметы',
                    foregroundColor: Colors.white,
                    boxColor: Theme.of(context).primaryColorLight),
              ],
            ))
          ],
        ),
      ),
    );
  }

  Future _openShedules(DatabaseWorker current) async {
    bool _started = false;
    try {
      var result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
              title: Text(
                  'Расписание обновляется, пожалуйста, не закрывайте приложение'),
              content: LinearProgressIndicator()));
      _started = true;

      if (result?.files.first != null) {
        List<int> fileBytes = List.from(result!.files.first.bytes!);

        var parsingResult = sheduleDomain(fileBytes);
        var resultEntities = parsingResult.item1;
        var resultShedule = parsingResult.item2;
        var err = await current.clearDatabase();
        if (err.isNotEmpty) {
          showTextSnackBar(
              context,
              'Встречена ошибка (обратите внимание, база данных могла нарушиться): $err',
              8000);
        } else {
          var results = <String>[];
          results.add(await current.fillGroups(resultEntities[0]));
          results.add(await current.fillSubjects(resultEntities[1]));
          results.add(await current.fillTeachers(resultEntities[2]));
          results.add(await current.fillRooms(resultEntities[3]));
          results.add(await current.fillShedule(resultShedule));
          for (var element in results) {
            if (element.isNotEmpty) {
              showTextSnackBar(context, element, 7000);
              return;
            }
          }

          showTextSnackBar(context, 'Расписание успешно обновлено!', 7000);
        }
      }
    } catch (e) {
      log(e.toString());
    } finally {
      if (_started) {
        Navigator.of(context).pop();
      }
    }
  }
}
