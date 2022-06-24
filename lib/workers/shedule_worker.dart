import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'package:tuple/tuple.dart';

//первый хэшмап - группы, второй - список распознанных предметов, 3 - учителя, 4 - аудитории, 5 - расписания
Tuple2<List<Map<int, String>>, List<Map<String, dynamic>>> sheduleDomain(
    List<int> fileBytes) {
  var decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
  var table = decoder.tables.values.first;

  var result = [
    <int, String>{},
    <int, String>{},
    <int, String>{},
    <int, String>{},
  ];

  String? findRoomForCell(int row, int column) {
    String? element;
    for (var i = column; i < column + 4; i++) {
      if (table.rows[2][i] == 'ауд') {
        element = table.rows[row][i].toString();
        if (element == 'null') {
          return null;
        }
        if (!result[3].values.contains(element)) {
          result[3].addAll({result[3].length: element});
        }
        return element;
      }
    }
    element = 'r$row-c$column?';
    if (!result[3].values.contains(element)) {
      result[3].addAll({result[3].length: element});
    }

    return element;
  }

  Map<int, String>? resolveTeacher(String? teacher) {
    if (teacher == null) {
      return null;
    }

    for (var i = 0; i < result[2].length; i++) {
      var name = result[2][i]!.replaceAll(' ', '');
      var surname = result[2][i]!.split(' ').first;

      var name2 = teacher.replaceAll(' ', '');
      var surname2 = teacher.split(' ').first;
      if (name == name2) {
        // Проверка на отсутствие пробелов
        if (result[2][i]!.length > teacher.length) {
          return {i: result[2][i]!};
        } else {
          result[2][i] = teacher;
          return {i: teacher};
        }
      } else if (name.length != name2.length && surname == surname2) {
        // Проверка на пропущенные инициалы
        if (result[2][i]!.length > teacher.length) {
          return {i: result[2][i]!};
        } else {
          result[2][i] = teacher;
          return {i: teacher};
        }
      }
    }

    var res = {result[2].length: teacher};
    if (!result[2].values.contains(res.values.single)) {
      result[2].addAll(res);
      return res;
    }
    return null;
  }

  Tuple2<Map<int, String>?, Map<int, String>?>? findLessonAndTeacher(
      int row, int column) {
    var element = table.rows[row][column];
    if (element == null) {
      return null;
    } else {
      var strs = element.toString().split('\n');
      Map<int, String>? lesson;
      Map<int, String>? teacher;
      String lessonName = '';

      for (var name in strs) {
        if (name.contains(RegExp(
            r'(([а-яА-Я]+ [а-яА-Я]\. [а-яА-Я]\.)|([а-яА-Я]+ [а-яА-Я]\.[а-яА-Я]\.))'))) {
          name = name.replaceAll(RegExp(r'((, )|,)'), '');
          if (teacher == null) {
            teacher = resolveTeacher(name);
          } else {
            teacher = null;
            resolveTeacher(name);
          }
        } else {
          if (name.contains(RegExp(r'([А-Я][а-я]+, [А-Я][а-я]+)'))) {
            for (var v in name.split(', ')) {
              resolveTeacher(v);
              teacher = null;
            }
          } else {
            lessonName += name;
          }
        }
      }

      for (var les in result[1].entries) {
        if (les.value == lessonName) {
          lesson = {les.key: les.value};
        }
      }

      if (lesson == null) {
        lesson = {result[1].length: lessonName};
        result[1].addAll(lesson);
      }

      return Tuple2(lesson, teacher);
    }
  }

  List<Map<String, dynamic>> weekShedule = [];
  int weekSheduleid = 0;
  int lessonid = 0;
  int groupnum;

  // ПАРСИНГ СИЛА
  for (var i = 0; i < table.rows[2].length; i++) {
    var element = table.rows[2][i];
    if (element != null &&
        element != 'время' &&
        element != 'ауд' &&
        !result[0].values.contains(element)) {
      groupnum = result[0].length;
      var group = {groupnum: element};
      result[0].addAll({group.keys.single: element});
      weekShedule.add({
        'id': weekSheduleid++,
        'group': group,
        'upweek': <int, dynamic>{},
        'downweek': <int, dynamic>{}
      });

      //Цикл для всей недели для одной группы
      for (var d = 0; d < 6; d++) {
        var upDayShedule = <String, dynamic>{
          'id': d + groupnum * 12,
          'daynum': null,
          'monthnum': null,
          'timeshedule': null,
          'weekday': d + 1,
          'lessons': List<Map<String, dynamic>>
        };
        var downDayShedule = <String, dynamic>{
          'id': d + 6 + groupnum * 12,
          'daynum': null,
          'monthnum': null,
          'timeshedule': null,
          'weekday': d + 1,
          'lessons': List<Map<String, dynamic>>
        };

        List<Map<String, dynamic>> lessons = [];
        //Цикл для верхней недели, на день
        for (var r = 0; r < 6; r++) {
          var rr = 3 + 12 * d + r * 2;
          var cell = findLessonAndTeacher(rr, i);

          if (cell == null) {
            lessons.add({
              'id': lessonid++,
              'queue': r + 1,
              'subject': null,
              'teacher': null,
              'room': null
            });
          } else {
            lessons.add({
              'id': lessonid++,
              'queue': r + 1,
              'subject': cell.item1,
              'teacher': cell.item2,
              'room': findRoomForCell(rr, i)
            });
          }
        }
        upDayShedule['lessons'] = lessons;
        (weekShedule.last['upweek'] as Map<int, dynamic>)
            .addAll({d + 1: upDayShedule});

        lessons = [];
        //Цикл для нижней недели
        for (var r = 0; r < 6; r++) {
          var rr = 4 + 12 * d + r * 2;

          var cell = findLessonAndTeacher(rr, i);
          if (cell == null) {
            lessons.add({
              'id': lessonid++,
              'queue': r + 1,
              'subject': null,
              'teacher': null,
              'room': null
            });
          } else {
            lessons.add({
              'id': lessonid++,
              'queue': r + 1,
              'subject': cell.item1,
              'teacher': cell.item2,
              'room': findRoomForCell(rr, i)
            });
          }
        }
        downDayShedule['lessons'] = lessons;
        (weekShedule.last['downweek'] as Map<int, dynamic>)
            .addAll({d + 1: downDayShedule});
      }
    }
  }

// Нахождение похожих предметов
//   var regExp = RegExp(r'([А-Я]+.\d\d.\d\d )');
//   for (var i = 0; i < result[1].length; i++) {
//     var name = result[1][i];

//     for (var k = i + 1; k < result[1].length; k++) {
//       var name2 = result[1][k];
//       var a = regExp.stringMatch(name);
//       if (a != null &&
//           a == regExp.stringMatch(name2) &&
//           levenshtein(name, name2) < 2) {
//         print("'$name' [$i] похоже на '$name2' [$k]");
//       }
//     }
//   }

  return Tuple2(result, weekShedule);
}
