import 'dart:developer' as dev;
import 'dart:isolate';

import '../utopia_queue.dart';

enum IsolateStatus {
  working,
  idle,
  paused,
  stopped,
}

class IsolateSupervisor {
  final Isolate isolate;
  final ReceivePort receivePort;
  final int id;
  SendPort? isolateSendPort;
  Function(Message) onError;
  IsolateStatus _status = IsolateStatus.paused;

  bool get isBusy => _status == IsolateStatus.working;

  static const String messageClose = '_CLOSE';

  IsolateSupervisor({
    required this.isolate,
    required this.receivePort,
    required this.id,
    required this.onError,
  });

  void resume() {
    receivePort.listen(listener);
    isolate.resume(isolate.pauseCapability!);
    _status = IsolateStatus.idle;
  }

  void stop() {
    dev.log('Stopping isolate $id', name: 'FINE');
    isolateSendPort?.send(messageClose);
    _status = IsolateStatus.stopped;
    receivePort.close();
  }

  void listener(dynamic message) async {
    if (message is SendPort) {
      isolateSendPort = message;
    } else if (message is Map) {
      if (message['type'] == 'error') {
        onError.call(message['message']);
      } else if (message['type'] == 'status') {
        _status = message['status'];
      }
    }
  }
}
