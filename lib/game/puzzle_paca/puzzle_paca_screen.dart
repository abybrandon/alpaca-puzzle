import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PuzzlePacaScreen extends StatefulWidget {
  final int stage;

  const PuzzlePacaScreen({super.key, required this.stage});

  @override
  State<PuzzlePacaScreen> createState() => _PuzzlePacaScreenState();
}

class _PuzzlePacaScreenState extends State<PuzzlePacaScreen> {
  final int _gridSize = 3;
  late List<int?> _board;

  late String _selectedImage;
  int _moves = 0;
  int _moveLimit = 0;
  int _timeLeft = 0;
  int _emptyCount = 1;

  Timer? _timer;
  bool _gameStarted = false;

  // Player dibikin final agar tidak berubah-ubah
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _isSoundOn = true;

  @override
  void initState() {
    super.initState();
    _setupStage();
    _initializeBoard();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initSoundSettings(); // Ganti pemanggilan _playBGM() ke pengecekan ini
        _showTargetPreview();
      }
    });
  }

  Future<void> _initSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    });

    if (_isSoundOn) {
      _playBGM();
    }
  }

  @override
  void dispose() {
    // PENTING: Matikan semua sebelum widget dihancurkan
    _timer?.cancel();
    _bgmPlayer.stop();
    _sfxPlayer.stop();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

void _setupStage() {
    _emptyCount = 1; // WAJIB 1 KOTAK KOSONG BIAR GAK BUG & NYANGKUT!

    if (widget.stage == 1) {
      _selectedImage = 'assets/images/alpaca_stage1.png';
      _timeLeft = 999; 
      _moveLimit = 999; // Santai
    } else if (widget.stage == 2) {
      _selectedImage = 'assets/images/alpaca_stage2.png';
      _timeLeft = 999; 
      _moveLimit = 50; // Taktik (Batas Gerakan)
    } else {
      _selectedImage = 'assets/images/alpaca_stage3.png';
      _timeLeft = 60; // 1 Menit
      _moveLimit = 40; // Panik (Waktu + Gerakan)
    }
  }

  void _playBGM() async {
    if (!_isSoundOn) return; // PROTEKSI: Jangan mainkan jika setting OFF

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/bgm_puzzle.mp3'), volume: 0.2);
    } catch (e) {
      debugPrint("BGM Error: $e");
    }
  }

  void _initializeBoard() {
    int totalSlots = _gridSize * _gridSize;
    _board = List.generate(totalSlots, (index) {
      if (index < totalSlots - _emptyCount) return index;
      return null;
    });

    _shuffleBoard();
    _moves = 0;
  }

  void _shuffleBoard() {
    Random r = Random();
    for (int i = 0; i < 150; i++) {
      List<int> movableIndices = [];
      for (int j = 0; j < _board.length; j++) {
        if (_board[j] != null && _canMove(j)) movableIndices.add(j);
      }
      if (movableIndices.isNotEmpty) {
        _performMove(
          movableIndices[r.nextInt(movableIndices.length)],
          silent: true,
        );
      }
    }
  }

  void _cheatWin() {
    _timer?.cancel();
    int totalSlots = _gridSize * _gridSize;
    setState(() {
      _board = List.generate(totalSlots, (index) {
        if (index < totalSlots - _emptyCount) return index;
        return null;
      });
    });
    _showWinDialog();
  }

void _startTimer() {
    _timer?.cancel(); 
    if (widget.stage < 3) return; // Stage 1 & 2 santai, gak usah pakai timer!

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        _showLoseDialog("WAKTU HABIS!");
      }
    });
  }

  bool _canMove(int index) {
    int row = index ~/ _gridSize;
    int col = index % _gridSize;
    for (int i = 0; i < _board.length; i++) {
      if (_board[i] == null) {
        int eRow = i ~/ _gridSize;
        int eCol = i % _gridSize;
        if ((row == eRow && (col - eCol).abs() == 1) ||
            (col == eCol && (row - eRow).abs() == 1)) {
          return true;
        }
      }
    }
    return false;
  }

void _performMove(int index, {bool silent = false}) {
    if (!_canMove(index)) return;

    int row = index ~/ _gridSize;
    int col = index % _gridSize;
    int targetEmptyIndex = -1;

    for (int i = 0; i < _board.length; i++) {
      if (_board[i] == null) {
        int eRow = i ~/ _gridSize;
        int eCol = i % _gridSize;
        if ((row == eRow && (col - eCol).abs() == 1) ||
            (col == eCol && (row - eRow).abs() == 1)) {
          targetEmptyIndex = i;
          break;
        }
      }
    }

    if (targetEmptyIndex != -1) {
      if (silent) {
        _board[targetEmptyIndex] = _board[index];
        _board[index] = null;
      } else {
        setState(() {
          _board[targetEmptyIndex] = _board[index];
          _board[index] = null;
          
          _moves++;
          if (_isSoundOn) {
            _sfxPlayer.play(AssetSource('sounds/slide.mp3'));
          }
          
          // Modifikasi: Stage 2 dan 3 akan kalah kalau langkah habis
          if (widget.stage >= 2 && _moves >= _moveLimit) {
            _timer?.cancel();
            _showLoseDialog("GERAKAN HABIS!");
          } else {
            _checkWin();
          }
        });
      }
    }
  }

  void _checkWin() {
    bool win = true;
    for (int i = 0; i < _board.length - _emptyCount; i++) {
      if (_board[i] != i) {
        win = false;
        break;
      }
    }
    if (win) {
      _timer?.cancel();
      _showWinDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset('assets/andes.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildPuzzleGrid(),
                const SizedBox(height: 20),
                _buildReferenceImage(),
                const Spacer(),
                _buildStats(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                "STAGE ${widget.stage}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "PUZZLE PACA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // IconButton(
          //   icon: const Icon(Icons.flash_on, color: Colors.amber),
          //   onPressed: _cheatWin,
          // ),
          _buildTimerBox(),
        ],
      ),
    );
  }

Widget _buildTimerBox() {
    bool isPanic = _timeLeft < 15 && widget.stage == 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPanic ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPanic ? Colors.redAccent : Colors.cyanAccent,
        ),
      ),
      child: Text(
        widget.stage < 3 ? "∞" : "$_timeLeft s", // Keren kan pakai Infinity!
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildPuzzleGrid() {
    double boardSize = MediaQuery.of(context).size.width - 40;
    return Container(
      width: boardSize,
      height: boardSize,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _board.length,
        itemBuilder: (context, index) {
          int? val = _board[index];
          if (val == null)
            return Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          return GestureDetector(
            onTap: () => _performMove(index),
            child: _buildTile(val),
          );
        },
      ),
    );
  }

  Widget _buildTile(int correctIdx) {
    int row = correctIdx ~/ _gridSize;
    int col = correctIdx % _gridSize;
    double alignX = -1.0 + (col * (2.0 / (_gridSize - 1)));
    double alignY = -1.0 + (row * (2.0 / (_gridSize - 1)));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          alignment: Alignment(alignX, alignY),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 56,
            height: MediaQuery.of(context).size.width - 56,
            child: Image.asset(_selectedImage, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceImage() {
    return Column(
      children: [
        const Text(
          "TARGET GAMBAR",
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 2),
            image: DecorationImage(
              image: AssetImage(_selectedImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

Widget _buildStats() {
    // Stage 1 bebas gerakan, Stage 2 & 3 ada batasnya
    String movesText = widget.stage == 1 ? "$_moves / ∞" : "$_moves / $_moveLimit";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statItem("GERAKAN", movesText),
          const SizedBox(width: 30),
          _statItem("UKURAN", "${_gridSize}x${_gridSize}"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- DIALOGS ---

  void _showTargetPreview() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.cyanAccent),
          ),
          title: const Text(
            "INGAT GAMBAR INI!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  _selectedImage,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 15),
              if (widget.stage == 3)
                const Text(
                  "AWAS! JANGAN MELEBIHI BATAS GERAKAN!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {
                      _gameStarted = true;
                      _startTimer();
                    });
                  }
                },
                child: const Text(
                  "MULAI",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinDialog() {
    if (_isSoundOn) _sfxPlayer.play(AssetSource('sounds/win.mp3'));
    _showEndDialog(
      "MISI BERHASIL!",
      Icons.emoji_events,
      Colors.cyanAccent,
      true,
    );
  }

  void _showLoseDialog(String msg) {
    if (_isSoundOn) _sfxPlayer.play(AssetSource('sounds/lose.mp3'));
    _showEndDialog(msg, Icons.timer_off, Colors.redAccent, false);
  }

  void _showEndDialog(String title, IconData icon, Color color, bool isWin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: color, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 70),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  // 1. Matikan Timer & Musik Dulu
                  _timer?.cancel();
                  await _bgmPlayer.stop();
                  await _sfxPlayer.stop();

                  if (!mounted) return;
                  Navigator.pop(context); // Tutup Dialog

                  if (isWin) {
                    if (widget.stage < 3) {
                      // LANJUT KE STAGE BERIKUTNYA
                      // Gunakan Microtask agar transisi bersih dari context dialog
                      Future.microtask(() {
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PuzzlePacaScreen(stage: widget.stage + 1),
                            ),
                          );
                        }
                      });
                    } else {
                      Navigator.pop(context); // Balik ke home
                    }
                  } else {
                    _setupStage();
                    _initializeBoard();
                    _playBGM();
                    _showTargetPreview();
                  }
                },
                child: Text(
                  isWin
                      ? (widget.stage < 3 ? "NEXT STAGE" : "BACK TO HOME")
                      : "COBA LAGI",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
