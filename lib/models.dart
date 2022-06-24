import 'package:json_annotation/json_annotation.dart';
import 'package:tuple/tuple.dart';

part 'models.g.dart';

class Weekday {
  final String _value;
  const Weekday._internal(this._value);

  @override
  String toString() => 'Weekday.$_value';

  String get name {
    switch (this) {
      case Weekday.monday:
        return 'Понедельник';
      case Weekday.tuesday:
        return 'Вторник';
      case Weekday.wednesday:
        return 'Среда';
      case Weekday.thursday:
        return 'Четверг';
      case Weekday.friday:
        return 'Пятница';
      case Weekday.saturday:
        return 'Суббота';
      case Weekday.sunday:
        return 'Воскресенье';
      default:
        throw Exception('Как в неделе оказался 8 день?');
    }
  }

  String get shortName {
    switch (this) {
      case Weekday.monday:
        return 'Пн';
      case Weekday.tuesday:
        return 'Вт';
      case Weekday.wednesday:
        return 'Ср';
      case Weekday.thursday:
        return 'Чт';
      case Weekday.friday:
        return 'Пт';
      case Weekday.saturday:
        return 'Сб';
      case Weekday.sunday:
        return 'Вс';
      default:
        throw Exception('Как в неделе оказался 8 день?');
    }
  }

  static const monday = Weekday._internal('monday');
  static const tuesday = Weekday._internal('tuesday');
  static const wednesday = Weekday._internal('wednesday');
  static const thursday = Weekday._internal('thursday');
  static const friday = Weekday._internal('friday');
  static const saturday = Weekday._internal('saturday');
  static const sunday = Weekday._internal('sunday');

  static const List<Weekday> all = [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
    Weekday.saturday,
    Weekday.sunday
  ];
  static final List<Weekday> exceptSunday = all.sublist(0, 6);
  static final List<Weekday> exceptWeekend = all.sublist(0, 5);
}

class Month {
  final String _value;
  const Month._internal(this._value);

  @override
  String toString() => 'Month.$_value';

  static Month fromNum(int num) => Month.all[num];

  String get name {
    switch (this) {
      case Month.january:
        return 'Январь';
      case Month.february:
        return 'Февраль';
      case Month.march:
        return 'Март';
      case Month.april:
        return 'Апрель';
      case Month.may:
        return 'Май';
      case Month.june:
        return 'Июнь';
      case Month.july:
        return 'Июль';
      case Month.august:
        return 'Август';
      case Month.september:
        return 'Сентябрь';
      case Month.october:
        return 'Октябрь';
      case Month.november:
        return 'Ноябрь';
      case Month.december:
        return 'Декабрь';
      default:
        throw Exception('Как появился 13 месяц?');
    }
  }

  String get ofName {
    switch (this) {
      case Month.january:
        return 'января';
      case Month.february:
        return 'февраля';
      case Month.march:
        return 'марта';
      case Month.april:
        return 'апреля';
      case Month.may:
        return 'мая';
      case Month.june:
        return 'июня';
      case Month.july:
        return 'июля';
      case Month.august:
        return 'августа';
      case Month.september:
        return 'сентября';
      case Month.october:
        return 'октября';
      case Month.november:
        return 'ноября';
      case Month.december:
        return 'декабря';
      default:
        throw Exception('Как появился 13 месяц?');
    }
  }

  int get num {
    switch (this) {
      case Month.january:
        return 1;
      case Month.february:
        return 2;
      case Month.march:
        return 3;
      case Month.april:
        return 4;
      case Month.may:
        return 5;
      case Month.june:
        return 6;
      case Month.july:
        return 7;
      case Month.august:
        return 8;
      case Month.september:
        return 9;
      case Month.october:
        return 10;
      case Month.november:
        return 11;
      case Month.december:
        return 12;
      default:
        throw Exception('Как появился 13 месяц?');
    }
  }

  static const january = Month._internal('january');
  static const february = Month._internal('february');
  static const march = Month._internal('march');
  static const april = Month._internal('april');
  static const may = Month._internal('may');
  static const june = Month._internal('june');
  static const july = Month._internal('july');
  static const august = Month._internal('august');
  static const september = Month._internal('september');
  static const october = Month._internal('october');
  static const november = Month._internal('november');
  static const december = Month._internal('december');

  static const List<Month> all = [
    Month.january,
    Month.february,
    Month.march,
    Month.april,
    Month.may,
    Month.june,
    Month.july,
    Month.august,
    Month.september,
    Month.october,
    Month.november,
    Month.december,
  ];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PairModel {
  final String name;
  final String? teacherName;
  final String? room;

  ///Создает модель пары по расписанию. Week - обозначение нечетности (1) и четности (2) недели. Если предмет есть на обеих неделях, необходимо указать число (3).
  PairModel(this.name, this.teacherName, this.room);

  Map<String, String> get toStringMap => {
        'name': name,
        'teacher': teacherName == null || teacherName == ''
            ? 'Не указан'
            : teacherName!,
        'room': room == null ? '—' : room!
      };

  factory PairModel.fromJson(Map<String, dynamic> json) =>
      _$PairModelFromJson(json);

  Map<String, dynamic> toJson() => _$PairModelToJson(this);

  @override
  String toString() {
    return name +
        ' ' +
        (teacherName ?? 'Преподаватель не указан') +
        ' ' +
        (room ?? 'Кабинет не указан');
  }
}

class Replacements {
  late final Map<SimpleDate, List<PairModel?>>? _replacements;

  Replacements(Map<SimpleDate, List<PairModel?>>? replacements) {
    _replacements = replacements;
  }

  getReplacement(SimpleDate simpleDate) => _replacements?[simpleDate];
}

///Класс, содержащий информацию о начале и конце занятия
@JsonSerializable(fieldRename: FieldRename.snake)
class Time {
  final String start;
  final String end;

  Time(this.start, this.end);

  factory Time.fromJson(Map<String, dynamic> json) => _$TimeFromJson(json);

  Map<String, dynamic> toJson() => _$TimeToJson(this);
}

//Модель упрощенной даты (день и месяц)
class SimpleDate {
  final int day;
  final int month;

  SimpleDate(this.day, this.month);

  @override
  bool operator ==(other) =>
      (other is SimpleDate && day == other.day && month == other.month);

  @override
  int get hashCode => Object.hash(day, month);

  @override
  String toString() {
    return '$day, ${Month.all[month].name}';
  }

  String toSpeech() => '$day ${Month.all[month].ofName}';

  String toNum() => '$day.${Month.all[month].num}';
}

///Расписание начала и конца пар
@JsonSerializable(fieldRename: FieldRename.snake)
class Timetable {
  Time first;
  Time second;
  Time third;
  Time fourth;
  Time fifth;
  Time sixth;

  Timetable(
      this.first, this.second, this.third, this.fourth, this.fifth, this.sixth);

  factory Timetable.fromJson(Map<String, dynamic> json) =>
      _$TimetableFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableToJson(this);

  Map<int, Time> get all => {
        1: first,
        2: second,
        3: third,
        4: fourth,
        5: fifth,
        6: sixth,
      };
}

///Расписание на неделю, timetable, верхняя неделя и нижняя
class WeekShedule {
  late final Tuple3<Timetable, List<List<PairModel?>>, List<List<PairModel?>>>
      weekLessons;

  WeekShedule(this.weekLessons);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SaveModel {
  late final Timetable timetable;
  late final List<List<PairModel?>> upShedule;
  late final List<List<PairModel?>> downShedule;
  late final String group;

  SaveModel(this.timetable, this.upShedule, this.downShedule, this.group);

  factory SaveModel.fromJson(Map<String, dynamic> json) =>
      _$SaveModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaveModelToJson(this);
}
