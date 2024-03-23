import 'package:utopia_queue/utopia_queue.dart';

void main(List<String> arguments) async {
  final connection = await ConnectionRedis.init('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');

  server.setResource('res1', () {
    return 'hello res 1';
  });

  server.job().inject('message').inject('res1').action((Message message, String res1) {
    print('res1: $res1');
    print(message.toMap());
  });
  server.start(threads: 2);
}
