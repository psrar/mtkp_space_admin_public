import 'dart:convert';
import 'dart:developer';

import 'package:mtkp/models.dart';
import 'package:flutter/widgets.dart';
import 'package:mtkp/utils/notification_utils.dart';
import 'package:supabase/supabase.dart';
import 'package:crypto/crypto.dart';
import 'package:tuple/tuple.dart';

part 'messages.dart';

const String supabaseKey =
    'тут был ключ :)';
const String supabaseURL = "https://ukucnsshztcrrlwwayaw.supabase.co";

class DatabaseWorker {
  static late DatabaseWorker _currentDatabaseWorker;
  static final CurrentUserNotifier _currentUserNotifier =
      CurrentUserNotifier(null);
  late final SupabaseClient _client;

  DatabaseWorker() {
    _client = SupabaseClient(supabaseURL, supabaseKey);
    _currentDatabaseWorker = this;
  }

  static DatabaseWorker get currentDatabaseWorker => _currentDatabaseWorker;
  static CurrentUserNotifier get currentUserNotifier => _currentUserNotifier;

  Future<User?> requestLogin(String username, String password) async {
    password = sha512.convert(utf8.encode(password)).toString();
    var result = await _client
        .from('t_user')
        .select()
        .eq('username', username)
        .eq('passhash', password)
        .execute();

    var data = result.data as List<dynamic>;
    if (data.length == 1) {
      var user = User._returnUser(username, data.first['userrole']);
      _currentUserNotifier.updateCurrentUser(user);
      return user;
    } else {
      return null;
    }
  }

  Future<bool> createUser(String username, String password, int role) async {
    password = sha512.convert(utf8.encode(password)).toString();
    var result = await _client.from('t_user').insert({
      'username': username,
      'passhash': password,
      'userrole': role
    }).execute();

    if (result.hasError) {
      return false;
    } else {
      return true;
    }
  }

  Future<List<String>> getTimeshedule() async {
    try {
      var response = <String>[];
      await _client.from('t_timeshedule').select().execute().then((value) {
        if ((value.data as List<dynamic>).isEmpty) {
          return [];
        } else {
          var element = (value.data as List<dynamic>).first;
          response.add(element['firstpair']);
          response.add(element['secondpair']);
          response.add(element['thirdpair']);
          response.add(element['fourthpair']);
          response.add(element['fifthpair']);
          response.add(element['sixthpair']);
        }
      });
      return response;
    } catch (e) {
      log('getTimeshedule: ' + e.toString());
      return [];
    }
  }

  Future<List<String>> getAllGroups() async {
    try {
      var response = <String>[];
      await _client.from('t_group').select().execute().then((value) {
        for (var element in (value.data as List<dynamic>)) {
          response.add(element['groupname']);
        }
      });
      return response;
    } catch (e) {
      throw Exception('getAllGroups: ' + e.toString());
    }
  }

  Future<List<Tuple2<int, String>>?> getAllTeachers() async {
    try {
      var response = <Tuple2<int, String>>[];
      await _client.from('t_teacher').select().execute().then((value) {
        for (var element in value.data as List<dynamic>) {
          response.add(Tuple2(element['id'], element['name']));
        }
      });
      return response;
    } catch (e) {
      throw Exception('getAllTeachers: ' + e.toString());
    }
  }

  Future<List<Tuple2<int, String>>?> getAllSubjects(String? group) async {
    try {
      var response = <Tuple2<int, String>>[];
      if (group == null) {
        await _client.from('t_subject').select().execute().then((value) {
          for (var element in value.data as List<dynamic>) {
            response.add(Tuple2(element['id'], element['name']));
          }
        });
      } else {
        await _client
            .rpc('getsubjects', params: {'selectedgroup': group})
            .execute()
            .then((value) {
              for (var element in value.data as List<dynamic>) {
                response.add(Tuple2(element['id'], element['name']));
              }
            });
      }
      return response;
    } catch (e) {
      throw Exception('getAllSubjects: ' + e.toString());
    }
  }

  Future<List<Tuple3<String?, String?, String?>>> getShedule(
      String group) async {
    try {
      var response = <Tuple3<String?, String?, String?>>[];
      await _client
          .rpc('getshedule', params: {'selectedgroup': group})
          .execute()
          .then((value) {
            for (var element in (value.data as List<dynamic>)) {
              response.add(
                  Tuple3(element['sname'], element['tname'], element['room']));
            }
          });
      return response;
    } catch (e) {
      throw Exception('getShedule: ' + e.toString());
    }
  }

  Future<Tuple2<String, List<Tuple4<int, String, String, String>>>>
      getAllMessages([Tuple2<int, DateTime>? from]) async {
    var result;
    if (from == null) {
      result = await _client.from('t_message').select().execute();
    } else {
      result = await _client
          .from('t_message')
          .select()
          .gte('id', from.item1)
          .execute();
    }
    if (result.hasError) return Tuple2(result.error.toString(), []);

    var messages = <Tuple4<int, String, String, String>>[];
    for (var element in (result.data as List<dynamic>)) {
      messages.add(Tuple4(element['id'], element['receiver'], element['title'],
          element['body']));
    }

    return Tuple2('', messages);
  }

  Future<String> clearDatabase() async {
    var results = <String>[];
    //Цепочка удалений важна из-за зависимосткй
    // results.add(await clearShedule());
    results.add(await clearTable('t_group'));
    results.add(await clearTable('t_subject'));
    results.add(await clearTable('t_room'));
    results.add(await clearTable('t_teacher'));

    for (var element in results) {
      if (element.isNotEmpty) {
        log(element);
        return element;
      }
    }
    return '';
  }

  Future<String> clearTable(String table) async {
    var result = await _client
        .from(table)
        .delete(returning: ReturningOption.minimal)
        .gt('id', -1)
        .execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> clearShedule() async {
    var result = await _client
        .from('t_pair')
        .delete(returning: ReturningOption.minimal)
        .gt('id', -1)
        .execute();
    if (result.hasError) {
      return result.error.toString();
    } else {
      result = await _client
          .from('t_dayshedule')
          .delete(returning: ReturningOption.minimal)
          .gt('id', -1)
          .execute();
      if (result.hasError) {
        return result.error.toString();
      } else {
        result = await _client
            .from('t_weekshedule')
            .delete(returning: ReturningOption.minimal)
            .gt('id', -1)
            .execute();
        if (result.hasError) {
          return result.error.toString();
        } else {
          return '';
        }
      }
    }
  }

  Future<String> clearTimeshedule() async {
    var result = await _client
        .from('t_timeshedule')
        .delete(returning: ReturningOption.minimal)
        .gt('id', -1)
        .execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillGroups(Map<int, dynamic> groups) async {
    var map = <Map<String, dynamic>>[];
    groups.forEach((key, value) {
      map.add({'id': key, 'groupname': value});
    });
    var result = await _client.from('t_group').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillSubjects(Map<int, dynamic> subjects) async {
    var map = <Map<String, dynamic>>[];
    subjects.forEach((key, value) {
      map.add({'id': key, 'name': value});
    });
    var result = await _client.from('t_subject').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillRooms(Map<int, dynamic> rooms) async {
    var map = <Map<String, dynamic>>[];
    rooms.forEach((key, value) {
      map.add({'id': value});
    });
    var result = await _client.from('t_room').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillTeachers(Map<int, dynamic> teachers) async {
    var map = <Map<String, dynamic>>[];
    teachers.forEach((key, value) {
      map.add({'id': key, 'name': value});
    });
    var result = await _client.from('t_teacher').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillShedule(List<Map<String, dynamic>> shedule) async {
    var results = <String>[];
    results.add(await fillWeekShedule(shedule));
    results.add(await fillDayShedule(shedule));
    results.add(await fillPairs(shedule));
    for (var element in results) {
      if (element.isNotEmpty) {
        log(element);
        return element;
      }
    }

    return '';
  }

  Future<String> fillWeekShedule(List<Map<String, dynamic>> shedule) async {
    var map = <Map<String, dynamic>>[];
    for (var i = 0; i < shedule.length * 2; i++) {
      map.add({
        'id': i,
        'groupid': (shedule[i ~/ 2]['group'] as Map<int, dynamic>).keys.single,
        'down': i % 2 == 0 ? false : true
      });
    }
    var result = await _client.from('t_weekshedule').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillDayShedule(List<Map<String, dynamic>> shedule) async {
    var map = <Map<String, dynamic>>[];
    map = [];
    for (var i = 0; i < shedule.length * 2; i++) {
      for (var d = 0; d < 6; d++) {
        map.add({'id': i * 6 + d, 'weekshedule': i, 'weekday': d + 1});
      }
    }
    var result = await _client.from('t_dayshedule').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> fillPairs(List<Map<String, dynamic>> shedule) async {
    var map = <Map<String, dynamic>>[];
    for (var i = 0; i < shedule.length * 2; i++) {
      var weekShedule = shedule[i ~/ 2][i % 2 == 0 ? 'upweek' : 'downweek'];
      for (var d = 0; d < 6; d++) {
        var dayShedule = weekShedule[d + 1];
        for (var p = 0; p < 6; p++) {
          var pair = dayShedule['lessons'][p] as Map<String, dynamic>;
          var subj = pair['subject'];
          if (subj != null) {
            subj = (subj as Map).keys.single;
          }
          var teacher = pair['teacher'];
          if (teacher != null) {
            teacher = (teacher as Map).keys.single;
          }
          map.add({
            'id': pair['id'],
            'subject': subj,
            'teacher': teacher,
            'room': pair['room'],
            'dayshedule': dayShedule['id'],
            'queue': pair['queue']
          });
        }
      }
    }
    var result = await _client.from('t_pair').insert(map).execute();
    return result.hasError ? result.error.toString() : '';
  }

  Future<String> sendMessage(String receiver, String title, String body) async {
    var result = await _client
        .from('t_message')
        .insert({'receiver': receiver, 'title': title, 'body': body}).execute();
    if (result.hasError) return result.error!.message;
    return '';
  }

  Future<String> replacementsMailingList(
      Tuple2<SimpleDate, Map<String, List<Tuple2<String, String?>?>>>
          replacements,
      List<dynamic> allGroups) async {
    var result = await clearTable('t_message');
    if (result.isNotEmpty) return result;

    //receiver, title, body
    List<Map<String, String>> messages = [];

    var groups = replacements.item2.keys.toList();
    List<String> dbGroups =
        allGroups.map((e) => (e['groupname']) as String).toList();
    for (var i = 0; i < dbGroups.length; i++) {
      if (!groups.contains(dbGroups[i])) {
        messages.add({
          'receiver': dbGroups[i],
          'title': '!Статус замен на ' + replacements.item1.toSpeech(),
          'body': 'Стандартное расписание, замен для вашей группы нет.'
        });
      }
    }

    for (var item in replacements.item2.entries) {
      String body = '';
      for (var i = 0; i < 6; i++) {
        var lesson = item.value[i];
        if (lesson == null) {
          body += '${i + 1}: ---';
        } else {
          body += '${i + 1}: ' + lesson.item1;
        }

        if (i != 5) body += '\n';
      }

      messages.add({
        'receiver': item.key,
        'title': '!Замены на ' + replacements.item1.toSpeech(),
        'body': body
      });
    }

    var resultSecond = await DatabaseWorker()
        ._client
        .from('t_message')
        .insert(messages)
        .execute();
    if (resultSecond.hasError) return resultSecond.error!.message;
    return '';
  }

  Future<String> fillReplacements(
      Tuple2<SimpleDate, Map<String, List<Tuple2<String, String?>?>>>
          replacements,
      bool isLast) async {
    var groups = replacements.item2.keys.toList();
    var result =
        await _client.from('t_group').select('id, groupname').execute();
    if (result.hasError) {
      return result.error!.message;
    } else {
      var dbGroups = result.data as List<dynamic>;
      var resGroups = <dynamic>[];

      if (isLast) {
        var res = await replacementsMailingList(replacements, dbGroups);
        if (res.isNotEmpty) return res;
      }

      String date =
          '2000-${(replacements.item1.month + 1).toString().padLeft(2, '0')}-${replacements.item1.day.toString().padLeft(2, '0')}';

      result =
          await _client.from('t_replacement').delete().eq('dt', date).execute();

      if (result.hasError) {
        return result.error!.message;
      } else {
        for (var i = 0; i < dbGroups.length; i++) {
          if (groups.contains(dbGroups[i]['groupname'])) {
            resGroups.add(dbGroups[i]);
          }
        }

        List<Map<String, dynamic>> replacementsMap = [];
        List<Map<String, dynamic>> replacementPairsMap = [];
        int repID = (replacements.item1.month + 1) * 1000000 +
            replacements.item1.day * 10000;

        for (var gr in resGroups) {
          var rid = repID + gr['id'] * 100;
          replacementsMap.add({'id': rid, 'groupid': gr['id'], 'dt': date});

          List<Tuple2<String, String?>?> lessons =
              replacements.item2[gr['groupname']]!;

          var pid = 0;
          for (var i = 0; i < lessons.length; i++) {
            replacementPairsMap.add({
              'id': rid + pid++,
              'replacement': rid,
              'queue': i + 1,
              'subject': lessons[i]?.item1,
              'room': lessons[i]?.item2,
            });
          }
        }

        result = await _client
            .from('t_replacement')
            .insert(replacementsMap)
            .execute();

        if (result.hasError) {
          return result.error!.message;
        } else {
          while (replacementPairsMap.length > 100) {
            var p1 = replacementPairsMap.sublist(0, 100);
            replacementPairsMap = replacementPairsMap.sublist(100);
            result =
                await _client.from('t_replacementpair').insert(p1).execute();
            if (result.hasError) {
              await clearTable('t_replacement');
              return result.error!.message;
            }
          }
          result = await _client
              .from('t_replacementpair')
              .insert(replacementPairsMap)
              .execute();
          if (result.hasError) {
            await clearTable('t_replacement');
            return result.error!.message;
          } else {
            return '';
          }
        }
      }
    }
  }

  ///Первый элемент - ID, второй - прошлое значение,
  ///третий элемент - новое значение.
  ///Прошлое значение необходимо для проверки изменения.
  Future<String?> updateTeacher(Tuple3<int, String, String> values) async {
    try {
      var result = await _client
          .from('t_teacher')
          .update({'name': values.item3}, returning: ReturningOption.minimal)
          .eq('id', values.item1)
          .eq('name', values.item2)
          .execute();

      if (result.hasError) {
        return 'Не удалось обновить данные. Обновите список преподавателей и попробуйте снова';
      } else {
        return null;
      }
    } catch (e) {
      log('updateTeacher: ' + e.toString());
    }
    return null;
  }

  ///Первый элемент - ID, второй - прошлое значение,
  ///третий элемент - новое значение.
  ///Прошлое значение необходимо для проверки изменения.
  Future<String?> updateSubject(Tuple3<int, String, String> values) async {
    try {
      var result = await _client
          .from('t_subject')
          .update({'name': values.item3}, returning: ReturningOption.minimal)
          .eq('id', values.item1)
          .eq('name', values.item2)
          .execute();

      if (result.hasError) {
        return 'Не удалось обновить данные. Обновите список предметов и попробуйте снова';
      } else {
        return null;
      }
    } catch (e) {
      log('updateSubject: ' + e.toString());
    }
    return null;
  }

  Future<bool> updateTimeshedule(int id, List<List<String>> timetable) async {
    try {
      var result = await _client.from('t_timeshedule').insert({
        'id': id,
        'firstpair': '${timetable[0][0]}-${timetable[0][1]}',
        'secondpair': '${timetable[1][0]}-${timetable[1][1]}',
        'thirdpair': '${timetable[2][0]}-${timetable[2][1]}',
        'fourthpair': '${timetable[3][0]}-${timetable[3][1]}',
        'fifthpair': '${timetable[4][0]}-${timetable[4][1]}',
        'sixthpair': '${timetable[5][0]}-${timetable[5][1]}'
      }).execute();
      return !result.hasError;
    } catch (e) {
      log('updateTimeshedule: ' + e.toString());
      return false;
    }
  }
}

enum Role { admin, moderator, teacher }

class User {
  final String login;
  late final int role;

  User._returnUser(this.login, this.role);
}

class CurrentUserNotifier extends ValueNotifier<User?> {
  CurrentUserNotifier(User? value) : super(value);

  void updateCurrentUser(User? user) {
    value = user;
    notifyListeners();
  }
}
