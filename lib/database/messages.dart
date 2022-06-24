part of 'database_interface.dart';

// Future<bool> createMessageToGroups(List<String> groups, String title, String body){

// }

Future<bool> createMessageToAll(String title, String body) async {
  var res = await DatabaseWorker._currentDatabaseWorker._client
      .from('t_message')
      .insert({'receiver': 'all', 'title': title, 'body': body}).execute();

  if (res.hasError) {
    NotificationHandler().showNotification(
        'МТКП Space',
        'При отправлении сообщения всем группам возникла ошибка: ' +
            res.error!.message);
    return false;
  } else {
    return true;
  }
}
