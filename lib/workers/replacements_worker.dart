import 'dart:convert';

import 'package:mtkp/database/database_interface.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart' show ZipDecoder;
import 'package:mtkp/models.dart';
import 'package:mtkp/utils/levenshtein.dart';
import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart';

import '../models.dart';

const restApi =
    'https://api.vk.com/method/wall.get?domain=mtkp_bmstu&offset=1&count=6&filter=all&extended=0&v=5.131&access_token=733ba40e54ee97a4db5a478c0910346fda3da33db69bf2b6a478b780cbf74cc8bb947264e9390019aa35b';

///Данная функция обновляет недавние замены
Future<Tuple3<String, List<SimpleDate>, int>> getReplacementFile(
    Tuple2<DatabaseWorker, int> data) async {
  try {
    var response = await http.get(Uri.parse(restApi));

    String? result;
    var dates = <SimpleDate>[];
    int lastReplacementsID = data.item2;
    bool isLast = true;

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      List<dynamic> entries = json['response']['items'];
      for (var i = 0; i < entries.length; i++) {
        var file = entries[i]?['attachments']?[0]?['doc'];
        if (file != null) {
          var z = file['title'].toString().split(' ');
          if (file['ext'] == 'docx' &&
              z.isNotEmpty &&
              levenshtein(z.first, 'замены') < 3) {
            if (file['id'] <= data.item2) {
              return Tuple3('', dates, lastReplacementsID);
            }

            String link = file['url'];
            var fileBytes = (await http.get(Uri.parse(link))).bodyBytes;
            var date = getReplacementDate(file['title']);
            if (!dates.contains(date)) {
              result = await parseReplacements(file['title'], fileBytes)
                  .then((replacements) async {
                if (replacements != null) {
                  dates.add(date);
                  var err =
                      await data.item1.fillReplacements(replacements, isLast);
                  isLast = false;
                  if (err.isEmpty) {
                    if (file['id'] > lastReplacementsID) {
                      lastReplacementsID = file['id'];
                    }
                  }
                  return err;
                }
                return null;
              });
              if (result!.isNotEmpty) {
                return Tuple3(result, [], lastReplacementsID);
              }
            }
          }
        }
      }

      return Tuple3(
          result ?? 'Не удалось получить замены', dates, lastReplacementsID);
    } else {
      return Tuple3('${response.statusCode}, не удалось получить замены', [],
          lastReplacementsID);
    }
  } catch (e) {
    return Tuple3(e.toString(), [], data.item2);
  }
}

SimpleDate getReplacementDate(String fileName) {
  var date = RegExp(r'([0-9]+.[0-9]+)')
      .stringMatch(fileName)!
      .split(RegExp(r'(\_|\.)'));
  return SimpleDate(int.parse(date.first), int.parse(date.last) - 1);
}

///Возвращает {Дата, Список(группа, Список(предмет, кабинет))}
Future<Tuple2<SimpleDate, Map<String, List<Tuple2<String, String?>?>>>?>
    parseReplacements(String fileName, List<int> fileBytes) async {
  Map<String, List<Tuple2<String, String?>?>> replacements = {};

  final archive = ZipDecoder().decodeBytes(fileBytes);

  for (final file in archive) {
    if (file.name == 'word/document.xml') {
      file.decompress();

      final xml = XmlDocument.parse(utf8.decode(file.content as List<int>));
      for (var table in xml.findAllElements('w:tbl')) {
        var row = table.findAllElements('w:tr').first;
        var columns = row
            .findAllElements('w:tc')
            .map((e) => e.findAllElements('w:t').map((e) => e.text).join())
            .toList();

        for (var i = 0; i < columns.length; i++) {
          var group = RegExp(r'([а-яА-Я]+-[1-9]+)').stringMatch(columns[i]);

          if (group != null) {
            try {
              List<Tuple2<String, String?>?> lessons = [];
              var rows = table.findAllElements('w:tr').toList();

              int pract = 0;
              Tuple2<String, String?>? practTuple;

              for (var k = 1; k < rows.length; k += 2) {
                var c = rows[k].findAllElements('w:tc').toList()[i];
                var val = c.findAllElements('w:t').map((e) => e.text).join('');
                if (pract != 0) {
                  if (c.findAllElements('w:vMerge').isNotEmpty) {
                    //ADDITIONAL CHECKS Can be implemented later
                    pract++;
                    lessons.add(practTuple);
                    continue;
                  } else {
                    while (lessons.length < 6) {
                      lessons.add(null);
                    }
                    break;
                  }
                }

                var lval = val.toLowerCase();
                if (lval.isEmpty ||
                    lval.replaceAll(' ', '') == 'группаотпущена') {
                  lessons.add(null);
                  //Смещение индекса, если строка с "группа отпущена" не содержит подстроку с номером кабинета
                  if (rows[k + 1]
                          .findAllElements('w:tc')
                          .map((e) => e
                              .findAllElements('w:t')
                              .map((e) => e.text)
                              .join(' '))
                          .toList()[0] !=
                      '') k--;
                } else if (lval.contains(
                    RegExp(r'(пп)|(практика)|(производственная практика)'))) {
                  var room = RegExp(r'([0-9]+|вц)').allMatches(lval);
                  val = 'Практика';
                  pract = 1;
                  if (room.length != 1) {
                    practTuple = Tuple2(val, null);
                  } else {
                    practTuple = Tuple2(val, room.single[0]);
                  }

                  lessons.add(practTuple);
                } else {
                  var room = rows[k + 1]
                      .findAllElements('w:tc')
                      .map((e) =>
                          e.findAllElements('w:t').map((e) => e.text).join(' '))
                      .toList()[i];
                  lessons.add(Tuple2(val, room));
                }
              }
              replacements[group] = lessons;
            } catch (e) {
              throw Exception(
                  'Ошибка при парсинге замен на ${getReplacementDate(fileName)}, группа $group: ' +
                      e.toString());
            }
          }
        }
      }
      return Tuple2(getReplacementDate(fileName), replacements);
    }
  }
  return null;
}
