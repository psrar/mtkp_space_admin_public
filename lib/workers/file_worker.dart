import 'dart:io';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:tuple/tuple.dart';

Future saveLastReplacementStamp(int fileID, DateTime dateTimeStamp) async {
  final file = await getDocumentsFilePath('lastCheckedReplacements.txt');
  await file.writeAsString('$fileID~$dateTimeStamp');
}

Future<Tuple2<int, DateTime>> getLastReplacementStamp() async {
  final file = await getDocumentsFilePath('lastCheckedReplacements.txt');
  if (!await file.exists()) {
    return Tuple2(0, DateTime(0));
  }
  var str = await file.readAsString();
  var stamp = str.split('~');
  return Tuple2(int.parse(stamp[0]), DateTime.parse(stamp[1]));
}

Future clearReplacementStamp() async {
  final file = await getDocumentsFilePath('lastCheckedReplacements.txt');
  if (await file.exists()) {
    file.delete();
  }
}

Future<File> getDocumentsFilePath(String fileName) async {
  final directory = await pp.getApplicationDocumentsDirectory();
  return File(directory.path + '/$fileName');
}
