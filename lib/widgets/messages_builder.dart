import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/utils/internet_connection_checker.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:tuple/tuple.dart';

class DatabaseMessages extends StatefulWidget {
  const DatabaseMessages({Key? key}) : super(key: key);

  @override
  State<DatabaseMessages> createState() => _DatabaseMessagesState();
}

class _DatabaseMessagesState extends State<DatabaseMessages> {
  List<Tuple4<int, String, String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    getMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ColoredTextButton(
          onPressed: () async {
            await checkInternetConnection(() async {
              var result = await DatabaseWorker.currentDatabaseWorker
                  .clearTable('t_message');
              if (result.isNotEmpty) {
                Fluttertoast.showToast(msg: result);
              } else {
                await getMessages();
              }
            });
          },
          text: 'Очистить все сообщения',
          boxColor: Colors.red),
      const SizedBox(height: 8),
      ColoredTextButton(
          onPressed: () async {
            await checkInternetConnection(() async {
              await getMessages();
            });
          },
          text: 'Обновить список сообщений',
          boxColor: Colors.orange),
      const SizedBox(height: 8),
      sendMessageButton(context),
      const SizedBox(height: 4),
      for (var i = 0; i < messages.length; i++)
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(messages[i].item3,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('Для группы ' + messages[i].item2,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(messages[i].item4,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400))
              ],
            ),
          ),
          color: Colors.lightBlue.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        )
    ]);
  }

  Future getMessages() async {
    await checkInternetConnection(() async {
      await DatabaseWorker.currentDatabaseWorker.getAllMessages().then((value) {
        if (value.item1.isNotEmpty) Fluttertoast.showToast(msg: value.item1);

        setState(() {
          messages = value.item2;
        });
      });
    });
  }

  ColoredTextButton sendMessageButton(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final receiversController = TextEditingController();
    return ColoredTextButton(
        onPressed: () async {
          titleController.clear();
          receiversController.clear();
          messageController.clear();
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => SimpleDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    title: const Text('Введите сообщение'),
                    contentPadding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                    controller: receiversController,
                                    decoration: standardInputDecoration(
                                        'Получатели', Icons.group_rounded)),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: titleController,
                                    decoration: standardInputDecoration(
                                        'Заголовок', Icons.title_rounded)),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: messageController,
                                    decoration: standardInputDecoration(
                                        'Сообщение', Icons.message_rounded)),
                                const SizedBox(height: 16),
                                ColoredTextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    text: 'Отмена',
                                    boxColor: Colors.red),
                                const SizedBox(height: 8),
                                ColoredTextButton(
                                    onPressed: () async {
                                      if (receiversController.text == '*') {
                                        var groups = await DatabaseWorker
                                            .currentDatabaseWorker
                                            .getAllGroups();
                                        for (var gr in groups) {
                                          await DatabaseWorker
                                              .currentDatabaseWorker
                                              .sendMessage(
                                                  gr,
                                                  titleController.text,
                                                  messageController.text);
                                        }
                                      }
                                      if (RegExp(r'^(([А-Я]+-[1-9]{2}( |))+)$')
                                          .hasMatch(receiversController.text)) {
                                        var result = await DatabaseWorker
                                            .currentDatabaseWorker
                                            .sendMessage(
                                                receiversController.text,
                                                titleController.text,
                                                messageController.text);

                                        if (result.isNotEmpty) {
                                          Fluttertoast.showToast(msg: result);
                                        } else {
                                          Navigator.of(context).pop();
                                          Fluttertoast.showToast(
                                              msg: 'Сообщение отправлено');
                                          await getMessages();
                                        }
                                      } else {
                                        Fluttertoast.showToast(
                                            msg:
                                                'Неверный перечень получателей',
                                            timeInSecForIosWeb: 1);
                                      }
                                    },
                                    text: 'Отправить сообщение',
                                    boxColor: Colors.blue)
                              ])),
                    ],
                  ));
        },
        text: 'Отправить тестовое сообщение',
        boxColor: Colors.green);
  }
}
