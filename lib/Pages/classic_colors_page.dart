import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ble_helper.dart';
import '../utils/colors.dart'; // GetX tema renkleri

class ClassicColorsPage extends StatefulWidget {
  const ClassicColorsPage({Key? key}) : super(key: key);

  @override
  ClassicColorsPageState createState() => ClassicColorsPageState();
}

class ClassicColorsPageState extends State<ClassicColorsPage> {
  // Klasik renkler listesi
  final List<Color> classicColors = const [
    Color(0xFFFF0000), // Pure Redz
    Color(0xFF00FF00), // Pure Green
    Color(0xFF0000FF), // Pure Blue
    Color(0xFFFFFF00), // Pure Yellow
    Color(0xFFFFA500), // Pure Orange
    Color(0xFF800080), // Pure Purple
  ];

  // Kelvin renkleri: sadece 2700K, 4500K ve 6500K değerlerine yakın renkler
  final List<Color> kelvinColors = const [
    Color(0xFFFFD6AA), // Yaklaşık 2700K - Warm White
    Color(0xFFFFF4E0), // Yaklaşık 4500K - Neutral White
    Color(0xFFF0F8FF), // Yaklaşık 6500K - Cool White
  ];

  // Kelvin etiketleri
  final List<String> kelvinLabels = const ["2700K", "4500K", "6500K"];

  int? selectedClassicIndex;
  int? selectedKelvinIndex;

  void sendClassicColorCommand(Color color) async {
    int r = color.red;
    int g = color.green;
    int b = color.blue;
    int p = 255; // Sabit parlaklık değeri
    String command;
    if (BLEHelper.mode.value == "RGBW") {
      // RGBW modunda beyaz değeri 0 olarak ayarlanıyor, fakat isteğe göre farklı hesaplanabilir
      int w = 0;
      command = "RGBW:$r,$g,$b,$w,$p";
    } else {
      command = "RGB:$r,$g,$b,$p";
    }

    List<int> bytes = command.codeUnits;
    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(bytes);
        print("Gönderilen klasik renk komutu: $command");
      } catch (e) {
        print("Klasik renk komutu gönderme hatası: $e");
        // Eğer hata alınırsa bağlantıyı temizle.
        BLEHelper.clearConnection();
      }
    } else {
      print("Bağlı BLE cihazı yok!");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bağlı BLE cihazı yok!")));
      BLEHelper.clearConnection();
    }
  }

  /// Renk kutularını grid şeklinde oluşturan widget.
  Widget buildColorGrid(
    List<Color> colors, {
    List<String>? labels,
    int? selectedIndex,
    Function(int)? onItemSelected,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        // Seçili öğe için scale farkı 1.1, diğerleri 1.0
        final scaleFactor =
            (selectedIndex != null && selectedIndex == index) ? 1.1 : 1.0;
        Widget colorBox = AnimatedScale(
          scale: scaleFactor,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
        if (labels != null && labels.length > index) {
          return GestureDetector(
            onTap: () {
              if (onItemSelected != null) {
                onItemSelected(index);
              }
              sendClassicColorCommand(color);
            },
            child: Column(
              children: [
                Expanded(child: colorBox),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          );
        } else {
          return GestureDetector(
            onTap: () {
              if (onItemSelected != null) {
                onItemSelected(index);
              }
              sendClassicColorCommand(color);
            },
            child: colorBox,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColorsController = Get.put(AppColorsController());
    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appColorsController.blackColor.value,
        iconTheme: IconThemeData(color: appColorsController.whiteColor.value),
        // Geri ok (back button) kaldırıldı.
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Classic Colors",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                buildColorGrid(
                  classicColors,
                  selectedIndex: selectedClassicIndex,
                  onItemSelected: (index) {
                    setState(() {
                      selectedClassicIndex = index;
                      selectedKelvinIndex = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  "Kelvin Colors",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                buildColorGrid(
                  kelvinColors,
                  labels: kelvinLabels,
                  selectedIndex: selectedKelvinIndex,
                  onItemSelected: (index) {
                    setState(() {
                      selectedKelvinIndex = index;
                      selectedClassicIndex = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
