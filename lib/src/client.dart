import 'package:uuid/uuid.dart';

import 'connection.dart';
import 'message.dart';

class Client {
  final String queue;
  final String namespace;
  final Connection connection;

  Client(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-queue',
  });

  Future<bool> enqueue(Map<String, dynamic> payload) async {
    final data = {
      'pid': Uuid().v1(),
      'queue': queue,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload
    };
    await connection.leftPushArray('$namespace.queue.$queue', data);
    return true;
  }

  void retry([int? limit]) async {
    int processed = 0;
    final start = DateTime.now().millisecondsSinceEpoch;
    while (true) {
      final pid = await connection.rightPop('$namespace.failed.$queue', 5);
      if (pid == null) {
        break;
      }
      final job = await getJob(pid);
      if (job == null) {
        break;
      }

      // job was already retried
      if (job.timestamp.millisecondsSinceEpoch >= start) {
        break;
      }

      // if we reached the max amount of jobs to retry
      if (limit != null && processed >= limit) {
        break;
      }

      enqueue(job.payload);
      processed++;
    }
  }

  Future<Message?> getJob(String pid) async {
    final value = await connection.get('$namespace.jobs.$queue.$pid');

    if (value == null) {
      return null;
    }
    return Message.fromJson(value);
  }
}
