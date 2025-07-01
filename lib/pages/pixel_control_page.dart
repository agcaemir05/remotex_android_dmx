import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/ble_helper.dart';
import '../utils/style.dart'; // Buton stil fonksiyonları
import '../utils/colors.dart'; // GetX tema renkleri

class SinglePixelControlPage extends StatefulWidget {
  const SinglePixelControlPage({Key? key}) : super(key: key);

  @override
  _SinglePixelControlPageState createState() => _SinglePixelControlPageState();
}

class _SinglePixelControlPageState extends State<SinglePixelControlPage> {
  final appColorsController = Get.put(AppColorsController());

  // Kullanıcının ayarlayacağı piksel numarası (1-indexli)
  final TextEditingController _pixelController = TextEditingController(
    text: "1",
  );

  double red = 0;
  double green = 0;
  double blue = 0;
  double white = 0; // Sadece RGBW modunda kullanılacak.
  double brightness = 255; // Parlaklık değeri

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

  /// BLE üzerinden sadece seçili pikselin renk değerlerini gönderir.
  Future<void> sendColorCommand() async {
    int pixelNumber = int.tryParse(_pixelController.text) ?? 0;
    if (pixelNumber <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen geçerli bir piksel numarası girin."),
        ),
      );
      return;
    }

    int r = red.toInt();
    int g = green.toInt();
    int b = blue.toInt();
    int p = brightness.toInt();

    String command;
    // Mod kontrolünü boşlukları silip büyük harf olarak yapıyoruz.
    bool isRGBW = (BLEHelper.mode.value.trim().toUpperCase() == "RGBW");
    if (isRGBW) {
      int w = white.toInt();
      command = "PIXCTRL:$pixelNumber:$r,$g,$b,$w,$p";
    } else {
      command = "PIXCTRL:$pixelNumber:$r,$g,$b,$p";
    }

    print("Gönderilen piksel komutu: $command");

    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(command.codeUnits);
      } catch (e) {
        print("PIXCTRL komutu gönderme hatası: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIXCTRL komutu gönderilemedi")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bağlı BLE cihazı yok!")));
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pixelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mod kontrolü için büyük harfe çevirerek kontrol ediyoruz.
    bool isRGBW = (BLEHelper.mode.value.trim().toUpperCase() == "RGBW");
    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      appBar: AppBar(
        backgroundColor: appColorsController.blackColor.value,
        // Geri tuşu eklenmiş durumda (AppBar'ın otomatik back buttonu çalışacaktır)
        iconTheme: IconThemeData(color: appColorsController.whiteColor.value),
        title: const Text(
          "Tek Piksel Kontrol",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Piksel numarası girilecek alan
              TextField(
                controller: _pixelController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: appColorsController.whiteColor.value),
                decoration: InputDecoration(
                  labelText: "Piksel Numarası (1-indexli)",
                  labelStyle: TextStyle(
                    color: appColorsController.whiteColor.value,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Renk önizleme kutusu
              Container(
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
              const SizedBox(height: 30),
              // Renk ve parlaklık slider'ları
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
                  // White slider, sadece RGBW modunda gösterilir
                  if (isRGBW) ...[
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
