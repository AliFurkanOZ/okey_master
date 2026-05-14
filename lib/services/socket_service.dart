import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static IO.Socket? _socket;
  
  static void connect() {
    if (_socket != null && _socket!.connected) return;
    
    // API URL'in sonundaki /api kısmını atarak ana sunucu adresini bul (örneğin: http://10.0.2.2:3000)
    String serverUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');

    _socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setExtraHeaders({
        'Bypass-Tunnel-Reminder': 'true',
        'ngrok-skip-browser-warning': 'true'
      })
      .disableAutoConnect()
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('[SocketService] Sunucuya bağlanıldı!');
    });

    _socket!.onDisconnect((_) {
      print('[SocketService] Sunucu bağlantısı koptu!');
    });
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }

  static void joinQueue(String nickname, String type) {
    if (_socket == null) connect();
    _socket!.emit('join_queue', {'nickname': nickname, 'type': type});
  }

  static void on(String event, Function(dynamic) callback) {
    if (_socket == null) connect();
    _socket!.on(event, callback);
  }

  static void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  static void emit(String event, dynamic data) {
    if (_socket != null) {
      _socket!.emit(event, data);
    }
  }

  static String? get socketId => _socket?.id;
}
