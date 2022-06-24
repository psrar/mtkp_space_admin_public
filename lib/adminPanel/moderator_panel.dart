import 'package:mtkp/adminPanel/login_page.dart';
import 'package:mtkp/adminPanel/subjects_view.dart';
import 'package:mtkp/adminPanel/teachers_view.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:flutter/material.dart';
import 'package:mtkp/widgets/layout.dart';

class ModeratorPanel extends StatefulWidget {
  const ModeratorPanel({Key? key}) : super(key: key);

  @override
  State<ModeratorPanel> createState() => _ModeratorPanelState();
}

class _ModeratorPanelState extends State<ModeratorPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Панель модератора',
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredTextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const TeachersView(),
                    )),
                text: 'Преподаватели',
                boxColor: const Color(0xFF2ec4b6)),
            const SizedBox(height: 8),
            ColoredTextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SubjectsView())),
                text: 'Предметы',
                boxColor: Theme.of(context).primaryColorLight),
          ],
        ),
      ),
    );
  }
}
