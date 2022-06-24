import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:mtkp/widgets/messages_builder.dart';
import 'package:mtkp/workers/background_worker.dart';
import 'package:mtkp/workers/file_worker.dart';
import 'package:tuple/tuple.dart';

import 'package:mtkp/utils/internet_connection_checker.dart';
import 'package:mtkp/adminPanel/moderator_panel.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../workers/replacements_worker.dart';
import 'admin_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseMessagesKey = GlobalKey<FormState>();
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Авторизация',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: loginController,
                          validator: (value) {
                            if (value!.contains(RegExp(r'[*();\-\\/]'))) {
                              return 'Логин содержит недопустимые символы';
                            }
                            if (value.isEmpty) {
                              return 'Необходимо ввести логин';
                            }
                            return null;
                          },
                          decoration: standardInputDecoration(
                              'Логин', Icons.person_rounded),
                          cursorColor: Colors.black,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Необходимо ввести пароль';
                            }
                            return null;
                          },
                          decoration: standardInputDecoration(
                              'Пароль', Icons.vpn_key_rounded),
                          cursorColor: Colors.black,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: Colors.green.shade50,
                              onSurface: Colors.green.shade100,
                              primary: Colors.black),
                          onPressed: () async {
                            await checkInternetConnection(() {
                              if (_formKey.currentState!.validate()) {
                                final db = DatabaseWorker();
                                db
                                    .requestLogin(loginController.text,
                                        passwordController.text)
                                    .then((value) {
                                  if (value is User) {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Авторизация успешна, ${value.login}');
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) => value.role < 2
                                                ? const AdminPanel()
                                                : const ModeratorPanel()));
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: 'Неверный логин или пароль');
                                  }
                                });
                              }
                            });
                          },
                          child: const Text('Войти'),
                        )
                      ]),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ColoredTextButton(
                                onPressed: () async {
                                  await checkInternetConnection(() async {
                                    showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const AlertDialog(
                                            title: Text(
                                                'Мы обновляем замены, пожалуйста, не закрывайте приложение'),
                                            content:
                                                LinearProgressIndicator()));
                                    try {
                                      var lastStamp =
                                          await getLastReplacementStamp();
                                      await compute(
                                              getReplacementFile,
                                              Tuple2(
                                                  DatabaseWorker
                                                      .currentDatabaseWorker,
                                                  lastStamp.item1))
                                          .then((value) async {
                                        await saveLastReplacementStamp(
                                            value.item3, DateTime.now());
                                        Navigator.of(context).pop();
                                        if (value.item1 == '') {
                                          if (value.item2.isEmpty) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'Новых замен не обнаружено');
                                            return;
                                          }
                                          String dates = value.item2.join('\n');
                                          showTextSnackBar(
                                              context,
                                              'Замены успешно обновлены на:\n$dates\nID последнего файла замен: ${value.item3}',
                                              3000);
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: value.item1);
                                        }
                                      });
                                    } catch (e) {
                                      Navigator.of(context).pop();
                                      Fluttertoast.showToast(msg: e.toString());
                                    }
                                  });
                                },
                                text: 'Проверить и разместить замены',
                                boxColor: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ColoredTextButton(
                                onPressed: () async {
                                  await clearReplacementStamp().whenComplete(
                                      () => Fluttertoast.showToast(
                                          msg: 'Штампы очищены'));
                                },
                                text: 'Очистить штампы о последних заменах',
                                boxColor: Colors.pink),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ColoredTextButton(
                        onPressed: () async {
                          checkInternetConnection(() {
                            if (!kIsWeb && Platform.isAndroid) {
                              stopShedule();
                              Fluttertoast.showToast(msg: 'Готово!');
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'Работает только на Андроид');
                            }
                          });
                        },
                        text: 'Остановить фоновую службу',
                        boxColor: Colors.red),
                    const SizedBox(height: 8),
                    ColoredTextButton(
                        onPressed: () async {
                          await checkInternetConnection(() {
                            if (!kIsWeb && Platform.isAndroid) {
                              startShedule();
                              Fluttertoast.showToast(msg: 'Готово!');
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'Работает только на Андроид');
                            }
                          });
                        },
                        text: 'Запустить фоновую службу',
                        boxColor: Colors.blue),
                    const SizedBox(height: 16),
                    DatabaseMessages(key: _databaseMessagesKey)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
