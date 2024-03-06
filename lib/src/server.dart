import 'dart:io';
import 'dart:isolate' as iso;
import 'package:utopia_di/utopia_di.dart';
import 'package:utopia_queue/src/message.dart';

import 'connection.dart';
import 'job.dart';

class Server {
  final Connection connection;
  final String queue;
  final String namespace;
  final di = DI();
  final List<Hook> _errors = [];
  final List<Hook> _init = [];
  final List<Hook> _shutdown = [];
  static Map<String, int> threads = {};

  Job _job = Job();

  Server(
    this.connection, {
    required this.queue,
    this.namespace = 'utopia-queue',
  });

  void setResource(
    String name,
    Function callback, {
    List<String> injections = const [],
  }) =>
      di.set(name, callback, injections: injections);

  dynamic getResource(String name, {bool fresh = false}) =>
      di.get(name, fresh: fresh);

  Job job() {
    _job = Job();
    return _job;
  }

  Hook init() {
    final hook = Hook()..groups(['*']);
    _init.add(hook);
    return hook;
  }

  Hook shutdown() {
    final hook = Hook()..groups(['*']);
    _shutdown.add(hook);
    return hook;
  }

  Hook error() {
    final hook = Hook()..groups(['*']);
    _errors.add(hook);
    return hook;
  }

  Future<void> _onIsolateMain((Connection, int) args) async {
    final (connection, id) = args;
    print('Server $id waiting for queue');
    while (true) {
      var nextMessage =
          await connection.rightPopArray('$namespace.queue.$queue', 5);

      if (nextMessage == null) {
        continue;
      }

      final message = Message.fromMap(nextMessage);
      setResource('message', () => message);
      print('$id: Job received ${message.pid}');

      try {
        final groups = _job.getGroups();
        if (_job.hook) {
          await _executeHooks(
            _init,
            groups,
            (hook) => _getArguments(hook, message.payload),
            globalHook: true,
          );
        }
        final args = _getArguments(_job, message.payload);
        await Function.apply(
            _job.getAction(), [..._job.argsOrder.map((key) => args[key])]);
        if (_job.hook) {
          await _executeHooks(
            _shutdown,
            groups,
            (hook) => _getArguments(hook, message.payload),
            globalHook: true,
          );
        }
        print('$id: Job ${message.pid} successfully run');
      } catch (e) {
        await connection.leftPush('$namespace.failed.$queue', message.pid);
        print('$id: Error: Job ${message.pid} failed to run');
        print('$id: Error: ${e.toString()}');
        setResource('error', () => e);
        _executeHooks(
          _errors,
          [],
          (hook) => _getArguments(hook, message.payload),
        );
      }
    }
  }

  Future<void> _spawnOffIsolates(int num) async {
    for (var i = 0; i < num; i++) {
      await iso.Isolate.spawn<(Connection, int)>(
          _onIsolateMain, (connection, i));
    }
  }

  Future<void> start({int threads = 1}) async {
    await _spawnOffIsolates(threads);
    stdin.readByteSync();
  }

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
        for (final hook in _init) {
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
}
