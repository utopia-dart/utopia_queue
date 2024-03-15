import 'package:utopia_queue/utopia_queue.dart';

void main(List<String> arguments) async {
  final connection = await ConnectionRedis.init('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');

  server.job().inject('message').action((Message message) {
    print(message.toMap());
  });
  server.start(threads: 2);
}
