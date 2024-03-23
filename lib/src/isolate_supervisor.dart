import 'dart:developer' as dev;
import 'dart:isolate';

class IsolateSupervisor {
  final Isolate isolate;
  final ReceivePort receivePort;
  final int id;
  SendPort? _isolateSendPort;

  static const String messageClose = '_CLOSE';

  IsolateSupervisor({
    required this.isolate,
    required this.receivePort,
    required this.id,
  });

  void resume() {
    receivePort.listen(listener);
    isolate.resume(isolate.pauseCapability!);
  }

  void stop() {
    dev.log('Stopping isolate $id', name: 'FINE');
    _isolateSendPort?.send(messageClose);
    receivePort.close();
  }

  void listener(dynamic message) async {
    if (message is SendPort) {
      _isolateSendPort = message;
    }
  }
}
