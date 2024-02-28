import 'connection.dart';

class Server {
  final Connection connection;
  final String queue;
  final String namespace;

  Server(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-dart.queue',
  });

  Future<void> start() async {
    while (true) {
      final nextMessage = await connection.leftPop('$namespace.$queue', 5);

      if (nextMessage == null) {
        continue;
      }
      print(nextMessage);
    }
  }
}
