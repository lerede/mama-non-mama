import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MamaNonMamaApp());
}

class MamaNonMamaApp extends StatelessWidget {
  const MamaNonMamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "M'ama Non M'ama",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  static const int totalPetals = 11;

  late List<AnimationController> _petalControllers;
  late List<Animation<double>> _petalFallAnimations;
  late List<Animation<double>> _petalOpacityAnimations;

  final List<bool> _petalRemoved = List.filled(totalPetals, false);
  int _removedCount = 0;
  bool _gameStarted = false;
  bool _gameFinished = false;
  bool _isAnimating = false;
  String _currentMessage = '';

  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _messageController;
  late Animation<double> _messageAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _petalControllers = List.generate(totalPetals, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 900),
        vsync: this,
      );
    });

    _petalFallAnimations = _petalControllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      );
    }).toList();

    _petalOpacityAnimations = _petalControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _messageController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _messageAnimation = CurvedAnimation(
      parent: _messageController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _startGame() async {
    if (_gameStarted) return;
    setState(() {
      _gameStarted = true;
      _isAnimating = true;
      _currentMessage = "M'ama...";
    });
    _messageController.forward(from: 0);

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('music/background.mp3'));
    } catch (_) {
      // Continue without music if asset is unavailable
    }

    _removePetalSequentially(0);
  }

  void _removePetalSequentially(int index) async {
    if (!mounted) return;

    if (index >= totalPetals) {
      final bool loves = (_removedCount % 2 == 1);
      setState(() {
        _gameFinished = true;
        _isAnimating = false;
        _currentMessage = loves ? "M'ama! ❤️" : "Non m'ama... 💔";
      });
      _messageController.forward(from: 0);
      await _audioPlayer.stop();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await _petalControllers[index].forward();

    if (!mounted) return;
    setState(() {
      _petalRemoved[index] = true;
      _removedCount++;
      final bool loves = (_removedCount % 2 == 1);
      _currentMessage = loves ? "M'ama..." : "Non m'ama...";
    });
    _messageController.forward(from: 0);
    _removePetalSequentially(index + 1);
  }

  Future<void> _resetGame() async {
    await _audioPlayer.stop();
    for (var controller in _petalControllers) {
      controller.reset();
    }
    _messageController.reset();
    setState(() {
      for (int i = 0; i < totalPetals; i++) {
        _petalRemoved[i] = false;
      }
      _removedCount = 0;
      _gameStarted = false;
      _gameFinished = false;
      _isAnimating = false;
      _currentMessage = '';
    });
  }

  @override
  void dispose() {
    for (var controller in _petalControllers) {
      controller.dispose();
    }
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "M'ama Non M'ama",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.pink[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.85;
                    return AnimatedBuilder(
                      animation: Listenable.merge(_petalControllers),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: FlowerPainter(
                            totalPetals: totalPetals,
                            petalFallAnimations: _petalFallAnimations,
                            petalOpacityAnimations: _petalOpacityAnimations,
                            petalRemoved: _petalRemoved,
                          ),
                          size: Size(size, size),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 70,
              child: AnimatedBuilder(
                animation: _messageAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + _messageAnimation.value * 0.2,
                    child: Opacity(
                      opacity: _currentMessage.isNotEmpty ? 1.0 : 0.0,
                      child: Text(
                        _currentMessage,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: _currentMessage.contains('Non')
                              ? Colors.grey[600]
                              : Colors.pink[600],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (!_gameStarted)
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            if (_gameFinished)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(
                  onPressed: _resetGame,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pink[400],
                    side: BorderSide(color: Colors.pink[300]!, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    'Riprova 🌸',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// Draws a daisy flower with petals that animate away one by one.
class FlowerPainter extends CustomPainter {
  final int totalPetals;
  final List<Animation<double>> petalFallAnimations;
  final List<Animation<double>> petalOpacityAnimations;
  final List<bool> petalRemoved;

  FlowerPainter({
    required this.totalPetals,
    required this.petalFallAnimations,
    required this.petalOpacityAnimations,
    required this.petalRemoved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final petalLength = radius * 0.70;
    final petalWidth = petalLength * 0.42;

    // Draw stem
    _drawStem(canvas, center, size, radius);

    // Draw petals
    for (int i = 0; i < totalPetals; i++) {
      if (petalRemoved[i]) continue;
      _drawPetal(canvas, center, radius, petalLength, petalWidth, i);
    }

    // Draw flower center
    _drawCenter(canvas, center, radius);
  }

  void _drawStem(Canvas canvas, Offset center, Size size, double radius) {
    final stemPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    final stemTop = center.dy + radius * 0.28;
    final stemBottom = size.height * 0.92;
    stemPath.moveTo(center.dx, stemTop);
    stemPath.cubicTo(
      center.dx + 18, stemTop + (stemBottom - stemTop) * 0.33,
      center.dx - 18, stemTop + (stemBottom - stemTop) * 0.66,
      center.dx, stemBottom,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Left leaf
    final leafPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;

    final leafY = stemTop + (stemBottom - stemTop) * 0.38;
    final leftLeaf = Path();
    leftLeaf.moveTo(center.dx - 5, leafY);
    leftLeaf.quadraticBezierTo(center.dx - 50, leafY - 22, center.dx - 55, leafY + 15);
    leftLeaf.quadraticBezierTo(center.dx - 25, leafY + 8, center.dx - 5, leafY);
    canvas.drawPath(leftLeaf, leafPaint);

    // Right leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(center.dx + 5, leafY + 20);
    rightLeaf.quadraticBezierTo(center.dx + 52, leafY - 2, center.dx + 50, leafY + 30);
    rightLeaf.quadraticBezierTo(center.dx + 22, leafY + 24, center.dx + 5, leafY + 20);
    canvas.drawPath(rightLeaf, leafPaint);
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double radius,
    double petalLength,
    double petalWidth,
    int index,
  ) {
    final angle = (2 * math.pi / totalPetals) * index - math.pi / 2;
    final fall = petalFallAnimations[index].value;
    final opacity = petalOpacityAnimations[index].value;

    // Petal detaches from flower, rotates and drifts to a side
    final sideDir = (index % 2 == 0) ? 1.0 : -1.0;
    final fallX = sideDir * fall * radius * 0.8 * math.sin(fall * math.pi);
    final fallY = fall * radius * 2.0;
    final spin = fall * math.pi * 1.5 * sideDir;

    canvas.save();
    canvas.translate(center.dx + fallX, center.dy + fallY);
    canvas.rotate(angle + spin);

    // Petal shadow
    final shadowPaint = Paint()
      ..color = Colors.pink.withOpacity(0.10 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(2, -radius * 0.78 + 4),
        width: petalWidth,
        height: petalLength,
      ),
      shadowPaint,
    );

    // Gradient-like petal fill (simulated with two overlapping ovals)
    final petalPaintBase = Paint()
      ..color = const Color(0xFFFFC1CC).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final petalPaintHighlight = Paint()
      ..color = const Color(0xFFFFE4EC).withOpacity(opacity * 0.7)
      ..style = PaintingStyle.fill;

    final petalRect = Rect.fromCenter(
      center: Offset(0, -radius * 0.78),
      width: petalWidth,
      height: petalLength,
    );

    canvas.drawOval(petalRect, petalPaintBase);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-petalWidth * 0.1, -radius * 0.78 - petalLength * 0.05),
        width: petalWidth * 0.55,
        height: petalLength * 0.7,
      ),
      petalPaintHighlight,
    );

    // Petal outline
    final outlinePaint = Paint()
      ..color = Colors.pink[200]!.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(petalRect, outlinePaint);

    // Midrib line
    final midribPaint = Paint()
      ..color = Colors.pink[300]!.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final midrib = Path();
    midrib.moveTo(0, -radius * 0.42);
    midrib.lineTo(0, -radius * 0.78 - petalLength * 0.42);
    canvas.drawPath(midrib, midribPaint);

    canvas.restore();
  }

  void _drawCenter(Canvas canvas, Offset center, double radius) {
    final centerRadius = radius * 0.26;

    // Outer glow
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, centerRadius + 4, glowPaint);

    // Main disk
    final diskPaint = Paint()
      ..color = const Color(0xFFFFCA28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius, diskPaint);

    // Inner ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius * 0.72, innerRingPaint);

    // Seed dots
    final dotPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;
    // Fixed seed produces stable dot positions across repaints.
    final rng = math.Random(99);
    for (int i = 0; i < 22; i++) {
      final dotAngle = rng.nextDouble() * 2 * math.pi;
      final dotR = rng.nextDouble() * centerRadius * 0.62;
      canvas.drawCircle(
        Offset(center.dx + dotR * math.cos(dotAngle), center.dy + dotR * math.sin(dotAngle)),
        1.6,
        dotPaint,
      );
    }

    // Disk outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, centerRadius, outlinePaint);
  }

  @override
  bool shouldRepaint(FlowerPainter oldDelegate) => true;
}
