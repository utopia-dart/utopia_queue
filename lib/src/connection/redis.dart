import 'dart:convert';

import 'package:redis/redis.dart';

import '../connection.dart';

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

  @override
  Future<Map<String, dynamic>?> leftPopArray(String queue, int timeout) async {
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

  @override
  Future<bool> leftPushArray(String queue, Map<String, dynamic> payload) async {
    try {
      await (await _getRedis())
          .send_object(['LPUSH', queue, jsonEncode(payload)]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> leftPush(String queue, String value) async {
    try {
      await (await _getRedis()).send_object(['LPUSH', queue, value]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> rightPopArray(String queue, int timeout) async {
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

  @override
  Future<bool> rightPushArray(
      String queue, Map<String, dynamic> payload) async {
    try {
      await (await _getRedis())
          .send_object(['RPUSH', queue, jsonEncode(payload)]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future leftPop(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BLPOP', queue, timeout]);
    if (res is List && res.length < 2) {
      return null;
    }
    return res[1];
  }

  @override
  Future rightPop(String queue, int timeout) async {
    final res =
        await (await _getRedis()).send_object(['BRPOP', queue, timeout]);
    if (res is List && res.length < 2) {
      return null;
    }
    return res[1];
  }

  @override
  Future get(String key) async {
    return (await _getRedis()).send_object(['GET', key]);
  }
}
