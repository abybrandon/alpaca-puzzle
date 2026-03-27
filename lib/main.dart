import 'package:alpacapuzzle/start_screen/start_screen.dart' show StartScreen;
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'dart:async'; // Untuk delay saat kartu salah

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}


class MemoryPacaScreen extends StatefulWidget {
  @override
  _MemoryPacaScreenState createState() => _MemoryPacaScreenState();
}

class _MemoryPacaScreenState extends State<MemoryPacaScreen> {
  // 1. Data Game (Gambar Aset)
  // Kita butuh sepasang untuk setiap gambar. Total 8 kartu (4 pasang).
  List<String> _cards = [
    'assets/alpaca_merah.png', 'assets/alpaca_merah.png',
    'assets/alpaca_biru.png', 'assets/alpaca_biru.png',
    'assets/wortel.png', 'assets/wortel.png',
    'assets/kaktus.png', 'assets/kaktus.png',
  ];

  // 2. State Game (Status Kartu)
  List<bool> _cardFlipped = []; // Apakah kartu sedang terbuka?
  List<bool> _cardMatched = []; // Apakah kartu sudah cocok/mati?
  int? _firstFlippedIndex; // Index kartu pertama yang dibuka
  bool _isCheckingMatch = false; // Mencegah tap saat animasi delay
  int _score = 0; // Skor (opsional)

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  // 3. Fungsi Reset/Mulai Game
  void _resetGame() {
    setState(() {
      _cards.shuffle(); // ACAK KARTU! Sangat penting.
      _cardFlipped = List<bool>.filled(_cards.length, false);
      _cardMatched = List<bool>.filled(_cards.length, false);
      _firstFlippedIndex = null;
      _isCheckingMatch = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Latar belakang pastel
      appBar: AppBar(
        title: Text("Memory Paca Harian"),
        backgroundColor: Colors.green[200],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Indikator Skor/Harian
            Text("Cocokkan semua Alpaca!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            // GRID KARTU (Inti Game)
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 kartu per baris
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  // Cek status kartu untuk menentukan apa yang ditampilkan
                  if (_cardMatched[index]) {
                    // JIKA SUDAH COCOK -> Kartu hilang (Container kosong)
                    return Container(color: Colors.transparent);
                  }

                  return GestureDetector(
                    onTap: () => _onCardTap(index), // Logika saat kartu di-tap
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300), // Animasi putar
                      decoration: BoxDecoration(
                        color: _cardFlipped[index] ? Colors.white : Colors.green[200], // Warna depan/belakang
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Center(
                        child: _cardFlipped[index]
                            ? Image.asset(_cards[index], width: 60) // Tampilkan Gambar (Depan)
                            : Icon(Icons.help_outline, size: 40, color: Colors.green[700]), // Tampilkan Ikon (Belakang)
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Logika Inti Permainan (Saat Kartu Di-tap)
  void _onCardTap(int index) {
    // Abaikan jika: Sedang delay pengecekan, kartu sudah terbuka, atau kartu sudah cocok.
    if (_isCheckingMatch || _cardFlipped[index] || _cardMatched[index]) {
      return;
    }

    setState(() {
      // Buka kartu yang di-tap
      _cardFlipped[index] = true;

      if (_firstFlippedIndex == null) {
        // INI ADALAH KARTU PERTAMA
        _firstFlippedIndex = index;
      } else {
        // INI ADALAH KARTU KEDUA
        _isCheckingMatch = true; // Kunci tap kartu lain

        // CEK APAKAH COCOK (Gambar sama tapi index berbeda)
        if (_cards[_firstFlippedIndex!] == _cards[index]) {
          // --- MATCH! (Cocok) ---
          Future.delayed(Duration(milliseconds: 500), () {
            setState(() {
              _cardMatched[_firstFlippedIndex!] = true;
              _cardMatched[index] = true;
              _cardFlipped[_firstFlippedIndex!] = false; // Reset status buka
              _cardFlipped[index] = false; // Reset status buka
              _firstFlippedIndex = null; // Reset pointer
              _isCheckingMatch = false; // Buka kunci tap
              _score += 10;

              // Cek Kondisi Menang
              if (_cardMatched.every((matched) => matched)) {
                _showWinDialog();
              }
            });
          });
        } else {
          // --- NO MATCH! (Salah) ---
          // Beri jeda 1 detik agar pemain bisa menghafal, lalu tutup kembali.
          Future.delayed(Duration(seconds: 1), () {
            setState(() {
              _cardFlipped[_firstFlippedIndex!] = false;
              _cardFlipped[index] = false;
              _firstFlippedIndex = null; // Reset pointer
              _isCheckingMatch = false; // Buka kunci tap
            });
          });
        }
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("YAY! HmmmHmm! 🦙"),
        content: Text("Kamu menyelesaikan Memory Paca hari ini! Ini hadiah Wortel harianmu."),
        actions: [
          TextButton(onPressed: () {
            Navigator.of(context).pop();
            _resetGame();
          }, child: Text("Main Lagi")),
        ],
      ),
    );
  }
}