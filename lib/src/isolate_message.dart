import 'dart:isolate';

import 'package:utopia_di/utopia_di.dart';

import 'job.dart';

class IsolateMessage {
  final int id;
  final SendPort sendPort;
  final List<Hook> errors;
  final List<Hook> init;
  final List<Hook> shutdown;
  final DI di;
  final Job job;

  IsolateMessage({
    required this.id,
    required this.sendPort,
    required this.errors,
    required this.init,
    required this.shutdown,
    required this.di,
    required this.job,
  });
}
