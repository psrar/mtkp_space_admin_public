import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class TeachersView extends StatefulWidget {
  const TeachersView({Key? key}) : super(key: key);

  @override
  _TeachersViewState createState() => _TeachersViewState();
}

class _TeachersViewState extends State<TeachersView> {
  List<Tuple2<int, String>>? _teachers;
  final _teacherNameFieldKey = GlobalKey<FormState>();
  final _teacherNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _requestTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Преподаватели',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _teachers = null;
                  _requestTeachers();
                });
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).primaryColorLight,
              ))
        ],
      ),
      body: _teachers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _teachers![index].item2,
                          style: const TextStyle(fontSize: 16),
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: Text(
                                _teachers![index].item2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Form(
                                  key: _teacherNameFieldKey,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  child: TextFormField(
                                      controller: _teacherNameController,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Необходимо ввести новое имя';
                                        }
                                        if (value.length > 99) {
                                          return 'Имя слишком длинное';
                                        }
                                        if (value
                                            .contains(RegExp(r'[*();\-\\/]'))) {
                                          return 'Имя содержит недопустимые символы';
                                        }
                                        if (value
                                            .contains(RegExp(r'[a-zA-Z]'))) {
                                          return 'Имя должно содержать только русские буквы';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                          hintText:
                                              'Введите новое имя преподавателя')),
                                ),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                        onPressed: () async {
                                          if (_teacherNameFieldKey.currentState!
                                              .validate()) {
                                            String prevName =
                                                _teachers![index].item2;
                                            var result = await DatabaseWorker
                                                .currentDatabaseWorker
                                                .updateTeacher(Tuple3(
                                                    _teachers![index].item1,
                                                    prevName,
                                                    _teacherNameController
                                                        .text));
                                            if (result == null) {
                                              setState(() {
                                                _teachers![index] =
                                                    _teachers![index].withItem2(
                                                        _teacherNameController
                                                            .text);
                                              });
                                              showTextSnackBar(
                                                  context,
                                                  'Новое имя успешно установлено!',
                                                  2000);
                                            } else {
                                              showTextSnackBar(
                                                  context, result, 2000);
                                            }
                                            Navigator.of(context).pop();
                                            _teacherNameController.clear();
                                          }
                                        },
                                        child: const Text(
                                          'Применить',
                                          style:
                                              TextStyle(color: Colors.orange),
                                        )),
                                    TextButton(
                                        onPressed: () =>
                                            {Navigator.of(context).pop()},
                                        child: const Text('Отмена'))
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(Icons.edit,
                            color: Theme.of(context).primaryColorLight),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                      )
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 0),
              itemCount: _teachers!.length),
    );
  }

  void _requestTeachers() {
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        showTextSnackBar(
            context,
            'Вы не подключены к интернету. Попробуйте обновить список, когда он появится.',
            5000);
      } else {
        DatabaseWorker.currentDatabaseWorker.getAllTeachers().then((value) {
          if (value == null) {
            showTextSnackBar(
                context,
                'Преподаватели не найдены или не удалось получить информацию о них',
                5000);
          } else {
            value.sort((a, b) => a.item2.compareTo(b.item2));
            setState(() => _teachers = value);
          }
        });
      }
    });
  }
}
