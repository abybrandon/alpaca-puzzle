import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; // Import package suara

// --- HALAMAN PILIH STAGE ---
class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({super.key});

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  int _unlockedStage = 1;
  bool _isLoading = true;

  // PENAMBAHAN BGM: Player khusus untuk menu
  final AudioPlayer _bgmPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadProgress();

    // PENAMBAHAN BGM: Mulai putar musik saat masuk menu
    _playMenuBGM();

    // Memanggil popup tutorial tepat setelah layar pertama kali di-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  // PENAMBAHAN BGM: Fungsi putar musik menu
  // PENAMBAHAN BGM: Fungsi putar musik menu HANYA JIKA SOUND ON
  void _playMenuBGM() async {
    final prefs = await SharedPreferences.getInstance();
    bool isSoundOn = prefs.getBool('isSoundOn') ?? true; // Ambil settingan dari Home

    if (isSoundOn) {
      try {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(AssetSource('sounds/bgm_selector.mp3'), volume: 0.4);
      } catch (e) {
        debugPrint("Error BGM Menu: $e");
      }
    }
  }

  @override
  void dispose() {
    // PENAMBAHAN BGM: Matikan musik saat widget hancur
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedStage = prefs.getInt('unlocked_stage') ?? 1;
      _isLoading = false;
    });
  }

  // Animasi Pop-up Tutorial bergaya game
  void _showTutorialDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Harus ditutup lewat tombol X
      barrierColor: Colors.black87.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );

        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            elevation: 0,
            content: Stack(
              clipBehavior: Clip.none,
              children: [
                // Container Gambar Tutorial
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/tutorial_match3.png', // Pastikan nama file sesuai
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Tombol Silang (Close) bergaya Arcade di Kanan Atas
                Positioned(
                  top: -15,
                  right: -15,
                  child: GestureDetector(
                    onTap: () {
                      // Putar suara tombol jika ada (opsional)
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Animasi pindah halaman yang lebih "nge-game" (Fade & Scale)
  Route _createGameRoute(int stage) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          Match3Screen(stage: stage), // Pastikan Match3Screen sudah ter-import
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack));
        var scaleAnimation = animation.drive(tween);
        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/andes_alpaca.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF0F172A).withOpacity(0.75)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tombol Back mentok di kiri
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white54,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Teks absolut di tengah
                    const Text(
                      "STORY MODE",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Pilih Tahapanmu",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _LevelCardWidget(
                        title: "STAGE 1",
                        subtitle: "Santai (Tanpa Batas Langkah)",
                        stage: 1,
                        color: Colors.greenAccent,
                        icon: Icons.park_rounded,
                        isLocked: 1 > _unlockedStage,
                        onTap: () async {
                          // PENAMBAHAN BGM: Stop musik sebelum pindah screen
                          await _bgmPlayer.stop();
                          await Navigator.of(context).push(_createGameRoute(1));
                          _loadProgress();
                          // PENAMBAHAN BGM: Putar lagi saat balik ke menu
                          if(mounted) _playMenuBGM();
                        },
                      ),
                      _LevelCardWidget(
                        title: "STAGE 2",
                        subtitle: "Taktik (Batas Langkah)",
                        stage: 2,
                        color: Colors.orangeAccent,
                        icon: Icons.extension_rounded,
                        isLocked: 2 > _unlockedStage,
                        onTap: () async {
                          // PENAMBAHAN BGM: Stop musik sebelum pindah screen
                          await _bgmPlayer.stop();
                          await Navigator.of(context).push(_createGameRoute(2));
                          _loadProgress();
                          // PENAMBAHAN BGM: Putar lagi saat balik ke menu
                          if(mounted) _playMenuBGM();
                        },
                      ),
                      _LevelCardWidget(
                        title: "STAGE 3",
                        subtitle: "Panik (Langkah + Waktu)",
                        stage: 3,
                        color: Colors.redAccent,
                        icon: Icons.timer_rounded,
                        isLocked: 3 > _unlockedStage,
                        onTap: () async {
                          // PENAMBAHAN BGM: Stop musik sebelum pindah screen
                          await _bgmPlayer.stop();
                          await Navigator.of(context).push(_createGameRoute(3));
                          _loadProgress();
                          // PENAMBAHAN BGM: Putar lagi saat balik ke menu
                          if(mounted) _playMenuBGM();
                        },
                      ),
                      // PENAMBAHAN STAGE 4
                      _LevelCardWidget(
                        title: "STAGE 4",
                        subtitle: "Extreme (Langkah + Waktu)",
                        stage: 4,
                        color: Colors.purpleAccent,
                        icon: Icons.flash_on_rounded,
                        isLocked: 4 > _unlockedStage,
                        onTap: () async {
                          await _bgmPlayer.stop();
                          await Navigator.of(context).push(_createGameRoute(4));
                          _loadProgress();
                          if(mounted) _playMenuBGM();
                        },
                      ),
                      const SizedBox(height: 30),
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
}

// Widget terpisah untuk Kartu Stage agar bisa diberi animasi "Bouncy" saat disentuh
class _LevelCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int stage;
  final Color color;
  final IconData icon;
  final bool isLocked;
  final VoidCallback onTap;

  const _LevelCardWidget({
    required this.title,
    required this.subtitle,
    required this.stage,
    required this.color,
    required this.icon,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<_LevelCardWidget> createState() => _LevelCardWidgetState();
}

class _LevelCardWidgetState extends State<_LevelCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTapDown: widget.isLocked ? null : (_) => _controller.forward(),
        onTapUp: widget.isLocked
            ? null
            : (_) {
                _controller.reverse();
                widget
                    .onTap(); // Panggil fungsi transisi setelah animasi tombol
              },
        onTapCancel: widget.isLocked ? null : () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.isLocked ? 0.6 : 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.isLocked
                          ? Colors.black.withOpacity(0.4)
                          : widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: widget.isLocked
                            ? Colors.white24
                            : widget.color.withOpacity(0.5),
                        width: widget.isLocked ? 1 : 2,
                      ),
                      boxShadow: widget.isLocked
                          ? []
                          : [
                              BoxShadow(
                                color: widget.color.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: widget.isLocked
                                ? Colors.white10
                                : widget.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isLocked ? Icons.lock_rounded : widget.icon,
                            color: widget.isLocked
                                ? Colors.white54
                                : widget.color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: widget.isLocked
                                      ? Colors.white54
                                      : Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.isLocked
                                    ? "Terkunci. Selesaikan stage sebelumnya."
                                    : widget.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isLocked
                                      ? Colors.white30
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isLocked)
                          Icon(
                            Icons.play_arrow_rounded,
                            color: widget.color.withOpacity(0.7),
                            size: 30,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DATA MODEL UNTUK TILE (KOTAK) ---
class TileItem {
  int type;
  bool isMatched;

  TileItem({required this.type, this.isMatched = false});
}

// --- GAME LAYAR UTAMA ---
class Match3Screen extends StatefulWidget {
  final int stage;

  const Match3Screen({super.key, required this.stage});

  @override
  State<Match3Screen> createState() => _Match3ScreenState();
}

class _Match3ScreenState extends State<Match3Screen> {
  final int rows = 8;
  final int cols = 6;
  final int numTypes = 5;
  
  // Modifikasi: targetScore tidak lagi final agar bisa berubah sesuai stage
  int targetScore = 500;

  late List<List<TileItem>> _grid;
  int _score = 0;
  int _moves = 15;
  int _timeLeft = 60;

  // Variabel untuk melacak jumlah combo berturut-turut
  int _comboCount = 0;

  bool _isAnimating = false;
  bool _isGameOver = false;
  bool _isWrongMove = false;

  Timer? _timer;
  Offset? _dragStartPosition;

  // PENAMBAHAN BGM: Player khusus untuk musik gameplay
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // Audio Player Instance (Untuk SFX)
  final AudioPlayer _audioPlayer = AudioPlayer();

  // MENGGUNAKAN GAMBAR ALPACAS SEBAGAI TILE
  final List<AssetImage> _tileAssets = const [
    AssetImage('assets/images/alpaca_happy.png'), // Type 0 (Pink)
    AssetImage('assets/images/alpaca_sad.png'), // Type 1 (Blue)
    AssetImage('assets/images/alpaca_angry.png'), // Type 2 (Orange)
    AssetImage('assets/images/alpaca_star.png'), // Type 3 (Amber)
    AssetImage('assets/images/alpaca_wink.png'), // Type 4 (Cyan)
  ];

  final List<Color> _tileColors = [
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.cyanAccent,
  ];

  @override
  void initState() {
    super.initState();
    _setupStageRules();
    _initializeBoard();
    
   _initSoundSettings();
  }
bool _isSoundOn = true;
  Future<void> _initSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    });

    if (_isSoundOn) {
      _playGameBGM();
    }
  }

  // PENAMBAHAN BGM: Fungsi khusus untuk BGM
  void _playGameBGM() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/bgm_match3.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint("Error BGM Game: $e");
    }
  }

  // Helper untuk memutar suara dengan aman (tidak crash jika file tidak ada)
void _playSound(String fileName) async {
    if (!_isSoundOn) return; // JIKA SETTING OFF, LANGSUNG BATALKAN SUARA

    try {
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("Suara $fileName belum ditambahkan atau error: $e");
    }
  }

  void _setupStageRules() {
    if (widget.stage == 1) {
      _moves = 999;
      targetScore = 500;
    } else if (widget.stage == 2) {
      _moves = 15;
      targetScore = 500;
    } else if (widget.stage == 3) {
      _moves = 15;
      _timeLeft = 45;
      targetScore = 500;
      _startTimer();
    } else if (widget.stage == 4) {
      // PENAMBAHAN STAGE 4
      _moves = 20;
      _timeLeft = 45;
      targetScore = 750;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _checkWinCondition();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // PENAMBAHAN BGM: Bersihkan memory audio
    _bgmPlayer.stop();
    _bgmPlayer.dispose();
    _audioPlayer.dispose(); // Wajib buang audio player dari memory
    super.dispose();
  }

  void _initializeBoard() {
    final random = Random();
    _grid = List.generate(
      rows,
      (r) =>
          List.generate(cols, (c) => TileItem(type: random.nextInt(numTypes))),
    );
    _removeInitialMatches();
  }

  void _removeInitialMatches() {
    bool hasMatch = true;
    final random = Random();
    while (hasMatch) {
      hasMatch = _markMatches();
      if (hasMatch) {
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (_grid[r][c].isMatched) {
              _grid[r][c].type = random.nextInt(numTypes);
              _grid[r][c].isMatched = false;
            }
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _performSwap(int r1, int c1, int r2, int c2) async {
    // Putar suara swap saat pemain menggeser
    _playSound('swap.mp3');

    setState(() {
      _isAnimating = true;
      int temp = _grid[r1][c1].type;
      _grid[r1][c1].type = _grid[r2][c2].type;
      _grid[r2][c2].type = temp;

      if (widget.stage >= 2) {
        _moves--;
      }
    });

    await Future.delayed(const Duration(milliseconds: 300));

    bool hasMatch = _markMatches();

    if (!hasMatch) {
      // Putar suara error jika geseran salah
      _playSound('error.mp3');

      setState(() {
        _isWrongMove = true;
        int temp = _grid[r1][c1].type;
        _grid[r1][c1].type = _grid[r2][c2].type;
        _grid[r2][c2].type = temp;

        if (widget.stage >= 2) {
          _moves++;
        }
      });
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _isAnimating = false;
        _isWrongMove = false;
      });
    } else {
      // Reset combo setiap kali pemain melakukan swap manual yang berhasil
      _comboCount = 0;
      _processMatches();
    }
  }

  bool _markMatches() {
    bool found = false;
    for (var row in _grid) {
      for (var tile in row) {
        tile.isMatched = false;
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        int type = _grid[r][c].type;
        if (type != -1 &&
            type == _grid[r][c + 1].type &&
            type == _grid[r][c + 2].type) {
          _grid[r][c].isMatched = true;
          _grid[r][c + 1].isMatched = true;
          _grid[r][c + 2].isMatched = true;
          found = true;
        }
      }
    }

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        int type = _grid[r][c].type;
        if (type != -1 &&
            type == _grid[r + 1][c].type &&
            type == _grid[r + 2][c].type) {
          _grid[r][c].isMatched = true;
          _grid[r + 1][c].isMatched = true;
          _grid[r + 2][c].isMatched = true;
          found = true;
        }
      }
    }
    return found;
  }

  Future<void> _processMatches() async {
    int matchCount = 0;

    setState(() {});

    // Hitung berapa tile yang match
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_grid[r][c].isMatched) {
          matchCount++;
        }
      }
    }

    // Putar suara sesuai status combo
    if (matchCount > 0) {
      _comboCount++; // Tambah hitungan combo setiap kali ada match otomatis
      if (_comboCount > 1) {
        _playSound('combo.mp3'); // Putar suara khusus jika combo lebih dari 1
      } else {
        _playSound('match.mp3'); // Putar suara biasa untuk match pertama
      }
    }

    await Future.delayed(const Duration(milliseconds: 350));

    setState(() {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (_grid[r][c].isMatched) {
            _grid[r][c].type = -1;
          }
        }
      }
      // Tambahkan multiplier combo ke skor biar makin rewarding!
      _score += (matchCount * 10) * _comboCount;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      for (int c = 0; c < cols; c++) {
        for (int r = rows - 1; r >= 0; r--) {
          if (_grid[r][c].type == -1) {
            for (int k = r - 1; k >= 0; k--) {
              if (_grid[k][c].type != -1) {
                _grid[r][c].type = _grid[k][c].type;
                _grid[k][c].type = -1;
                break;
              }
            }
          }
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    setState(() {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (_grid[r][c].type == -1) {
            _grid[r][c].type = random.nextInt(numTypes);
            _grid[r][c].isMatched = false;
          }
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Kalau setelah blok baru turun ternyata ada match lagi, panggil fungsinya lagi (looping combo)
    if (_markMatches()) {
      _processMatches();
    } else {
      setState(() {
        _isAnimating = false;
        // Kita tidak mereset _comboCount di sini agar animasi/suara terakhir tetap selesai dengan benar.
        // Combo count akan di-reset saat pemain melakukan _performSwap berikutnya.
      });
      _checkWinCondition();
    }
  }

  Future<void> _unlockNextStage() async {
    final prefs = await SharedPreferences.getInstance();
    int currentUnlocked = prefs.getInt('unlocked_stage') ?? 1;

    if (widget.stage >= currentUnlocked) {
      await prefs.setInt('unlocked_stage', widget.stage + 1);
    }
  }

  void _checkWinCondition() async {
    if (_isGameOver) return;

    if (_score >= targetScore) {
      _isGameOver = true;
      _timer?.cancel();
      
      // PENAMBAHAN BGM: Hentikan BGM gameplay saat menang
      await _bgmPlayer.stop();

      await _unlockNextStage();

      // Suara Menang!
      _playSound('win.mp3');
      _showAnimatedDialog(
        "LEVEL CLEARED!",
        "Stage ${widget.stage} Berhasil! Stage baru telah terbuka.",
        true,
      );
    } else {
      // Modifikasi: Karena Stage 3 & 4 pakai waktu, kita satukan logikanya
      if ((widget.stage >= 3) && _timeLeft <= 0) {
        _isGameOver = true;
        _timer?.cancel();
        
        // PENAMBAHAN BGM: Hentikan BGM gameplay saat kalah
        await _bgmPlayer.stop();

        // Suara Kalah
        _playSound('lose.mp3');
        _showAnimatedDialog(
          "TIME'S UP!",
          "Waktu habis! Paca gagal ngumpulin item.",
          false,
        );
      } else if (widget.stage >= 2 && _moves <= 0) {
        _isGameOver = true;
        _timer?.cancel();
        
        // PENAMBAHAN BGM: Hentikan BGM gameplay saat kalah
        await _bgmPlayer.stop();

        // Suara Kalah
        _playSound('lose.mp3');
        _showAnimatedDialog(
          "OUT OF MOVES!",
          "Langkahmu habis! Coba lagi ya.",
          false,
        );
      }
    }
  }

  void _showAnimatedDialog(String title, String subtitle, bool isWin) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );

        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWin
                      ? [Colors.amber.shade800, Colors.amber.shade400]
                      : [Colors.red.shade900, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: isWin
                        ? Colors.amber.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWin
                        ? Icons.emoji_events_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isWin
                          ? Colors.amber.shade900
                          : Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "CONTINUE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Positioned.fill(
            child: Image.asset('assets/andes_alpaca.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF0F172A).withOpacity(0.85)),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                           // PENAMBAHAN BGM: Matikan lagu game kalau di-back secara manual
                           await _bgmPlayer.stop();
                           if(mounted) Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "STAGE ${widget.stage}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "$_score / $targetScore",
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: widget.stage == 1
                                    ? Colors.green
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.multiple_stop_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.stage == 1 ? "∞" : "$_moves",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Modifikasi: Tampilkan timer untuk stage 3 dan 4
                          if (widget.stage >= 3) const SizedBox(height: 8),
                          if (widget.stage >= 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _timeLeft <= 10
                                    ? Colors.redAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _timeLeft <= 10
                                      ? Colors.redAccent
                                      : Colors.white24,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_rounded,
                                    color: _timeLeft <= 10
                                        ? Colors.redAccent
                                        : Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$_timeLeft s",
                                    style: TextStyle(
                                      color: _timeLeft <= 10
                                          ? Colors.redAccent
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isWrongMove
                          ? Colors.redAccent
                          : Colors.white.withOpacity(0.2),
                      width: _isWrongMove ? 3.0 : 1.0,
                    ),
                    boxShadow: _isWrongMove
                        ? [
                            const BoxShadow(
                              color: Colors.redAccent,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(rows, (r) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(cols, (c) {
                              TileItem item = _grid[r][c];

                              return GestureDetector(
                                onPanStart: (details) {
                                  if (_isAnimating || _isGameOver) return;
                                  _dragStartPosition = details.globalPosition;
                                },
                                onPanUpdate: (details) {
                                  if (_isAnimating ||
                                      _isGameOver ||
                                      _dragStartPosition == null)
                                    return;

                                  final dx =
                                      details.globalPosition.dx -
                                      _dragStartPosition!.dx;
                                  final dy =
                                      details.globalPosition.dy -
                                      _dragStartPosition!.dy;
                                  const swipeThreshold = 30.0;

                                  if (dx.abs() > swipeThreshold ||
                                      dy.abs() > swipeThreshold) {
                                    if (dx.abs() > dy.abs()) {
                                      if (dx > 0 && c < cols - 1) {
                                        _performSwap(r, c, r, c + 1);
                                      } else if (dx < 0 && c > 0) {
                                        _performSwap(r, c, r, c - 1);
                                      }
                                    } else {
                                      if (dy > 0 && r < rows - 1) {
                                        _performSwap(r, c, r + 1, c);
                                      } else if (dy < 0 && r > 0) {
                                        _performSwap(r, c, r - 1, c);
                                      }
                                    }
                                    _dragStartPosition = null;
                                  }
                                },
                                onPanEnd: (_) => _dragStartPosition = null,
                                onPanCancel: () => _dragStartPosition = null,

                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width:
                                      MediaQuery.of(context).size.width / cols -
                                      12,
                                  height:
                                      MediaQuery.of(context).size.width / cols -
                                      12,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: item.type == -1
                                        ? Colors.transparent
                                        : item.isMatched
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: item.isMatched
                                          ? Colors.white
                                          : Colors.white10,
                                      width: item.isMatched ? 3 : 1,
                                    ),
                                    boxShadow:
                                        item.type != -1 && !item.isMatched
                                        ? [
                                            BoxShadow(
                                              color: _tileColors[item.type]
                                                  .withOpacity(0.2),
                                              blurRadius: 5,
                                            ),
                                          ]
                                        : (item.isMatched
                                              ? [
                                                  const BoxShadow(
                                                    color: Colors.white,
                                                    blurRadius: 15,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : []),
                                  ),

                                  child: Center(
                                    child: AnimatedScale(
                                      scale: item.type == -1
                                          ? 0.0
                                          : (item.isMatched ? 1.9 : 1.1),
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: item.isMatched
                                          ? Curves.elasticOut
                                          : Curves.easeIn,
                                      child: item.type == -1
                                          ? const SizedBox()
                                          : Image(
                                              image: _tileAssets[item.type],
                                              width:
                                                  36, // Ukuran disesuaikan agar pas di dalam kotak
                                              height: 36,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Modifikasi: Teks khusus untuk stage 3 dan 4
                Text(
                  widget.stage >= 3 ? "HURRY UP!" : "SWIPE TO MATCH 3!",
                  style: TextStyle(
                    color: widget.stage >= 3 && _timeLeft <= 10
                        ? Colors.redAccent
                        : Colors.white30,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}