import 'package:json_annotation/json_annotation.dart';

part 'monitor.g.dart';

@JsonSerializable()
class Monitor {
  final int id;
  final String name;
  final String? url;
  final String type;
  final int interval;
  final bool? status;
  final bool active;
  final List<Tag>? tags;
  final int? parent;
  @JsonKey(name: 'childrenIDs')
  final List<int>? childrenIds;

  const Monitor({
    required this.id,
    required this.name,
    this.url,
    required this.type,
    required this.interval,
    this.status,
    required this.active,
    this.tags,
    this.parent,
    this.childrenIds,
  });

  factory Monitor.fromJson(Map<String, dynamic> json) => _$MonitorFromJson(json);
  Map<String, dynamic> toJson() => _$MonitorToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Monitor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Monitor{id: $id, name: $name, active: $active}';
}

@JsonSerializable()
class Tag {
  final String name;
  final String color;

  const Tag({
    required this.name,
    required this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);
}