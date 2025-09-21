import 'package:json_annotation/json_annotation.dart';

part 'heartbeat.g.dart';

@JsonSerializable()
class Heartbeat {
  @JsonKey(name: 'monitor_id')
  final int monitorId;
  final int status;
  final String time;
  final String? msg;
  final double? ping;
  final bool important;
  final int? duration;

  const Heartbeat({
    required this.monitorId,
    required this.status,
    required this.time,
    this.msg,
    this.ping,
    required this.important,
    this.duration,
  });

  factory Heartbeat.fromJson(Map<String, dynamic> json) => _$HeartbeatFromJson(json);
  Map<String, dynamic> toJson() => _$HeartbeatToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Heartbeat &&
          runtimeType == other.runtimeType &&
          monitorId == other.monitorId &&
          time == other.time;

  @override
  int get hashCode => Object.hash(monitorId, time);

  @override
  String toString() => 'Heartbeat{monitorId: $monitorId, status: $status, time: $time}';
}