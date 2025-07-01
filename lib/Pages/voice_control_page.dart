// vu_meter_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ble_helper.dart';
import '../utils/colors.dart';
import '../Utils/style.dart';

class VuMeterPage extends StatefulWidget {
  const VuMeterPage({Key? key}) : super(key: key);

  @override
  _VuMeterPageState createState() => _VuMeterPageState();
}

class _VuMeterPageState extends State<VuMeterPage> {
  final AppColorsController appColorsController = Get.put(
    AppColorsController(),
  );

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  bool _isRecording = false;
  double _currentDb = 0.0; // Ölçülen ses seviyesi (dB cinsinden)
  int _mappedValue = 0; // dB değerinin 0-255 aralığına haritalanmış hali

  @override
  void initState() {
    super.initState();
    _noiseMeter = NoiseMeter();
    requestMicrophonePermission().then((granted) {
      if (granted) {
        startListening();
      } else {
        print("Mikrofon izni verilmedi!");
      }
    });
  }

  Future<bool> requestMicrophonePermission() async {
    if (await Permission.microphone.isGranted) {
      return true;
    } else {
      var status = await Permission.microphone.request();
      return status.isGranted;
    }
  }

  void onData(NoiseReading noiseReading) {
    setState(() {
      _currentDb = noiseReading.meanDecibel;
      // Örnek ayarlar: 30 dB minimum, 90 dB maksimum kabul ediyoruz.
      double dBMin = 30.0;
      double dBMax = 90.0;
      double normalized = ((_currentDb - dBMin) / (dBMax - dBMin)).clamp(
        0.0,
        1.0,
      );
      _mappedValue = (normalized * 255).toInt();
      print("Ortalama dB: $_currentDb, Haritalanmış: $_mappedValue");
      // Veriyi aldıktan hemen sonra komutu gönderiyoruz.
      sendVuMeterCommand(_mappedValue);
    });
  }

  void onError(Object error) {
    print("NoiseMeter error: $error");
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> startListening() async {
    try {
      _noiseSubscription = _noiseMeter!.noise.listen(onData, onError: onError);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print("Error starting noise meter: $e");
    }
  }

  Future<void> stopListening() async {
    try {
      await _noiseSubscription?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print("Error stopping noise meter: $e");
    }
  }

  void sendVuMeterCommand(int value) async {
    String command = "VU:$value";
    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(command.codeUnits);
        print("Gönderilen VU komutu: $command");
      } catch (e) {
        print("VU komutu gönderme hatası: $e");
        BLEHelper.clearConnection();
      }
    } else {
      print("Bağlı BLE cihazı yok!");
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      appBar: AppBar(
        title: Text(
          "Voice Control",
          style: TextStyle(color: appColorsController.whiteColor.value),
        ),
        backgroundColor: appColorsController.blackColor.value,
        iconTheme: IconThemeData(color: appColorsController.whiteColor.value),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Anlık dB: ${_currentDb.toStringAsFixed(2)} dB",
              style: TextStyle(
                color: appColorsController.whiteColor.value,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            // dB değerine göre dolan görsel bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: appColorsController.greyColor.value,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _mappedValue / 255,
                      child: Container(
                        decoration: BoxDecoration(
                          color: appColorsController.primaryColor.value,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "LED Değeri: $_mappedValue",
              style: TextStyle(
                color: appColorsController.whiteColor.value,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            // Başlat ve Durdur butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildCustomElevatedButtonPrimary(
                  "Başlat",
                  () {
                    if (!_isRecording) {
                      startListening();
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  icon: Icons.play_arrow,
                ),
                buildCustomElevatedButtonSecondary(
                  "Durdur",
                  () {
                    if (_isRecording) {
                      stopListening();
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  icon: Icons.stop,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
