import 'dart:isolate';

import 'connection.dart';

class IsolateMessage {
  final int id;
  final SendPort sendPort;
  final Connection connection;

  IsolateMessage({
    required this.id,
    required this.sendPort,
    required this.connection,
  });
}
