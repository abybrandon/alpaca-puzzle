import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODEL KARTU ---
class CardModel {
  final int id;
  final String imagePath;
  bool isFaceUp;
  bool isMatched;

  CardModel({
    required this.id,
    required this.imagePath,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

// --- SCREEN UTAMA MEMORY PACA ---
class MemoryPacaScreen extends StatefulWidget {
  final int stage;

  const MemoryPacaScreen({super.key, required this.stage});

  @override
  State<MemoryPacaScreen> createState() => _MemoryPacaScreenState();
}

class _MemoryPacaScreenState extends State<MemoryPacaScreen> {
  final List<String> _allAssets = List.generate(
    20, 
    (index) => 'assets/images/paca${index + 1}.png'
  );

  late List<CardModel> _cards;
  int _moves = 0;
  int _matches = 0;
  bool _isProcessing = false;
  int? _firstCardIndex;
  
  Timer? _timer;
  int _timeLeft = 0;
  bool _isPeeking = false;
  bool _isTicking = false; 
  
  int _bestTimeRemaining = 0;

  // Player dibikin final agar stabil di memori
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer(); 
  bool _isSoundOn = true;

  @override
  void initState() {
    super.initState();
    _loadBestTime();
    _initSoundSettings();
    _initializeGame();
  }

  Future<void> _initSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    });

    if (_isSoundOn) {
      _playBackgroundMusic();
    }
  }

  @override
  void dispose() {
    // PROTEKSI: Matikan semua proses sebelum widget dihancurkan
    _timer?.cancel();
    _stopTickSound();
    _bgmPlayer.stop();
    _sfxPlayer.stop();
    
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
    _tickPlayer.dispose(); 
    super.dispose();
  }

  // --- AUDIO LOGIC ---
  void _playBackgroundMusic() async {
    if (!_isSoundOn) return; // PROTEKSI: Jangan mainkan jika setting OFF

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/bgm.mp3'), volume: 0.25);
    } catch (e) {
      debugPrint("BGM error: $e");
    }
  }

  void _playSound(String fileName) async {
    if (!_isSoundOn) return; // PROTEKSI: Jangan mainkan jika setting OFF

    try {
      await _sfxPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("SFX error: $fileName - $e");
    }
  }
 
  void _startTickSound() async {
    if (!_isSoundOn) return; // PROTEKSI: Jangan mainkan jika setting OFF
    if (_isTicking) return;

    try {
      _isTicking = true;
      await _tickPlayer.setReleaseMode(ReleaseMode.loop);
      await _tickPlayer.play(AssetSource('sounds/tick.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint("Tick sound error: $e");
    }
  }

  void _stopTickSound() async {
    try {
      _isTicking = false;
      await _tickPlayer.stop();
    } catch (e) {}
  }

  // --- DATA PERSISTENCE ---
  Future<void> _loadBestTime() async {
    if (widget.stage >= 3) { // Support stage 3 dan 4
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _bestTimeRemaining = prefs.getInt('memory_stage${widget.stage}_best') ?? 0;
      });
    }
  }

  Future<void> _saveBestTime(int currentTimeRemaining) async {
    if (widget.stage >= 3 && currentTimeRemaining > _bestTimeRemaining) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('memory_stage${widget.stage}_best', currentTimeRemaining);
      if (!mounted) return;
      setState(() {
        _bestTimeRemaining = currentTimeRemaining;
      });
    }
  }

  // --- GAME ENGINE ---
  void _initializeGame() {
    _timer?.cancel();
    _stopTickSound(); 
    
    int pairCount = 6; 
    if (widget.stage == 1) pairCount = 6; // 12 Kartu
    else if (widget.stage == 2) pairCount = 10; // 20 Kartu
    else if (widget.stage == 3) pairCount = 12; // 24 Kartu
    else if (widget.stage == 4) pairCount = 16; // 32 Kartu (Nambah 2 baris ke bawah)

    _timeLeft = (widget.stage == 1) ? 999 : 45; // Stage 4 tetap 45 detik

    _allAssets.shuffle(Random());
    List<String> selectedAssets = _allAssets.take(pairCount).toList();
    List<String> pairedImages = [...selectedAssets, ...selectedAssets];
    pairedImages.shuffle(Random()); 

    _cards = List.generate(
      pairedImages.length,
      (index) => CardModel(id: index, imagePath: pairedImages[index]),
    );

    _moves = 0;
    _matches = 0;
    _firstCardIndex = null;
    _isProcessing = false;
    _isTicking = false;

    if (widget.stage >= 2) {
      _isPeeking = true;
      _isProcessing = true; 
      for (var card in _cards) { card.isFaceUp = true; }
      if (mounted) setState(() {});

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() {
          for (var card in _cards) { card.isFaceUp = false; }
          _isPeeking = false;
          _isProcessing = false;
          _startTimer(); 
        });
      });
    } else {
      if (mounted) setState(() {});
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() { _timeLeft--; });
        if (_timeLeft == 15 && widget.stage > 1) _startTickSound();
      } else {
        timer.cancel();
        _isProcessing = true;
        _stopTickSound(); 
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showLoseDialog();
        });
      }
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing || _cards[index].isFaceUp || _cards[index].isMatched) return;

    _playSound('swap.mp3'); 

    setState(() { _cards[index].isFaceUp = true; });

    if (_firstCardIndex == null) {
      _firstCardIndex = index;
    } else {
      _isProcessing = true;
      _moves++;

      if (_cards[_firstCardIndex!].imagePath == _cards[index].imagePath) {
        _playSound('match.mp3');
        setState(() {
          _cards[_firstCardIndex!].isMatched = true;
          _cards[index].isMatched = true;
          _matches++;
        });
        _firstCardIndex = null;
        _isProcessing = false;
        
        if (_matches == (_cards.length / 2).floor()) {
          _timer?.cancel();
          _stopTickSound(); 
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _checkWin();
          });
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _cards[_firstCardIndex!].isFaceUp = false;
            _cards[index].isFaceUp = false;
            _firstCardIndex = null;
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _checkWin() async {
    bool isNewRecord = false;
    if (widget.stage >= 3 && _timeLeft > _bestTimeRemaining) {
      isNewRecord = true;
      await _saveBestTime(_timeLeft);
    }
    if (mounted) _showWinDialog(isNewRecord);
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/andes.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isPeeking) _buildPeekIndicator(),
                Expanded(child: _buildCardGrid()),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await _bgmPlayer.stop();
                    if(mounted) Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("STAGE ${widget.stage}", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      const Text("MEMORY PACA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                _buildTimerDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TIMER DISPLAY ---
  Widget _buildTimerDisplay() {
    bool isLow = _timeLeft <= 10 && widget.stage > 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? Colors.redAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isLow ? Colors.redAccent : Colors.cyanAccent, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: isLow ? Colors.redAccent : Colors.cyanAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            widget.stage == 1 ? "∞" : "$_timeLeft",
            style: TextStyle(color: isLow ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- CARD GRID ---
  Widget _buildCardGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Menentukan jumlah kolom dan baris berdasarkan stage
          int cols = widget.stage == 1 ? 3 : 4;
          int rows = (_cards.length / cols).ceil();

          // Menghitung spasi antar kartu (spacing)
          double spacing = 10.0;
          double totalCrossAxisSpacing = spacing * (cols - 1);
          double totalMainAxisSpacing = spacing * (rows - 1);

          // Menghitung rasio yang pas agar kartu mengisi penuh layar tapi tidak luber
          double cardWidth = (constraints.maxWidth - totalCrossAxisSpacing) / cols;
          double cardHeight = (constraints.maxHeight - totalMainAxisSpacing) / rows;
          double dynamicAspectRatio = cardWidth / cardHeight;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // MATIKAN SCROLL
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: dynamicAspectRatio, // Pakai rasio dinamis
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) => _ModernFlipCard(
              card: _cards[index],
              onTap: () => _onCardTap(index),
            ),
          );
        }
      ),
    );
  }

  // --- FOOTER ---
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 5, left: 20, right: 20), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("GERAKAN", "$_moves"),
          if (widget.stage >= 3) _buildStat("TERBAIK", "$_bestTimeRemaining s"), // Nampil di Stage 3 & 4
        ],
      ),
    );
  }

  // --- PEEK INDICATOR ---
  Widget _buildPeekIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
      child: const Text("INGAT POSISINYA!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: Colors.black)),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- DIALOGS (WIN/LOSE) ---
  void _showWinDialog(bool isNewRecord) {
    _playSound('win.mp3');
    _showGameDialog(
      title: "STAGE ${widget.stage} SELESAI!",
      icon: Icons.auto_awesome,
      color: Colors.cyanAccent,
      isWin: true,
      isNewRecord: isNewRecord,
    );
  }

  void _showLoseDialog() {
    _playSound('lose.mp3');
    _showGameDialog(
      title: "WAKTU HABIS!",
      icon: Icons.timer_off_outlined,
      color: Colors.redAccent,
      isWin: false,
    );
  }

  void _showGameDialog({required String title, required IconData icon, required Color color, required bool isWin, bool isNewRecord = false}) {
    if (!mounted) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              content: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 80),
                    const SizedBox(height: 16),
                    Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (isWin) Text("Langkah: $_moves | Sisa Waktu: $_timeLeft s", style: const TextStyle(color: Colors.white70)),
                    if (isNewRecord) 
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                        child: const Text("REKOR BARU!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        if (!mounted) return;
                        // Stop suara dulu sebelum navigasi
                        await _bgmPlayer.stop();
                        await _sfxPlayer.stop();
                        
                        if (!mounted) return;
                        Navigator.pop(context); // Tutup Dialog

                        if (!isWin) {
                          _initializeGame();
                        } else if (widget.stage < 4) { // Disesuaikan sampai Stage 4
                          // Gunakan microtask agar transisi bersih
                          Future.microtask(() {
                            if (mounted) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MemoryPacaScreen(stage: widget.stage + 1)));
                            }
                          });
                        } else {
                          Navigator.pop(context); // Finish di Stage 4
                        }
                      },
                      // Teks tombol juga menyesuaikan batas akhir adalah Stage 4
                      child: Text(isWin ? (widget.stage < 4 ? "LANJUT STAGE" : "SELESAI") : "COBA LAGI", style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- MODERN FLIP CARD WIDGET ---
class _ModernFlipCard extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;

  const _ModernFlipCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: card.isFaceUp ? 180 : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, double value, child) {
          final isBack = value < 90;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(value * pi / 180),
            child: isBack 
              ? _buildCardBack() 
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildCardFront(),
                ),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.1,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _GridPainter(),
            ),
          ),
          const Icon(Icons.help_outline_rounded, color: Colors.cyanAccent, size: 30),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isMatched ? Colors.cyanAccent : const Color(0xffcb9361), 
          width: 3
        ),
        boxShadow: [
          if (card.isMatched) 
            const BoxShadow(color: Colors.cyanAccent, blurRadius: 15, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Opacity(
        opacity: card.isMatched ? 0.6 : 1.0,
        child: Image.asset(card.imagePath, fit: BoxFit.contain),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyanAccent..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 10) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}