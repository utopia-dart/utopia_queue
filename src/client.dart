import 'package:uuid/uuid.dart';

import 'connection.dart';

class Client {
  final String queue;
  final String namespace;
  final Connection connection;

  Client(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-dart.queue',
  });

  Future<bool> enqueue(Map<String, dynamic> payload) async {
    final data = {
      'pid': Uuid().v1(),
      'queue': queue,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload
    };
    await connection.leftPushArray('$namespace.$queue', data);
    return true;
  }
}
