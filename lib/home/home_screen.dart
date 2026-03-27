import 'package:alpacapuzzle/game/match3/match3_screen.dart';
import 'package:alpacapuzzle/game/memory%20paca/memory_paca_screen.dart';
import 'package:alpacapuzzle/game/puzzle_paca/puzzle_paca_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:alpacapuzzle/memory_paca/memory_paca_screen.dart'; // Sesuaikan path-nya nanti

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = "Player";
  bool _isSoundOn = true;
  
  // PENAMBAHAN BGM: Player khusus untuk Home/Lobby
  final AudioPlayer _bgmHomePlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Player";
      _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    });

    if (_isSoundOn) {
      _playHomeBGM();
    }
  }

  void _playHomeBGM() async {
    try {
      await _bgmHomePlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmHomePlayer.play(AssetSource('sounds/bgm_selector.mp3'), volume: 0.3); // Pastikan nama file cocok
    } catch (e) {
      debugPrint("Error Home BGM: $e");
    }
  }

  void _stopHomeBGM() async {
    await _bgmHomePlayer.stop();
  }

  @override
  void dispose() {
    _bgmHomePlayer.stop();
    _bgmHomePlayer.dispose();
    super.dispose();
  }

  // --- DIALOG SETTINGS ---
  void _showSettingsDialog() {
    TextEditingController editNameCtrl = TextEditingController(text: _username);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Settings",
      barrierColor: Colors.black87.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: StatefulBuilder( // Butuh StatefulBuilder agar Toggle Switch di dialog bisa update UI
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("PENGATURAN", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 25),
                          
                          // Ubah Nama
                          const Align(alignment: Alignment.centerLeft, child: Text("Ubah Nama:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: editNameCtrl,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black45,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Toggle Sound
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Suara Latar (BGM):", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              Switch(
                                activeColor: Colors.amber,
                                value: _isSoundOn,
                                onChanged: (val) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('isSoundOn', val);
                                  
                                  // Update state dialog
                                  setStateDialog(() {
                                    _isSoundOn = val;
                                  });
                                  // Update state screen
                                  setState(() {
                                    _isSoundOn = val;
                                  });

                                  if (val) {
                                    _playHomeBGM();
                                  } else {
                                    _stopHomeBGM();
                                  }
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Save Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              String newName = editNameCtrl.text.trim().isEmpty ? "Player" : editNameCtrl.text.trim();
                              await prefs.setString('username', newName);
                              setState(() {
                                _username = newName;
                              });
                              if(mounted) Navigator.pop(context);
                            },
                            child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/andes.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: const Color(0xFF0F172A).withOpacity(0.7))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 240, filterQuality: FilterQuality.high),
                      const SizedBox(height: 20),
                      const Text('STORY MODE - LEVEL', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 4)),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () async {
                           // Stop BGM Lobby sebelum pindah ke Level Selector
                           await _bgmHomePlayer.stop();
                           if(!mounted) return;
                           
                           await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelSelectorScreen()));
                           
                           // Putar lagi saat balik dari Level Selector
                           if(mounted && _isSoundOn) _playHomeBGM();
                        },
                        child: _buildMainPlayButton(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DAILY & ARCADE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniGameCardWidget(
                              title: "MEMORY PACA",
                              imagePath: 'assets/memory_logo.png',
                              color: Colors.amber,
                              onTap: () async {
                                await _bgmHomePlayer.stop();
                                if(!mounted) return;
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => const MemoryPacaScreen(stage: 1)));
                                if(mounted && _isSoundOn) _playHomeBGM();
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _MiniGameCardWidget(
                              title: "PUZZLE PACA",
                              imagePath: 'assets/puzzle_paca_logo.png',
                              color: Colors.cyanAccent,
                              onTap: () async {
                                await _bgmHomePlayer.stop();
                                if(!mounted) return;
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => const PuzzlePacaScreen(stage: 1)));
                                if(mounted && _isSoundOn) _playHomeBGM();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // --- MENAMPILKAN USERNAME DI KIRI ATAS ---
              _buildGlassChip(Icons.person_rounded, _username.toUpperCase(), Colors.amber),
            ],
          ),
          GestureDetector(
            onTap: _showSettingsDialog, // Panggil Setting
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(IconData icon, String value, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPlayButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pinkAccent.withOpacity(0.6), Colors.purpleAccent.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              SizedBox(width: 10),
              Text("PLAY", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET KARTU MINI GAME (ARCADE STYLE) ---
class _MiniGameCardWidget extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  const _MiniGameCardWidget({super.key, required this.title, required this.imagePath, required this.color, required this.onTap});

  @override
  State<_MiniGameCardWidget> createState() => _MiniGameCardWidgetState();
}

class _MiniGameCardWidgetState extends State<_MiniGameCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap(); 
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 140, 
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [widget.color.withOpacity(0.3), Colors.black.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 15, spreadRadius: 1)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(widget.imagePath, fit: BoxFit.contain)))),
                        const SizedBox(height: 10),
                        Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2, height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}