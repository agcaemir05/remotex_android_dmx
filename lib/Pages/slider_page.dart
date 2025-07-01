import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ble_helper.dart';
import '../Utils/style.dart'; // Buton stil fonksiyonları
import '../utils/colors.dart'; // GetX tema renkleri

class SliderPage extends StatefulWidget {
  const SliderPage({Key? key}) : super(key: key);

  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  final appColorsController = Get.put(AppColorsController());

  double red = 0;
  double green = 0;
  double blue = 0;
  double white = 0; // White slider için değişken
  double brightness = 255; // Ön izleme kutusundaki parlaklık değeri

  bool isSending = false;
  Timer? _debounce;

  /// Slider değiştiğinde 30ms sonra komutu gönderir.
  void _onColorChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 30), () {
      if (isSending) {
        sendColorCommand();
      }
    });
  }

  /// BLE cihazına RGB veya RGBW komutunu gönderir.
  Future<void> sendColorCommand() async {
    if (!isSending) return;

    int r = red.toInt();
    int g = green.toInt();
    int b = blue.toInt();
    int p = brightness.toInt();

    String command;
    if (BLEHelper.mode.value == "RGBW") {
      int w = white.toInt();
      command = "RGBW:$r,$g,$b,$w,$p";
    } else {
      command = "RGB:$r,$g,$b,$p";
    }

    List<int> bytes = command.codeUnits;
    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(bytes);
        print("Gönderilen komut: $command");
      } catch (e) {
        print("Renk komutu gönderme hatası: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Renk komutu gönderilemedi")),
          );
        }
        // Hata alınırsa bağlı cihazı temizle.
        BLEHelper.clearConnection();
      }
    } else {
      print("Bağlı BLE cihazı yok!");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bağlı BLE cihazı yok!")));
      }
      BLEHelper.clearConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Renk önizleme kutusu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                      brightness.toInt(),
                      red.toInt(),
                      green.toInt(),
                      blue.toInt(),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Sliders bölümünü içeren Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red slider
                  Text(
                    "Red: ${red.toInt()}",
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  Slider(
                    inactiveColor: Colors.red.withOpacity(0.5),
                    activeColor: Colors.red,
                    min: 0,
                    max: 255,
                    divisions: 255,
                    value: red,
                    label: red.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        red = value;
                      });
                      _onColorChanged();
                    },
                  ),
                  // Green slider
                  Text(
                    "Green: ${green.toInt()}",
                    style: const TextStyle(color: Colors.green, fontSize: 18),
                  ),
                  Slider(
                    activeColor: Colors.green,
                    inactiveColor: Colors.green.withOpacity(0.5),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    value: green,
                    label: green.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        green = value;
                      });
                      _onColorChanged();
                    },
                  ),
                  // Blue slider
                  Text(
                    "Blue: ${blue.toInt()}",
                    style: const TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                  Slider(
                    activeColor: Colors.blue,
                    inactiveColor: Colors.blue.withOpacity(0.5),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    value: blue,
                    label: blue.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        blue = value;
                      });
                      _onColorChanged();
                    },
                  ),
                  // White slider, sadece mod "RGBW" ise gösterilir
                  if (BLEHelper.mode.value == "RGBW") ...[
                    Text(
                      "White: ${white.toInt()}",
                      style: const TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    Slider(
                      activeColor: Colors.grey,
                      inactiveColor: Colors.grey.withOpacity(0.5),
                      min: 0,
                      max: 255,
                      divisions: 255,
                      value: white,
                      label: white.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          white = value;
                        });
                        _onColorChanged();
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Brightness slider
                  Text(
                    "Brightness: ${brightness.toInt()}",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withOpacity(0.5),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    value: brightness,
                    label: brightness.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        brightness = value;
                      });
                      _onColorChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Start ve Stop butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: buildCustomElevatedButtonPrimary(
                      "Start",
                      () {
                        setState(() {
                          isSending = true;
                        });
                        sendColorCommand();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      icon: Icons.play_arrow,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: buildCustomElevatedButtonSecondary(
                      "Stop",
                      () {
                        setState(() {
                          isSending = false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      icon: Icons.stop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
