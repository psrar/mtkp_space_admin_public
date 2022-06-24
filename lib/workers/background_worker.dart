import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mtkp/database/database_interface.dart';
import 'package:mtkp/utils/internet_connection_checker.dart';
import 'package:mtkp/utils/notification_utils.dart';
import 'package:mtkp/workers/file_worker.dart';
import 'package:mtkp/workers/replacements_worker.dart';
import 'package:tuple/tuple.dart';

const int helloAlarmID = 0;

void backgroundFunc() async {
  try {
    checkInternetConnectionElse(() async {
      await getReplacementFile(
              Tuple2(DatabaseWorker(), (await getLastReplacementStamp()).item1))
          .then((value) async {
        await saveLastReplacementStamp(value.item3, DateTime.now());
        if (value.item1 == '') {
          if (value.item2.isEmpty) {
            await NotificationHandler().showSilentNotification(
                'Статус замен', 'Новые замены не обнаружены');
            return;
          }
          String dates = value.item2.join('\n');
          await NotificationHandler().showNotification('Загружены замены',
              'Замены успешно обновлены на:\n$dates\nID последнего файла замен: ${value.item3}');
        } else {
          await NotificationHandler()
              .showNotification('Ошибка при загрузке замен', value.item1);
        }
      });
    },
        () async => await NotificationHandler().showSilentNotification(
            'Статус замен', 'Нет доступа к интернету, замены не проверены'));
  } catch (e) {
    await NotificationHandler()
        .showNotification('Ошибка при загрузке замен', e.toString());
  } finally {
    await AndroidAlarmManager.oneShot(
        const Duration(minutes: 1), helloAlarmID, backgroundFunc,
        exact: true, alarmClock: true, allowWhileIdle: true, wakeup: true);
  }
}

Future<bool> initAlarmManager() async {
  return await AndroidAlarmManager.initialize();
}

void startShedule() async {
  await NotificationHandler().showNotification('MTKP AlarmService',
      'AlarmManager запущен. Первый запуск черех 10 секунд, последующие с интервалом в 1 минуту');
  await AndroidAlarmManager.oneShot(
      const Duration(seconds: 10), helloAlarmID, backgroundFunc,
      exact: true, alarmClock: true, allowWhileIdle: true, wakeup: true);
}

void stopShedule() async {
  await NotificationHandler()
      .showNotification('MTKP AlarmService', 'AlarmManager остановлен');
  await AndroidAlarmManager.cancel(helloAlarmID);
}
