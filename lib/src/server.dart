import 'connection.dart';

class Server {
  final Connection connection;
  final String queue;
  final String namespace;

  Server(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-queue',
  });

  Future<void> start() async {
    while (true) {
      final nextMessage =
          await connection.leftPop('$namespace.queue.$queue', 5);

      if (nextMessage == null) {
        continue;
      }
      print(nextMessage);
    }
  }
}
