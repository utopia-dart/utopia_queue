import 'package:redis/redis.dart';

import '../src/connection/redis.dart';
import '../src/server.dart';

final RedisConnection connection = RedisConnection();
void main(List<String> arguments) async {
  final connection = ConnectionRedis('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');
  server.start();
}
