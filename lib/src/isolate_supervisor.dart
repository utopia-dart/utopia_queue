import 'dart:developer' as dev;
import 'dart:isolate';

import '../utopia_queue.dart';

class IsolateSupervisor {
  final Isolate isolate;
  final ReceivePort receivePort;
  final int id;
  SendPort? isolateSendPort;
  Function(Message) onError;

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
  }

  void stop() {
    dev.log('Stopping isolate $id', name: 'FINE');
    isolateSendPort?.send(messageClose);
    receivePort.close();
  }

  void listener(dynamic message) async {
    if (message is SendPort) {
      isolateSendPort = message;
    } else if (message is Map) {
      if (message['status'] == 'failed') {
        onError.call(message['message']);
      }
    }
  }
}
