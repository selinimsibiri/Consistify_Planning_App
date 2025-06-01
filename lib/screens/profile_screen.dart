import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/screens/market_section.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> selectedItems = {}; // 🔹 kategori adı: görsel yolu

  // 🧩 Uygulama açıldığında DB'den seçilen itemları yükle
  @override
  void initState() {
    super.initState();
    _loadSelectedItems();
  }

  Future<void> _loadSelectedItems() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT si.name, si.category_id, c.name as category_name
      FROM user_selected_items usi
      JOIN shop_items si ON usi.item_id = si.id
      JOIN categories c ON si.category_id = c.id
    ''');

    Map<String, String> loadedItems = {};
    for (var row in result) {
      String category = row['category_name'] as String;
      String itemName = row['name'] as String;
      loadedItems[category] = 'assets/items/$category/$itemName.png';
    }

    setState(() {
      selectedItems = loadedItems;
    });
  }

  void updateSelectedItem(String category, String imagePath) {
    setState(() {
      selectedItems[category] = imagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x404040),
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
                        border: Border.all(color: Color(0xececec)),
                      ),
                     child: Stack(
                      alignment: Alignment.center,
                      children: selectedItems.entries.map((entry) {
                        return Image.asset(
                          entry.value,
                          fit: BoxFit.contain,
                          height: 200,
                        );
                      }).toList(),
                    ),

                    ),
                  ),
                  // Market Alanı: Şimdilik placeholder
                  Expanded(
                    child: MarketSection(
                      onItemSelected: updateSelectedItem,
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
