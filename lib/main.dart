import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
      home: const GameScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum PetalState { attached, falling, fallen }

class PetalInfo {
  final double angle;
  PetalState state;
  double animValue;

  PetalInfo(this.angle)
      : state = PetalState.attached,
        animValue = 0;
}

// ---------------------------------------------------------------------------
// Game screen
// ---------------------------------------------------------------------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int _numPetals = 13;
  static const Duration _fallDuration = Duration(milliseconds: 1400);
  static const Duration _betweenDelay = Duration(milliseconds: 700);

  late List<PetalInfo> _petals;
  late List<AnimationController> _controllers;

  int _pluckedCount = 0;
  bool _gameStarted = false;
  bool _gameOver = false;
  String _currentWord = '';

  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initGame();
  }

  void _initGame() {
    _pluckedCount = 0;
    _gameStarted = false;
    _gameOver = false;
    _currentWord = '';

    _petals = List.generate(
      _numPetals,
      (i) => PetalInfo(2 * math.pi * i / _numPetals - math.pi / 2),
    );

    _controllers = List.generate(_numPetals, (i) {
      final c = AnimationController(duration: _fallDuration, vsync: this);
      c.addListener(() {
        if (_petals[i].state == PetalState.falling) {
          setState(() => _petals[i].animValue = c.value);
        }
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() => _gameStarted = true);

    // Start background music (gracefully skip if asset is missing)
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/music.mp3'));
    } catch (_) {
      // Music file not available – continue without sound
    }

    _pluckNext();
  }

  void _pluckNext() {
    if (_pluckedCount >= _numPetals) {
      _endGame();
      return;
    }

    final idx = _pluckedCount;
    final label = _pluckedCount.isEven ? "M'AMA" : "NON M'AMA";

    setState(() {
      _petals[idx].state = PetalState.falling;
      _currentWord = label;
      _pluckedCount++;
    });

    _controllers[idx].forward().then((_) {
      setState(() => _petals[idx].state = PetalState.fallen);
      Future.delayed(_betweenDelay, () {
        if (mounted) _pluckNext();
      });
    });
  }

  Future<void> _endGame() async {
    await _audioPlayer.stop();
    // Last petal index is _numPetals - 1; determine result
    final lastLabel = (_numPetals - 1).isEven ? "M'AMA! ❤️" : "NON M'AMA 💔";
    setState(() {
      _gameOver = true;
      _currentWord = lastLabel;
    });
  }

  Future<void> _restart() async {
    for (final c in _controllers) {
      c.dispose();
    }
    await _audioPlayer.stop();
    setState(_initGame);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            // Title
            Text(
              "M'ama Non M'ama",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.pink[700],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 20),
            // Current word label
            SizedBox(
              height: 52,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  _currentWord,
                  key: ValueKey(_currentWord),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _currentWord.contains('NON')
                            ? Colors.red[600]
                            : Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            // Flower
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.maxWidth.clamp(200.0, 340.0);
                    return AnimatedBuilder(
                      animation: Listenable.merge(_controllers),
                      builder: (context, _) => CustomPaint(
                        size: Size(side, side * 1.35),
                        painter: FlowerPainter(petals: _petals),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_gameStarted) _buildButton('START 🌸', _startGame),
                  if (_gameOver) _buildButton('Ricomincia 🌸', _restart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[500],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 5,
        shadowColor: Colors.pink[200],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter – draws flower + animated falling petals on one canvas
// ---------------------------------------------------------------------------

class FlowerPainter extends CustomPainter {
  final List<PetalInfo> petals;

  const FlowerPainter({required this.petals});

  static const double _petalLen = 52;
  static const double _petalW = 22;
  static const double _centerR = 26;
  static const double _petalDist = 32; // gap between center edge and petal
  static const Color _petalColor = Color(0xFFF48FB1); // pink[300]
  static const double _fadeStartThreshold = 0.55;
  static const double _fadeDurationFraction = 0.45;
  static const int _centerDotCount = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final center = Offset(cx, cy);

    _drawStem(canvas, center, size);
    _drawLeaf(canvas, center, size);
    _drawAttachedPetals(canvas, center);
    _drawFallingPetals(canvas, center, size);
    _drawCenter(canvas, center);
  }

  // ---- stem ----------------------------------------------------------------

  void _drawStem(Canvas canvas, Offset center, Size size) {
    canvas.drawLine(
      center + Offset(0, _centerR - 2),
      center + Offset(0, _centerR + size.height * 0.30),
      Paint()
        ..color = const Color(0xFF388E3C)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---- leaf ----------------------------------------------------------------

  void _drawLeaf(Canvas canvas, Offset center, Size size) {
    final base = center + Offset(0, _centerR + size.height * 0.14);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
          base.dx + 32, base.dy - 22, base.dx + 40, base.dy + 6)
      ..quadraticBezierTo(
          base.dx + 12, base.dy + 10, base.dx, base.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF66BB6A)
        ..style = PaintingStyle.fill,
    );
  }

  // ---- attached petals -----------------------------------------------------

  void _drawAttachedPetal(Canvas canvas, Offset center, double angle) {
    final petalPaint = Paint()
      ..color = _petalColor
      ..style = PaintingStyle.fill;
    final veinPaint = Paint()
      ..color = const Color(0xFFFCE4EC) // pink[50]
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCenter(
      center: Offset(0, -(_petalDist + _centerR + _petalLen / 2)),
      width: _petalW,
      height: _petalLen,
    );
    canvas.drawOval(rect, petalPaint);
    canvas.drawLine(
      Offset(0, -(_petalDist + _centerR)),
      Offset(0, -(_petalDist + _centerR + _petalLen)),
      veinPaint,
    );
    canvas.restore();
  }

  void _drawAttachedPetals(Canvas canvas, Offset center) {
    for (final p in petals) {
      if (p.state == PetalState.attached) {
        _drawAttachedPetal(canvas, center, p.angle);
      }
    }
  }

  // ---- falling petals ------------------------------------------------------

  void _drawFallingPetals(Canvas canvas, Offset center, Size size) {
    for (final p in petals) {
      if (p.state != PetalState.falling) continue;

      final t = p.animValue;
      // Start at petal's position on the flower
      final startX = center.dx +
          math.cos(p.angle) * (_petalDist + _centerR + _petalLen / 2);
      final startY = center.dy +
          math.sin(p.angle) * (_petalDist + _centerR + _petalLen / 2);

      // Gravity drop + slight lateral drift
      final px = startX + math.sin(p.angle) * 55 * t;
      final py = startY + size.height * 0.55 * t * t;

      final rotation = p.angle + 3.5 * math.pi * t;
      final opacity = t < _fadeStartThreshold
          ? 1.0
          : ((1.0 - t) / _fadeDurationFraction).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: _petalW, height: _petalLen),
        Paint()
          ..color = _petalColor.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  // ---- flower center -------------------------------------------------------

  void _drawCenter(Canvas canvas, Offset center) {
    // Yellow fill
    canvas.drawCircle(
      center,
      _centerR,
      Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.fill,
    );
    // Orange border
    canvas.drawCircle(
      center,
      _centerR,
      Paint()
        ..color = const Color(0xFFF57F17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // Small decorative dots
    final dotPaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < _centerDotCount; i++) {
      final a = 2 * math.pi * i / _centerDotCount;
      canvas.drawCircle(
        center + Offset(math.cos(a) * 14, math.sin(a) * 14),
        2.8,
        dotPaint,
      );
    }
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(FlowerPainter old) => true;
}
