// settings_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ble_helper.dart';
import '../utils/colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final appColorsController = Get.put(AppColorsController());
  final TextEditingController _pixelController = TextEditingController();

  // Varsayılan mod, initState'te global değerden alınacak.
  String mode = "RGB";

  @override
  void initState() {
    super.initState();
    // Global olarak ayarlanmış mod (örn. BLEHelper.mode) varsa onu kullanıyoruz.
    mode = BLEHelper.mode.value;
  }

  // Mode komutunu BLE üzerinden gönder
  void _sendModeValue(String newMode) {
    if (BLEHelper.connectedCharacteristic != null) {
      String command = "MODE:$newMode";
      BLEHelper.connectedCharacteristic!.write(command.codeUnits);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mod değeri gönderildi: $newMode")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bağlı BLE cihazı yok!")));
    }
  }

  // Piksel komutunu gönder (gönderilen değer doğrudan maksimum piksel sayısını temsil edecek)
  void _sendPixelValue() {
    if (BLEHelper.connectedCharacteristic != null) {
      int pixelCount = int.tryParse(_pixelController.text) ?? 0;
      if (pixelCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen geçerli bir piksel numarası girin."),
          ),
        );
        return;
      }
      String command = "Piksel:$pixelCount";
      BLEHelper.connectedCharacteristic!.write(command.codeUnits);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Piksel değeri gönderildi: $pixelCount")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bağlı BLE cihazı yok!")));
    }
  }

  @override
  void dispose() {
    _pixelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: appColorsController.whiteColor.value),
        ),
        backgroundColor: appColorsController.blackColor.value,
        iconTheme: IconThemeData(color: appColorsController.whiteColor.value),
      ),
      backgroundColor: appColorsController.blackColor.value,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Piksel Bölümü
            Text(
              "Maksimum Piksel Sayısı",
              style: TextStyle(
                color: appColorsController.whiteColor.value,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pixelController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: appColorsController.whiteColor.value,
                    ),
                    decoration: InputDecoration(
                      hintText: "Maksimum Piksel Sayısı",
                      hintStyle: TextStyle(
                        color: appColorsController.greyColor.value,
                      ),
                      labelStyle: TextStyle(
                        color: appColorsController.whiteColor.value,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendPixelValue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColorsController.primaryColor.value,
                  ),
                  child: Text(
                    "Gönder",
                    style: TextStyle(
                      color: appColorsController.whiteColor.value,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Mode Seçimi Bölümü
            Text(
              "Mode",
              style: TextStyle(
                color: appColorsController.whiteColor.value,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // RGB Seçeneği
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        mode = "RGB";
                        BLEHelper.mode.value = "RGB";
                        _sendModeValue("RGB");
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            mode == "RGB"
                                ? appColorsController.primaryColor.value
                                : appColorsController.greyColor.value,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: mode == "RGB",
                            onChanged: (bool? val) {
                              setState(() {
                                mode = "RGB";
                                BLEHelper.mode.value = "RGB";
                                _sendModeValue("RGB");
                              });
                            },
                          ),
                          Text(
                            "RGB",
                            style: TextStyle(
                              color: appColorsController.whiteColor.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // RGBW Seçeneği
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        mode = "RGBW";
                        BLEHelper.mode.value = "RGBW";
                        _sendModeValue("RGBW");
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            mode == "RGBW"
                                ? appColorsController.primaryColor.value
                                : appColorsController.greyColor.value,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: mode == "RGBW",
                            onChanged: (bool? val) {
                              setState(() {
                                mode = "RGBW";
                                BLEHelper.mode.value = "RGBW";
                                _sendModeValue("RGBW");
                              });
                            },
                          ),
                          Text(
                            "RGBW",
                            style: TextStyle(
                              color: appColorsController.whiteColor.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
