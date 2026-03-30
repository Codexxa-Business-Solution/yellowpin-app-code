import 'dart:io';

/// On Android emulator, "localhost" is the emulator itself. Use 10.0.2.2 to reach the host machine.
String getApiHost() {
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}
