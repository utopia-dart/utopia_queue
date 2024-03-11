abstract class Connection {
  Future<bool> rightPushJson(String queue, Map<String, dynamic> payload);
  Future<Map<String, dynamic>?> rightPopJson(String queue, int timeout);
  Future<bool> leftPushJson(String queue, Map<String, dynamic> payload);
  Future<bool> leftPush(String queue, String value);
  Future<Map<String, dynamic>?> leftPopJson(String queue, int timeout);
  Future<dynamic> leftPop(String queue, int timeout);
  Future<dynamic> rightPop(String queue, int timeout);
  Future get(String key);
}
