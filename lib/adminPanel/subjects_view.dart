import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({Key? key}) : super(key: key);

  @override
  _SubjectsViewState createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  List<Tuple2<int, String>>? _subjects;
  final _subjectNameFieldKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  String _selectedGroup = 'Группа';

  List<String> entryOptions = [];

  @override
  void initState() {
    super.initState();

    _requestGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Предметы',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
              splashRadius: 18,
              onPressed: () {
                setState(() {
                  _subjects = null;
                  if (_selectedGroup != 'Группа') {
                    _requestSubjects(_selectedGroup);
                  }
                  if (_selectedGroup == 'Все') {
                    _requestSubjects(null);
                  }
                });
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).primaryColorLight,
              )),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 10, 8),
            child: GroupSelector(
                selectedGroup: _selectedGroup,
                options: entryOptions,
                callback: (value) => setState(() {
                      if (value == 'Показать все предметы') {
                        _selectedGroup = 'Все';
                        _requestSubjects(null);
                      } else {
                        _selectedGroup = value;
                        _requestSubjects(_selectedGroup);
                      }
                      // requestShedule(_selectedGroup);
                    })),
          )
        ],
      ),
      body: _subjects == null
          ? entryOptions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : (const Center(
                  child: Text(
                    'Выберите группу, чтобы увидеть индивидуальные предметы для неё',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ))
          : ListView.separated(
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _subjects![index].item2,
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
                                _subjects![index].item2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Form(
                                  key: _subjectNameFieldKey,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  child: TextFormField(
                                      controller: _subjectNameController,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Необходимо ввести новое название';
                                        }
                                        if (value.length > 99) {
                                          return 'Название слишком длинное';
                                        }
                                        if (value
                                            .contains(RegExp(r'[*();\-\\/]'))) {
                                          return 'Название содержит недопустимые символы';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                          hintText:
                                              'Введите новое название предмета')),
                                ),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                        onPressed: () async {
                                          if (_subjectNameFieldKey.currentState!
                                              .validate()) {
                                            String prevName =
                                                _subjects![index].item2;
                                            var result = await DatabaseWorker
                                                .currentDatabaseWorker
                                                .updateSubject(Tuple3(
                                                    _subjects![index].item1,
                                                    prevName,
                                                    _subjectNameController
                                                        .text));
                                            if (result == null) {
                                              setState(() {
                                                _subjects![index] =
                                                    _subjects![index].withItem2(
                                                        _subjectNameController
                                                            .text);
                                              });
                                              showTextSnackBar(
                                                  context,
                                                  'Новое название успешно установлено!',
                                                  2000);
                                            } else {
                                              showTextSnackBar(
                                                  context, result, 2000);
                                            }
                                            Navigator.of(context).pop();
                                            _subjectNameController.clear();
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
              itemCount: _subjects!.length),
    );
  }

  void _requestSubjects(String? group) {
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none) {
        showTextSnackBar(
            context,
            'Вы не подключены к интернету. Попробуйте обновить список, когда он появится.',
            5000);
      } else {
        DatabaseWorker.currentDatabaseWorker
            .getAllSubjects(group)
            .then((value) {
          if (value == null) {
            showTextSnackBar(
                context,
                'Предметы не найдены или не удалось получить информацию о них',
                5000);
          } else {
            value.sort((a, b) => a.item2.compareTo(b.item2));
            setState(() => _subjects = value);
          }
        });
      }
    });
  }

  void _requestGroups() async {
    try {
      await Connectivity().checkConnectivity().then((value) {
        if (value != ConnectivityResult.none) {
          DatabaseWorker.currentDatabaseWorker
              .getAllGroups()
              .then((value) => setState(() {
                    entryOptions = value;
                    if (entryOptions.isNotEmpty) {
                      entryOptions.insert(0, 'Показать все предметы');
                    }
                  }));
        } else {
          showTextSnackBar(
              context, 'Вы не в сети. Не удаётся загрузить данные.', 5000);
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }
}
