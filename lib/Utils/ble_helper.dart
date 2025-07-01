import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BLEHelper {
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Reaktif mod: "RGB" veya "RGBW"
  static RxString mode = RxString("RGB");

  // Reaktif bağlı cihaz; null ise cihaz bağlı değildir.
  static Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);

  // Bağlı cihazın karakteristiği.
  static BluetoothCharacteristic? connectedCharacteristic;

  /// Bağlantı bilgilerini temizleyen yardımcı fonksiyon.
  static void clearConnection() {
    connectedDevice.value = null;
    connectedCharacteristic = null;
  }

  /// Cihazın bağlantı durumunu dinler.
  /// Eğer cihaz disconnect olursa, bağlantı bilgilerini temizler.
  static void monitorDeviceState(BluetoothDevice device) {
    device.state.listen((state) {
      if (state == BluetoothDeviceState.connected) {
        // Bağlantı sağlandığında ek işlemler yapılabilir.
      } else if (state == BluetoothDeviceState.disconnected) {
        clearConnection();
      }
    });
  }
}
