import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:flutter/material.dart';

class TimetableEditor extends StatefulWidget {
  const TimetableEditor({Key? key}) : super(key: key);

  @override
  _TimetableEditorState createState() => _TimetableEditorState();
}

class _TimetableEditorState extends State<TimetableEditor> {
  var times = [
    ['9:00', '10:30'],
    ['10:50', '12:10'],
    ['12:40', '14:00'],
    ['14:30', '16:00'],
    ['16:10', '17:40'],
    ['18:00', '19:30']
  ];

  final welcomeText = 'Задайте время начала и конца для каждой пары';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('График',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Text(
              welcomeText,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.left,
            ),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 32,
                                child: Text(i.toString(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 100,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await showTimePicker(
                                      context: context,
                                      initialTime:
                                          const TimeOfDay(hour: 9, minute: 0),
                                      cancelText: 'Отмена',
                                      confirmText: 'Подтвердить',
                                      helpText: 'Начало $i пары',
                                      builder: (context, child) => MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: true),
                                          child: child!),
                                    ).then((value) {
                                      if (value != null) {
                                        setState(() {
                                          times[i][0] =
                                              value.hour.toString().padLeft(2) +
                                                  ':' +
                                                  value.minute
                                                      .toString()
                                                      .padLeft(2, '0');
                                        });
                                      }
                                    });
                                  },
                                  child: Text(times[i][0]),
                                )),
                            const SizedBox(
                                width: 32,
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                )),
                            SizedBox(
                                width: 100,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await showTimePicker(
                                      context: context,
                                      initialTime:
                                          const TimeOfDay(hour: 9, minute: 0),
                                      cancelText: 'Отмена',
                                      confirmText: 'Подтвердить',
                                      helpText: 'Конец $i пары',
                                      builder: (context, child) => MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: true),
                                          child: child!),
                                    ).then((value) {
                                      if (value != null) {
                                        setState(() {
                                          times[i][1] =
                                              value.hour.toString().padLeft(2) +
                                                  ':' +
                                                  value.minute
                                                      .toString()
                                                      .padLeft(2, '0');
                                        });
                                      }
                                    });
                                  },
                                  child: Text(times[i][1]),
                                )),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.orange.shade100,
                          onSurface: Colors.white,
                          primary: Colors.black),
                      onPressed: () async {
                        var db = DatabaseWorker.currentDatabaseWorker;
                        db.clearTimeshedule().whenComplete(() =>
                            db.updateTimeshedule(0, times).then((value) {
                              if (value == false) {
                                showTextSnackBar(context,
                                    'Не удалось обновить график', 5000);
                              } else {
                                showTextSnackBar(
                                    context, 'График успешно обновлен', 5000);
                              }
                            }));
                      },
                      child: const Text('Сохранить график'),
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
