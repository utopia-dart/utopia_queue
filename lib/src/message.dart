import 'dart:convert';

class Message {
  final String pid;
  final String queue;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  Message({
    required this.pid,
    required this.queue,
    required this.timestamp,
    required this.payload,
  });

  Message copyWith({
    String? pid,
    String? queue,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
  }) {
    return Message(
      pid: pid ?? this.pid,
      queue: queue ?? this.queue,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pid': pid,
      'queue': queue,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': payload,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      pid: map['pid'] ?? '',
      queue: map['queue'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      payload: Map<String, dynamic>.from(map['payload']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Message(pid: $pid, queue: $queue, timestamp: $timestamp, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.pid == pid &&
        other.queue == queue &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return pid.hashCode ^
        queue.hashCode ^
        timestamp.hashCode ^
        payload.hashCode;
  }
}
