import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/widgets/layout.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRole = 2;

  final welcomeText =
      'Вы можете предоставить доступ к редактированию базы данных другому человеку.\nДля этого требуется создать нового пользователя и указать уровень его привилегий.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Регистрация',
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
              child: Form(
                key: _formKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _loginController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Необходимо ввести логин';
                          }
                          if (value.contains(RegExp(r'[*();\-\\/]'))) {
                            return 'Логин содержит недопустимые символы';
                          }
                          if (value.length > 10) {
                            return 'Логин должен быть меньше 10 символов';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Логин',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade700, fontSize: 20),
                          prefixIcon: Icon(Icons.person_rounded,
                              color: Colors.grey.shade600, size: 20),
                          contentPadding: const EdgeInsets.all(6),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.black12)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue)),
                        ),
                        cursorColor: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value!.isEmpty) return 'Необходимо ввести пароль';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Пароль',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade700, fontSize: 20),
                          prefixIcon: Icon(Icons.vpn_key_rounded,
                              color: Colors.grey.shade600, size: 20),
                          contentPadding: const EdgeInsets.all(6),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.black12)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue)),
                        ),
                        cursorColor: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: _selectedRole == 2
                                    ? Colors.blue
                                    : Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 2),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Модератор\nМожет только редактировать список преподавателей и предметов.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: _selectedRole == 1
                                    ? Colors.red
                                    : Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Администратор\nИмеет все привилегии, в том числе создание новых пользователей',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final db = DatabaseWorker();
                            db
                                .createUser(_loginController.text,
                                    _passwordController.text, _selectedRole)
                                .then((value) {
                              if (value) {
                                showTextSnackBar(
                                    context,
                                    'Создан модератор: ${_loginController.text}',
                                    4000);
                                Navigator.of(context).pop();
                              } else {
                                showTextSnackBar(
                                    context,
                                    'Не удалось создать пользователя. Возможно, имя уже занято.',
                                    2000);
                              }
                            });
                          }
                        },
                        child: const Text('Зарегистрировать пользователя'),
                      )
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
