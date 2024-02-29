import 'package:utopia_queue/utopia_queue.dart';

void main() async {
  final connection = ConnectionRedis('localhost', 6379);
  final client = Client(connection, queue: 'myqueue');
  client.enqueue({'user': 1, 'name': 2});
}
