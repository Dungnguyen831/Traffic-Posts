import 'traffic_post_model.dart';

/// Envelope model cho sự kiện bài viết giao thông realtime từ STOMP WebSocket
class TrafficPostRealtimeEvent {
  final String eventId;
  final String eventType;
  final DateTime occurredAt;
  final TrafficPostModel data;

  TrafficPostRealtimeEvent({
    required this.eventId,
    required this.eventType,
    required this.occurredAt,
    required this.data,
  });

  factory TrafficPostRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return TrafficPostRealtimeEvent(
      eventId: json['eventId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      occurredAt: json['occurredAt'] != null
          ? DateTime.tryParse(json['occurredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      data: TrafficPostModel.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'occurredAt': occurredAt.toIso8601String(),
      'data': data.toJson(),
    };
  }
}
