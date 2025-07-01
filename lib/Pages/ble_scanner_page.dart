import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ble_helper.dart';
import 'package:remotex_android_dmx/Utils/colors.dart';


class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  _BleScannerPageState createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final FlutterBluePlus flutterBluePlus = FlutterBluePlus();
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool hasScanned = false;

  Timer? _connectionCheckTimer;
  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    _loadLastDeviceId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissionsAndStartScan();
    });
  }

  Future<void> _loadLastDeviceId() async {
    setState(() {});
  }

  Future<void> _saveLastDeviceId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastDeviceId', id);
  }

  Future<void> requestPermissionsAndStartScan() async {
    print("Requesting permissions and starting scan...");
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

    statuses.forEach((permission, status) {
      print("Permission: $permission, Status: $status");
    });

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (allGranted) {
      print("All permissions granted, starting scan...");
      startScan();
    } else {
      print("Required permissions not granted!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required permissions not granted!")),
      );
    }
  }

  void startScan() {
    setState(() {
      isScanning = true;
      scanResults.clear();
      hasScanned = true;
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)).then((_) {
      setState(() {
        isScanning = false;
      });
    });
    scanSubscription?.cancel();
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results.where((r) => r.device.name.isNotEmpty).toList();
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      // Ignore if already connected.
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
      await _saveLastDeviceId(device.id.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connected: ${device.name}")));
      // Monitor device state.
      BLEHelper.monitorDeviceState(device);
      // Set up periodic RSSI check.
      _connectionCheckTimer?.cancel();
      _connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (
        timer,
      ) async {
        try {
          int rssi = await device.readRssi().timeout(
            const Duration(seconds: 2),
          );
          if (rssi <= 0) {
            throw Exception("Unexpected RSSI: $rssi");
          }
        } catch (e) {
          timer.cancel();
          disconnectFromDevice(device);
        }
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Target service/characteristic not found"),
        ),
      );
      await device.disconnect();
    }
  }

  void disconnectFromDevice(BluetoothDevice device) async {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    try {
      await device.disconnect();
    } catch (e) {
      print("Disconnect error: $e");
    }
    BLEHelper.clearConnection();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Disconnected: ${device.name}")));
    setState(() {});
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColorsController = Get.find<AppColorsController>();

    Widget connectedDeviceWidget = Obx(() {
      if (BLEHelper.connectedDevice.value != null) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appColorsController.greyColor.value.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Connected Device: ${BLEHelper.connectedDevice.value!.name}",
                  style: TextStyle(
                    color: appColorsController.whiteColor.value,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    () =>
                        disconnectFromDevice(BLEHelper.connectedDevice.value!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColorsController.primaryColor.value,
                ),
                child: Text(
                  "Unconnect",
                  style: TextStyle(color: appColorsController.whiteColor.value),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appColorsController.greyColor.value.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Connected Device: Unavailable",
            style: TextStyle(
              color: appColorsController.whiteColor.value,
              fontSize: 16,
            ),
          ),
        );
      }
    });

    final List<ScanResult> filteredResults =
        BLEHelper.connectedDevice.value != null
            ? scanResults
                .where(
                  (r) => r.device.id != BLEHelper.connectedDevice.value!.id,
                )
                .toList()
            : scanResults;

    Widget listWidget;
    if (isScanning) {
      listWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                appColorsController.primaryColor.value,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Aranıyor...",
              style: TextStyle(color: appColorsController.whiteColor.value),
            ),
          ],
        ),
      );
    } else if (!isScanning && filteredResults.isEmpty && hasScanned) {
      listWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hiçbir cihaz bulunamadı.",
              style: TextStyle(color: appColorsController.whiteColor.value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: requestPermissionsAndStartScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: appColorsController.primaryColor.value,
              ),
              child: Text(
                "Tekrar Ara",
                style: TextStyle(color: appColorsController.whiteColor.value),
              ),
            ),
          ],
        ),
      );
    } else {
      listWidget = ListView.builder(
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          ScanResult result = filteredResults[index];
          return ListTile(
            tileColor: appColorsController.greyColor.value.withOpacity(0.2),
            title: Text(
              result.device.name.isNotEmpty
                  ? result.device.name
                  : result.device.id.toString(),
              style: TextStyle(color: appColorsController.whiteColor.value),
            ),
            subtitle: Text(
              "RSSI: ${result.rssi}",
              style: TextStyle(color: appColorsController.white70Color.value),
            ),
            trailing: Obx(() {
              bool isConnected =
                  BLEHelper.connectedDevice.value != null &&
                  BLEHelper.connectedDevice.value!.id == result.device.id;
              return ElevatedButton(
                onPressed: () {
                  if (isConnected) {
                    disconnectFromDevice(result.device);
                  } else {
                    connectToDevice(result.device);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColorsController.primaryColor.value,
                ),
                child: Text(
                  isConnected ? "Unconnect" : "Connect",
                  style: TextStyle(color: appColorsController.whiteColor.value),
                ),
              );
            }),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      appBar: AppBar(
        title: Text(
          "BLE Scanner",
          style: TextStyle(color: appColorsController.whiteColor.value),
        ),
        backgroundColor: appColorsController.blackColor.value,
        iconTheme: IconThemeData(color: appColorsController.whiteColor.value),
      ),
      body: Column(
        children: [connectedDeviceWidget, Expanded(child: listWidget)],
      ),
      floatingActionButton:
          (scanResults.isNotEmpty || isScanning)
              ? FloatingActionButton(
                onPressed: requestPermissionsAndStartScan,
                backgroundColor: appColorsController.primaryColor.value,
                child: Icon(
                  Icons.search,
                  color: appColorsController.whiteColor.value,
                ),
              )
              : null,
    );
  }
}
