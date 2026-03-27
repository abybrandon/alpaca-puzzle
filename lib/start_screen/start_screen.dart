import 'package:alpacapuzzle/game/match3/match3_screen.dart'; // Sesuaikan import kamu
import 'package:alpacapuzzle/game/memory%20paca/memory_paca_screen.dart';
import 'package:alpacapuzzle/game/puzzle_paca/puzzle_paca_screen.dart';
import 'package:alpacapuzzle/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// 1. START SCREEN (FORM USERNAME)
// ============================================================================

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  bool _isButtonPressed = false;
  bool _showForm = false; // Flag untuk menampilkan form username
  final TextEditingController _nameController = TextEditingController();

  // PENAMBAHAN BGM: Player khusus untuk Start Screen
  final AudioPlayer _bgmPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playStartBGM();
    _checkExistingUser();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  void _playStartBGM() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSoundOn = prefs.getBool('isSoundOn') ?? true;
    
    if (isSoundOn) {
      try {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(AssetSource('sounds/bgm_start.mp3'), volume: 0.4); // Ganti dengan file BGM yang kamu punya
      } catch (e) {
        debugPrint("Error BGM Start: $e");
      }
    }
  }

  // Jika sudah ada nama, bisa skip form atau tetap tampilkan dengan nama lama
  void _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? existingName = prefs.getString('username');
    if (existingName != null && existingName.isNotEmpty) {
      _nameController.text = existingName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveNameAndStart() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) name = "Player"; // Default name jika kosong

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);

    await _bgmPlayer.stop(); // Stop musik sblm pindah

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildCurvedTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: title.split('').asMap().entries.map((entry) {
        int idx = entry.key;
        String letter = entry.value;

        double middle = (title.length - 1) / 2;
        double x = idx - middle;
        double y = 2.0 * (x * x); 
        double angle = x * 0.08; 

        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.rotate(
            angle: angle,
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                  Shadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Biar background gak terdorong keyboard
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/andes.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildCurvedTitle("PACAPUZZLE"),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Text(
                      'P E T U A L A N G A N   W O L',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(offset: Offset(0, _bounceAnimation.value), child: child);
                    },
                    child: Image.asset('assets/logo.png', height: 350, filterQuality: FilterQuality.high),
                  ),
                  const Spacer(),

                  // --- LOGIKA FORM VS TOMBOL START ---
                  if (!_showForm)
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) {
                        setState(() {
                          _isButtonPressed = false;
                          _showForm = true; // Munculin Form
                        });
                      },
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      child: AnimatedScale(
                        scale: _isButtonPressed ? 0.95 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('TAP TO START', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 3)),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // FORM INPUT USERNAME
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30, width: 1.5),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Siapa namamu, Petualang?", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                                  decoration: InputDecoration(
                                    hintText: "NAMA",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  onPressed: _saveNameAndStart,
                                  child: const Text("MASUK LOBBY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
