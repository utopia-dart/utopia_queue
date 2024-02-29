abstract class Connection {
  Future<bool> rightPushArray(String queue, Map<String, dynamic> payload);
  Future<Map<String, dynamic>?> rightPopArray(String queue, int timeout);
  Future<bool> leftPushArray(String queue, Map<String, dynamic> payload);
  Future<bool> leftPush(String queue, String value);
  Future<Map<String, dynamic>?> leftPopArray(String queue, int timeout);
  Future<dynamic> leftPop(String queue, int timeout);
  Future<dynamic> rightPop(String queue, int timeout);
  Future get(String key);
}
