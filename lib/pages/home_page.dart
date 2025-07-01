// home_page.dart
import 'package:RemoteX/pages/pixel_control_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "dart:async";

import 'slider_page.dart';
import 'classic_colors_page.dart';
import 'animations_page.dart';
import 'ble_scanner_page.dart';
import 'settings_page.dart';
import 'voice_control_page.dart'; // Yeni eklenen VU Meter sayfası
import '../utils/colors.dart';
import '../utils/ble_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final appColorsController = Get.put(AppColorsController());
  int _selectedIndex = 0;

  // Ana sayfa içerikleri
  final List<Widget> _pages = [
    SliderPage(),
    ClassicColorsPage(),
    AnimationsPage(),
  ];

  // Otomatik bağlantı için ek değişkenler
  final FlutterBluePlus flutterBluePlus = FlutterBluePlus();

  bool _hasAutoConnected = false;

  // Heartbeat timer (1 saniyede bir ESP32’ye "HB:" komutu gönderilecek)
  Timer? _heartbeatTimer;
  // Reconnect timer: bağlı cihaz yoksa belirli aralıklarla yeniden bağlantı denemesi yapar.
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _autoConnect();
    startHeartbeat();
    startReconnectTimer();
  }

  // 1 saniyede bir heartbeat komutu gönderir; hata alsa da timer çalışmaya devam eder.
  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (BLEHelper.connectedCharacteristic != null) {
        try {
          String heartbeat = "HB:";
          await BLEHelper.connectedCharacteristic!.write(heartbeat.codeUnits);
          print("Heartbeat sent.");
        } catch (e) {
          print("Heartbeat error: $e");
          BLEHelper.clearConnection();
          _hasAutoConnected =
              false; // Bağlantı koptuğunda yeniden bağlantı denemeleri yapılabilsin.
        }
      }
    });
  }

  // Her 5 saniyede bir, bağlı cihaz yoksa otomatik yeniden bağlantı denemesi yapar.
  void startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (BLEHelper.connectedDevice.value == null) {
        _hasAutoConnected = false; // Yeniden bağlantı için flag sıfırlanıyor.
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? lastDeviceId = prefs.getString('lastDeviceId');
        if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
          print("No device connected. Attempting auto-connect...");
          _autoConnect();
        }
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  // SharedPreferences'dan daha önce kaydedilmiş cihaz ID'sini okuyup otomatik bağlantı başlatır.
  Future<void> _autoConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDeviceId = prefs.getString('lastDeviceId');
    if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.location,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();

      if (statuses.values.every((status) => status.isGranted)) {
        _startAutoScan(lastDeviceId);
      } else {
        print("Otomatik bağlanmak için gerekli izinler verilmedi.");
      }
    }
  }

  void _startAutoScan(String targetDeviceId) {
    if (_hasAutoConnected) return;
    setState(() {});
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)).then((_) {
      setState(() {});
    });
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.id.toString() == targetDeviceId &&
            !_hasAutoConnected) {
          _hasAutoConnected = true;
          _connectToDevice(result.device);
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      // Bağlıysa hata oluşabilir; yoksayılır.
    }
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? targetCharacteristic;
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() ==
          BLEHelper.serviceUUID.toLowerCase()) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() ==
              BLEHelper.characteristicUUID.toLowerCase()) {
            targetCharacteristic = c;
            break;
          }
        }
      }
    }
    if (targetCharacteristic != null) {
      BLEHelper.connectedDevice.value = device;
      BLEHelper.connectedCharacteristic = targetCharacteristic;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('lastDeviceId', device.id.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bağlandı: ${device.name}")));
      BLEHelper.monitorDeviceState(device);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hedef servis/karakteristik bulunamadı")),
      );
      await device.disconnect();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        width: 200,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: appColorsController.greyColor.value,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Image.asset('assets/fiberli-logo.jpg', height: 100),
                  Text(
                    'DMX Controller',
                    style: TextStyle(
                      color: appColorsController.whiteColor.value,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.devices,
                color: appColorsController.blackColor.value,
              ),
              title: Text(
                'Devices',
                style: TextStyle(color: appColorsController.blackColor.value),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BleScannerPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.pix,
                color: appColorsController.blackColor.value,
              ),
              title: Text(
                'Pixel Control',
                style: TextStyle(color: appColorsController.blackColor.value),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SinglePixelControlPage(),
                  ),
                );
              },
            ),
            // Yeni: VU Meter menü öğesi
            ListTile(
              leading: Icon(
                Icons.equalizer,
                color: appColorsController.blackColor.value,
              ),
              title: Text(
                'Voice Control',
                style: TextStyle(color: appColorsController.blackColor.value),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VuMeterPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: appColorsController.blackColor.value,
              ),
              title: Text(
                'Settings',
                style: TextStyle(color: appColorsController.blackColor.value),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Builder(
                builder:
                    (context) => IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: appColorsController.whiteColor.value,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
              ),
            ),
          ),
          // Üstte bağlı cihaz bilgisini gösteren widget.
          Positioned(
            top: 42,
            left: 15,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(
                  () => Text(
                    BLEHelper.connectedDevice.value != null
                        ? "Connected Device: ${BLEHelper.connectedDevice.value!.name}"
                        : "Connected Device: Unavailable",
                    style: TextStyle(
                      color: appColorsController.whiteColor.value,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: appColorsController.blackColor.value,
        selectedItemColor: appColorsController.primaryColor.value,
        unselectedItemColor: appColorsController.white70Color.value,
        selectedLabelStyle: TextStyle(
          color: appColorsController.whiteColor.value,
        ),
        unselectedLabelStyle: TextStyle(
          color: appColorsController.whiteColor.value,
        ),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.slideshow),
            label: 'Kontrol',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: 'Classic Colors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.animation),
            label: 'Animations',
          ),
        ],
      ),
    );
  }
}
