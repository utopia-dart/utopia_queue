# Utopia Queue

Utopia queue is a powerful queue library. It is designed to be simple and easy to learn and use. It is built on top of redis.

It is super helpful to build background workers to handle long running tasks. For example in your API server, you can use a emails queue to handle sending emails in the background.

## Usage

In main.dart, you can start a server as the following.

```dart
import 'package:utopia_queue/utopia_queue.dart';

void main(List<String> arguments) async {
  final connection = await ConnectionRedis.init('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');

  server.job().inject('message').action((Message message) {
    print(message.toMap());
    // Do something with the message
  });
  server.start();
}

```

To send a message to the queue, use the following code.

```dart
import 'dart:io';
import 'dart:math';

import 'package:utopia_queue/utopia_queue.dart';

void sendMessage() async {
  final connection = await ConnectionRedis.init('localhost', 6379);
  final client = Client(connection, queue: 'myqueue');
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  print('enqueued');
}
```
