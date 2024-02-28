abstract class Connection {
  Future<bool> rightPushArray(String queue, Map<String, dynamic> payload);
  Future<List?> rightPopArray(String queue, int timeout);
  Future<bool> leftPushArray(String queue, Map<String, dynamic> payload);
  Future<List?> leftPopArray(String queue, int timeout);
  Future<dynamic> leftPop(String queue, int timeout);
}
