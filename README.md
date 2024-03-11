# Utopia Queue

A light and fast queue library.

## Getting started

First add the dependency in your pubspec.yaml

```yaml
dependencies:
  utopia_queue: ^0.2.0
```

Now, in main.dart, you can start a server as the following.

```dart
import 'package:utopia_queue/utopia_queue.dart';

void main(List<String> arguments) async {
  final connection = ConnectionRedis('localhost', 6379);
  final Server server = Server(connection, queue: 'myqueue');

  server.job().inject('message').action((Message message) {
    print(message.toMap());
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
  final connection = ConnectionRedis('localhost', 6379);
  final client = Client(connection, queue: 'myqueue');
  await client
      .enqueue({'user': Random().nextInt(20), 'name': 'Damodar Lohani'});
  print('enqueued');
}
```
