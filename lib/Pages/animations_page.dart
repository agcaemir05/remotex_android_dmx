import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Utils/ble_helper.dart';
import '../Utils/ble_helper.dart'; // Buton stil fonksiyonları
import '../utils/colors.dart'; // GetX tema renkleri

/// Animasyon türleri. 'rainbowSeq' pikselleri sırayla rainbow yapar.
enum AnimationType { rgb, fade, rainbow, rainbowSeq, strobe, snake }

class AnimationsPage extends StatefulWidget {
  const AnimationsPage({super.key});

  @override
  _AnimationsPageState createState() => _AnimationsPageState();
}

class _AnimationsPageState extends State<AnimationsPage>
    with TickerProviderStateMixin {
  final appColorsController = Get.put(AppColorsController());

  // Seçili animasyon; hem üst önizleme hem de grid butonlarda kullanılıyor.
  AnimationType _selectedAnimation = AnimationType.rgb;
  double opacity = 1.0;
  bool isSending = false;
  Timer? _debounce;

  // Üst önizleme için controller'lar (Start butonuna basıldığında çalışacak)
  late AnimationController _rgbController;
  late Animation<Color?> _rgbAnimation;
  late AnimationController _rainbowController;
  late AnimationController _fadeController;
  late AnimationController _strobeController;
  late AnimationController _snakeController;

  double _hue = 0.0;
  double _fadeValue = 1.0;

  @override
  void initState() {
    super.initState();

    _rgbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _rgbAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.red, end: Colors.green),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.green, end: Colors.blue),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.blue, end: Colors.red),
        weight: 1,
      ),
    ]).animate(_rgbController);

    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      setState(() {
        _hue = _rainbowController.value * 360;
      });
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
      setState(() {
        _fadeValue = 0.5 + 0.5 * sin(2 * pi * _fadeController.value);
      });
    });

    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
      setState(() {}); // Her tick'te yeniden çizdir.
    });

    _snakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
      setState(() {}); // Her tick'te yeniden çizdir.
    });

    // Üst önizleme controller'ları, Start butonuna basılana kadar çalıştırılmıyor.
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rgbController.dispose();
    _rainbowController.dispose();
    _fadeController.dispose();
    _strobeController.dispose();
    _snakeController.dispose();
    super.dispose();
  }

  Future<void> sendAnimationCommand() async {
    if (!isSending) return;
    String command = "";
    switch (_selectedAnimation) {
      case AnimationType.rgb:
        command = "ANIM:RGB:";
        break;
      case AnimationType.fade:
        command = "ANIM:FADE:$opacity";
        break;
      case AnimationType.rainbow:
        command = "ANIM:RAINBOW:";
        break;
      case AnimationType.rainbowSeq:
        command = "ANIM:RAINBOWSEQ:";
        break;
      case AnimationType.strobe:
        command = "ANIM:STROBE:";
        break;
      case AnimationType.snake:
        command = "ANIM:SNAKE:";
        break;
    }
    List<int> bytes = command.codeUnits;
    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(bytes);
        print("Gönderilen animasyon komutu: $command");
      } catch (e) {
        print("Animasyon komutu gönderme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Animasyon komutu gönderilemedi")),
        );
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

  Future<void> sendStopCommand() async {
    String command = "ANIM:STOP:";
    List<int> bytes = command.codeUnits;
    if (BLEHelper.connectedCharacteristic != null) {
      try {
        await BLEHelper.connectedCharacteristic!.write(bytes);
        print("Gönderilen animasyon durdurma komutu: $command");
      } catch (e) {
        print("Animasyon durdurma komutu gönderme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Animasyon durdurma komutu gönderilemedi"),
          ),
        );
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

  /// Üstteki büyük önizleme alanı.
  Widget _buildAnimationPreview() {
    switch (_selectedAnimation) {
      case AnimationType.rgb:
        return AnimatedBuilder(
          animation: _rgbAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: _rgbAnimation.value ?? Colors.white,
            );
          },
        );
      case AnimationType.fade:
        Color fadeColor = Color.lerp(Colors.blue, Colors.red, _fadeValue)!;
        int computedAlpha = (opacity * 255).toInt().clamp(0, 255);
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: fadeColor.withAlpha(computedAlpha),
        );
      case AnimationType.rainbow:
        Color rainbowColor = HSVColor.fromAHSV(1, _hue, 1, 1).toColor();
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: rainbowColor,
        );
      case AnimationType.rainbowSeq:
        return LayoutBuilder(
          builder: (context, constraints) {
            double totalWidth = constraints.maxWidth;
            int blocks = 10;
            double blockWidth = totalWidth / blocks;
            return Container(
              color: Colors.black,
              child: Row(
                children: List.generate(blocks, (index) {
                  double hue =
                      ((_rainbowController.value * 360) +
                          (index * (360 / blocks))) %
                      360;
                  Color blockColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
                  return Container(
                    width: blockWidth,
                    height: double.infinity,
                    color: blockColor,
                  );
                }),
              ),
            );
          },
        );
      case AnimationType.strobe:
        return AnimatedBuilder(
          animation: _strobeController,
          builder: (context, child) {
            Color color =
                (_strobeController.value < 0.5) ? Colors.white : Colors.black;
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: color,
            );
          },
        );
      case AnimationType.snake:
        return LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;
            double height = constraints.maxHeight;
            double progress = _snakeController.value;
            double snakeLength = width * 0.2;
            return Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Positioned(
                    left: width * progress,
                    top: height / 2 - 15,
                    child: Container(
                      width: snakeLength,
                      height: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  /// Grid şeklinde animasyon butonları.
  Widget buildAnimationGrid() {
    final List<AnimationType> animationTypes = [
      AnimationType.rgb,
      AnimationType.fade,
      AnimationType.rainbow,
      AnimationType.rainbowSeq,
      AnimationType.strobe,
      AnimationType.snake,
    ];

    final List<String> labels = [
      "RGB",
      "Fade",
      "Rainbow",
      "Rainbow Seq",
      "Strobe",
      "Snake",
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: animationTypes.length,
      itemBuilder: (context, index) {
        final type = animationTypes[index];
        final scaleFactor = (_selectedAnimation == type) ? 1.1 : 1.0;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAnimation = type;
            });
            sendAnimationCommand();
          },
          child: AnimatedScale(
            scale: scaleFactor,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _AnimationMiniPreview(animationType: type),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColorsController.blackColor.value,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Üstteki büyük önizleme kutusu.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildAnimationPreview(),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Grid şeklinde animasyon butonları.
              buildAnimationGrid(),
              if (_selectedAnimation == AnimationType.fade) ...[
                const SizedBox(height: 20),
                Text(
                  "Brightness: ${(opacity * 100).toInt()}%",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.5),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  value: opacity,
                  label: (opacity * 100).toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      opacity = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 40),
              // Start ve Stop butonları.
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
                        sendAnimationCommand();
                        _rgbController.repeat();
                        _rainbowController.repeat();
                        _fadeController.repeat();
                        _strobeController.repeat();
                        _snakeController.repeat();
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
                        sendStopCommand();
                        _rgbController.stop();
                        _rainbowController.stop();
                        _fadeController.stop();
                        _strobeController.stop();
                        _snakeController.stop();
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

class _AnimationMiniPreview extends StatefulWidget {
  final AnimationType animationType;
  const _AnimationMiniPreview({required this.animationType});

  @override
  __AnimationMiniPreviewState createState() => __AnimationMiniPreviewState();
}

class __AnimationMiniPreviewState extends State<_AnimationMiniPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  Animation<Color?>? rgbAnimation;
  double fadeValue = 1.0;
  double hue = 0.0;

  @override
  void initState() {
    super.initState();
    switch (widget.animationType) {
      case AnimationType.rgb:
        controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 3),
        );
        rgbAnimation = TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(begin: Colors.red, end: Colors.green),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: Colors.green, end: Colors.blue),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: Colors.blue, end: Colors.red),
            weight: 1,
          ),
        ]).animate(controller);
        controller.repeat();
        break;
      case AnimationType.fade:
        controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        );
        controller.addListener(() {
          setState(() {
            fadeValue = 0.5 + 0.5 * sin(2 * pi * controller.value);
          });
        });
        controller.repeat();
        break;
      case AnimationType.rainbow:
      case AnimationType.rainbowSeq:
        controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 5),
        );
        controller.addListener(() {
          setState(() {
            hue = controller.value * 360;
          });
        });
        controller.repeat();
        break;
      case AnimationType.strobe:
        controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );
        controller.addListener(() {
          setState(() {});
        });
        controller.repeat();
        break;
      case AnimationType.snake:
        controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 3),
        );
        controller.addListener(() {
          setState(() {});
        });
        controller.repeat();
        break;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildPreview() {
    switch (widget.animationType) {
      case AnimationType.rgb:
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Container(color: rgbAnimation?.value ?? Colors.white);
          },
        );
      case AnimationType.fade:
        Color fadeColor = Color.lerp(Colors.blue, Colors.red, fadeValue)!;
        int computedAlpha = (fadeValue * 255).toInt().clamp(0, 255);
        return Container(color: fadeColor.withAlpha(computedAlpha));
      case AnimationType.rainbow:
        Color rainbowColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
        return Container(color: rainbowColor);
      case AnimationType.rainbowSeq:
        int blocks = 5;
        return LayoutBuilder(
          builder: (context, constraints) {
            double totalWidth = constraints.maxWidth;
            double blockWidth = totalWidth / blocks;
            return Row(
              children: List.generate(blocks, (index) {
                double blockHue = ((hue) + (index * (360 / blocks))) % 360;
                Color blockColor =
                    HSVColor.fromAHSV(1, blockHue, 1, 1).toColor();
                return Container(width: blockWidth, color: blockColor);
              }),
            );
          },
        );
      case AnimationType.strobe:
        Color strobeColor =
            (controller.value < 0.5) ? Colors.white : Colors.black;
        return Container(color: strobeColor);
      case AnimationType.snake:
        return LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;
            double progress = controller.value;
            double snakeLength = width * 0.3;
            return Stack(
              children: [
                Container(color: Colors.black),
                Positioned(
                  left: width * progress,
                  top: 0,
                  bottom: 0,
                  child: Container(width: snakeLength, color: Colors.white),
                ),
              ],
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildPreview();
  }
}
