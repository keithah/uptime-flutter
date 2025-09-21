// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heartbeat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Heartbeat _$HeartbeatFromJson(Map<String, dynamic> json) => Heartbeat(
      monitorId: (json['monitor_id'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      time: json['time'] as String,
      msg: json['msg'] as String?,
      ping: (json['ping'] as num?)?.toDouble(),
      important: json['important'] as bool,
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HeartbeatToJson(Heartbeat instance) => <String, dynamic>{
      'monitor_id': instance.monitorId,
      'status': instance.status,
      'time': instance.time,
      'msg': instance.msg,
      'ping': instance.ping,
      'important': instance.important,
      'duration': instance.duration,
    };
