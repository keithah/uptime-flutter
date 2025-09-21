// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Monitor _$MonitorFromJson(Map<String, dynamic> json) => Monitor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      url: json['url'] as String?,
      type: json['type'] as String,
      interval: (json['interval'] as num).toInt(),
      status: json['status'] as bool?,
      active: json['active'] as bool,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      parent: (json['parent'] as num?)?.toInt(),
      childrenIds: (json['childrenIDs'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MonitorToJson(Monitor instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'type': instance.type,
      'interval': instance.interval,
      'status': instance.status,
      'active': instance.active,
      'tags': instance.tags,
      'parent': instance.parent,
      'childrenIDs': instance.childrenIds,
    };

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
      name: json['name'] as String,
      color: json['color'] as String,
    );

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
    };
