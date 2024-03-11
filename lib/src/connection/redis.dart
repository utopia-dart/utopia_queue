import 'dart:convert';

import 'package:redis/redis.dart';

import '../connection.dart';

/// Connection redis
///
/// Used to connect to redis server
/// and manage queue
class ConnectionRedis extends Connection {
  final String host;
  final int port;
  final String? user;
  final String? password;

  Command? redis;

  ConnectionRedis(this.host, this.port, {this.user, this.password});

  Future<Command> _getRedis() async {
    if (redis != null) {
      return redis!;
    }
    final connection = RedisConnection();
    redis = await connection.connect(host, port);
    if (user != null && password != null) {
      redis!.send_object(['AUTH', user, password]);
    }
    return redis!;
  }

  /// Left pop json item from the queue
  @override
  Future<Map<String, dynamic>?> leftPopJson(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BLPOP', queue, timeout]);
    if (res == null) {
      return null;
    }
    if (res is List && res.length < 2) {
      return null;
    }
    return jsonDecode(res[1]);
  }

  /// Left push json item to the queue
  @override
  Future<bool> leftPushJson(String queue, Map<String, dynamic> payload) async {
    try {
      await (await _getRedis())
          .send_object(['LPUSH', queue, jsonEncode(payload)]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Left push item to the queue
  @override
  Future<bool> leftPush(String queue, String value) async {
    try {
      await (await _getRedis()).send_object(['LPUSH', queue, value]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Right pop json item from the queue
  @override
  Future<Map<String, dynamic>?> rightPopJson(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BRPOP', queue, timeout]);

    if (res == null) {
      return null;
    }
    if (res is List && res.length < 2) {
      return null;
    }
    return jsonDecode(res[1]);
  }

  /// Right push json item to the queue
  @override
  Future<bool> rightPushJson(String queue, Map<String, dynamic> payload) async {
    try {
      await (await _getRedis())
          .send_object(['RPUSH', queue, jsonEncode(payload)]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Left pop item from the queue
  @override
  Future leftPop(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BLPOP', queue, timeout]);
    if (res is List && res.length < 2) {
      return null;
    }
    return res[1];
  }

  /// Right pop item from the queue
  @override
  Future rightPop(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BRPOP', queue, timeout]);
    if (res is List && res.length < 2) {
      return null;
    }
    return res[1];
  }

  /// Get a key from redis
  @override
  Future get(String key) async {
    return (await _getRedis()).send_object(['GET', key]);
  }
}
