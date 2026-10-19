abstract class LanServer {
  Future<void> start(
    int port,
    void Function(String text, String originName) onReceived,
  );
  Future<void> stop();
  String? get localIp;
  bool get isRunning;
}
