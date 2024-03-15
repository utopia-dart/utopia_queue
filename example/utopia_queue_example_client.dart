import 'dart:io';
import 'dart:math';

import 'package:utopia_queue/utopia_queue.dart';

void main() async {
  final connection = await ConnectionRedis.init('localhost', 6379);
  final client = Client(connection, queue: 'myqueue');
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  print('enqueued');
  exit(0);
}
