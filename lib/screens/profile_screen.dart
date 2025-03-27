import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/screens/market_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // hafif arka plan rengi
      body: SafeArea(
        child: Column(
          children: [
            // Üst: Başlık
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Orta: Karakter ve Market Alanı
            Expanded(
              child: Column(
                children: [
                  // Karakter Görseli
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                    child: Container(
                      width: 400, // Genişliği isteğine göre ayarla
                      height: 220, // Yüksekliği isteğine göre ayarla
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16), // İstersen kenarlar yumuşak
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset('assets/images/p1.png'),
                          Image.asset('assets/images/p2.png'),
                          Image.asset('assets/images/p3.png'),
                          Image.asset('assets/images/p4.png'),
                          // Gerekirse daha fazla layer eklenebilir
                        ],
                      ),
                    ),
                  ),
                  // Market Alanı: Şimdilik placeholder
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MarketSection(),
                    ),
                  ),
                ],
              ),
            ),

            // Alt: Sayfa geçiş butonları
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.home),
                    onPressed: () {
                      // Ana sayfaya git
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.person),
                    onPressed: () {
                      // Profil sayfasındayız zaten
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      // Ayarlar sayfasına git
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
