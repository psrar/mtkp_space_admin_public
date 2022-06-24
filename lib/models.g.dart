// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PairModel _$PairModelFromJson(Map<String, dynamic> json) => PairModel(
      json['name'] as String,
      json['teacher_name'] as String?,
      json['room'] as String?,
    );

Map<String, dynamic> _$PairModelToJson(PairModel instance) => <String, dynamic>{
      'name': instance.name,
      'teacher_name': instance.teacherName,
      'room': instance.room,
    };

Time _$TimeFromJson(Map<String, dynamic> json) => Time(
      json['start'] as String,
      json['end'] as String,
    );

Map<String, dynamic> _$TimeToJson(Time instance) => <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };

Timetable _$TimetableFromJson(Map<String, dynamic> json) => Timetable(
      Time.fromJson(json['first'] as Map<String, dynamic>),
      Time.fromJson(json['second'] as Map<String, dynamic>),
      Time.fromJson(json['third'] as Map<String, dynamic>),
      Time.fromJson(json['fourth'] as Map<String, dynamic>),
      Time.fromJson(json['fifth'] as Map<String, dynamic>),
      Time.fromJson(json['sixth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TimetableToJson(Timetable instance) => <String, dynamic>{
      'first': instance.first,
      'second': instance.second,
      'third': instance.third,
      'fourth': instance.fourth,
      'fifth': instance.fifth,
      'sixth': instance.sixth,
    };

SaveModel _$SaveModelFromJson(Map<String, dynamic> json) => SaveModel(
      Timetable.fromJson(json['timetable'] as Map<String, dynamic>),
      (json['up_shedule'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => e == null
                  ? null
                  : PairModel.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
      (json['down_shedule'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => e == null
                  ? null
                  : PairModel.fromJson(e as Map<String, dynamic>))
              .toList())
          .toList(),
      json['group'] as String,
    );

Map<String, dynamic> _$SaveModelToJson(SaveModel instance) => <String, dynamic>{
      'timetable': instance.timetable,
      'up_shedule': instance.upShedule,
      'down_shedule': instance.downShedule,
      'group': instance.group,
    };
