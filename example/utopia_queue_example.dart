import 'package:utopia_queue/utopia_queue.dart';
void main(List<String> arguments) async {
  final connection = ConnectionRedis('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');
  server.start();
}
