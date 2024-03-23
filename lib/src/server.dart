import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate' as iso;

import 'package:utopia_di/utopia_di.dart';
import 'package:utopia_queue/src/isolate_message.dart';
import 'package:utopia_queue/src/isolate_supervisor.dart';
import 'package:utopia_queue/src/message.dart';

import 'connection.dart';
import 'job.dart';

/// Queue server
///
/// Runs and listens to the queue and processes
/// jobs as theyare received
class Server {
  final Connection connection;
  final String queue;
  final String namespace;
  final di = DI();
  final List<Hook> _errors = [];
  final List<Hook> _init = [];
  final List<Hook> _shutdown = [];
  final List<IsolateSupervisor> _supervisors = [];

  Job _job = Job();

  Server(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-queue',
  });

  /// Set resource
  void setResource(
    String name,
    Function callback, {
    List<String> injections = const [],
  }) =>
      di.set(name, callback, injections: injections);

  /// Get resource
  dynamic getResource<T>(String name, {bool fresh = false}) =>
      di.get<T>(name, fresh: fresh);

  /// Set job handler
  Job job() {
    _job = Job();
    return _job;
  }

  /// Setup init hooks
  ///
  /// Init hooks are executed before the job
  /// is executed
  Hook init() {
    final hook = Hook()..groups(['*']);
    _init.add(hook);
    return hook;
  }

  /// Setup shutdown hooks
  ///
  /// Shutdown hooks are executed after the job
  /// is executed
  Hook shutdown() {
    final hook = Hook()..groups(['*']);
    _shutdown.add(hook);
    return hook;
  }

  /// Error hooks
  ///
  /// Error hooks are executed for each error
  Hook error() {
    final hook = Hook()..groups(['*']);
    _errors.add(hook);
    return hook;
  }

  Future<void> _watchQueue() async {
    while (true) {
      IsolateSupervisor? worker;
      for (final sup in _supervisors) {
        if (sup.isBusy) {
          continue;
        }
        worker = sup;
        break;
      }

      if (worker == null) {
        continue;
      }
      var nextMessage =
          await connection.rightPopJson('$namespace.queue.$queue', 5);

      if (nextMessage == null) {
        continue;
      }

      final message = Message.fromMap(nextMessage);
      setResource('message', () => message);
      worker.isolateSendPort?.send(message);
    }
  }

  void _onError(Message message) {
    connection.leftPushJson('$namespace.failed.$queue', message.toMap());
  }

  Future<void> _spawn(int num) async {
    _supervisors.clear();
    for (var i = 0; i < num; i++) {
      final receivePort = iso.ReceivePort();
      final isolate = await iso.Isolate.spawn<IsolateMessage>(
        _entrypoint,
        IsolateMessage(
          id: i,
          sendPort: receivePort.sendPort,
          errors: _errors,
          job: _job,
          init: _init,
          shutdown: _shutdown,
          di: di,
        ),
        paused: true,
      );
      final sup = IsolateSupervisor(
          isolate: isolate, receivePort: receivePort, id: i, onError: _onError);
      _supervisors.add(sup);
      sup.resume();
    }
  }

  /// Start queue server
  Future<void> start({int threads = 1}) async {
    await _spawn(threads);
    await _watchQueue();
  }
}

class _IsolateServer {
  final Job job;
  final DI di;
  final List<Hook> errors;
  final List<Hook> init;
  final List<Hook> shutdown;
  final iso.SendPort sendPort;
  final int id;

  _IsolateServer({
    required this.id,
    required this.job,
    required this.di,
    required this.errors,
    required this.init,
    required this.shutdown,
    required this.sendPort,
  });

  Map<String, dynamic> _getArguments(
    Hook hook,
    Map<String, dynamic> payload,
  ) {
    final args = <String, dynamic>{};
    hook.params.forEach((key, param) {
      var value = payload[key] ?? param.defaultValue;
      value = value == '' || value == null ? param.defaultValue : value;
      _validate(key, param, value);
      args[key] = value;
    });

    for (var injection in hook.injections) {
      args[injection] = di.get(injection);
    }
    return args;
  }

  void _validate(String key, Param param, dynamic value) {
    if ('' != value && value != null) {
      final validator = param.validator;
      if (validator != null) {
        if (!validator.isValid(value)) {
          throw Exception(
            'Invalid $key: ${validator.getDescription()}',
          );
        }
      }
    } else if (!param.optional) {
      throw Exception('Param "$key" is not optional.');
    }
  }

  Future<void> _executeHooks(
    List<Hook> hooks,
    List<String> groups,
    Map<String, dynamic> Function(Hook) argsCallback, {
    bool globalHook = false,
    bool globalHooksFirst = true,
  }) async {
    void executeGlobalHook() {
      for (final hook in hooks) {
        if (hook.getGroups().contains('*')) {
          final arguments = argsCallback.call(hook);
          Function.apply(
            hook.getAction(),
            [...hook.argsOrder.map((key) => arguments[key])],
          );
        }
      }
    }

    void executeGroupHooks() {
      for (final group in groups) {
        for (final hook in init) {
          if (hook.getGroups().contains(group)) {
            final arguments = argsCallback.call(hook);
            Function.apply(
              hook.getAction(),
              [...hook.argsOrder.map((key) => arguments[key])],
            );
          }
        }
      }
    }

    if (globalHooksFirst && globalHook) {
      executeGlobalHook();
    }
    executeGroupHooks();
    if (!globalHooksFirst && globalHook) {
      executeGlobalHook();
    }
  }

  Future<void> execute(Message message) async {
    dev.log('$id: Job received ${message.pid}');
    di.set('message', () => message);
    sendPort.send({'type': 'status', 'status': IsolateStatus.working});

    try {
      final groups = job.getGroups();
      if (job.hook) {
        await _executeHooks(
          init,
          groups,
          (hook) => _getArguments(hook, message.payload),
          globalHook: true,
        );
      }
      final args = _getArguments(job, message.payload);
      await Function.apply(
          job.getAction(), [...job.argsOrder.map((key) => args[key])]);
      if (job.hook) {
        await _executeHooks(
          shutdown,
          groups,
          (hook) => _getArguments(hook, message.payload),
          globalHook: true,
        );
      }
      dev.log('$id: Job ${message.pid} successfully run');
    } catch (e) {
      sendPort.send({'type': 'error', 'message': message});
      dev.log('$id: Error: Job ${message.pid} failed to run');
      dev.log('$id: Error: ${e.toString()}');
      _executeHooks(
        errors,
        [],
        (hook) => _getArguments(hook, message.payload),
      );
    } finally {
      sendPort.send({'type': 'status', 'status': IsolateStatus.idle});
    }
  }
}

Future<void> _entrypoint(IsolateMessage options) async {
  final receivePort = iso.ReceivePort();
  final server = _IsolateServer(
    id: options.id,
    job: options.job,
    di: options.di,
    errors: options.errors,
    init: options.init,
    shutdown: options.shutdown,
    sendPort: options.sendPort,
  );

  options.sendPort.send(receivePort.sendPort);
  dev.log('Worker: ${options.id} waiting fro job');
  receivePort.listen((message) async {
    if (message is Message) {
      await server.execute(message);
    } else if (message == IsolateSupervisor.messageClose) {
      receivePort.close();
    }
  });
}
