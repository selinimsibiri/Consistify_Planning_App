import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/screens/daily_screen.dart';
import 'package:sayfa_yonlendirme/screens/login_page.dart';
import 'package:sayfa_yonlendirme/screens/market_section.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/todo_screen.dart';
import 'package:sayfa_yonlendirme/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int userId;
  Map<String, String> selectedItems = {};

  // Katman sıralamasını
  final List<String> layerOrder = [
    'body',    // En arkada
    'shoes',   // Ayakkabı
    'bottom',  // Pantolon/etek
    'top',     // Üst giyim
    'mouth',   // Ağız
    'eyes',    // Gözler
    'hair',    // Saç
    'accs',    // Aksesuar
    'hat',     // Şapka (en önde)
  ];

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadSelectedItems();
  }

  Future<void> _loadSelectedItems() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT si.name, si.category_id, c.name as category_name
      FROM user_selected_items usi
      JOIN shop_items si ON usi.item_id = si.id
      JOIN categories c ON si.category_id = c.id
      WHERE usi.user_id = ?
    ''', [userId]);

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
      backgroundColor: Color(0xFF2D2D2D), // Koyu gri arkaplan
      body: SafeArea(
        child: Column(
          children: [
            // 🎯 Üst Bar - Mor gradient
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6), // Mor
                    Color(0xFF7C3AED), // Koyu mor
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Settings icon
                    GestureDetector(
                      onTap: () {
                        _showLogoutDialog();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    Spacer(),
                    
                    // Profile text
                    Text(
                      "PROFILE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    Spacer(),
                    
                    // Level & Coins
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "13 🔥",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "💰 256",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.yellow[300],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

             // 🎯 Karakter Görseli - Düzeltilmiş katman sıralaması
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFFE0E0E0),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ✅ Katmanları sabit sırayla göster
                      ...layerOrder.map((category) {
                        if (selectedItems.containsKey(category)) {
                          return Image.asset(
                            selectedItems[category]!,
                            fit: BoxFit.contain,
                            height: 180,
                          );
                        }
                        return SizedBox.shrink(); // Boş widget
                      }).toList(),
                    ],
                  ),
                ),
              ),

            // 🎯 Market Alanı
            Expanded(
              child: MarketSection(
                onItemSelected: updateSelectedItem, userId: userId,
              ),
            ),

            // 🎯 Alt Navigation Bar - Renkli butonlar
            Container(
              height: 80,
              color: Color(0xFF2D2D2D),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    icon: Icons.check_circle,
                    color: Color(0xFF8B5CF6), // Mor
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TodoScreen(userId: userId),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.assignment,
                    color: Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.home,
                    color: Color(0xFFF59E0B), // Turuncu
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.trending_up,
                    color: Color(0xFFEC4899), // Pembe
                    onTap: () async {
                      try {
                        await DatabaseHelper.instance.exportDatabaseToJson();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📄 Database JSON\'a export edildi!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Export hatası: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  Widget _buildNavButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Çıkış Yap'),
          content: Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _logout(); // Çıkış yap
              },
              child: Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await AuthService.logout();

    // Tüm ekranları temizleyip login sayfasına git
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
      (route) => false, // Tüm önceki route'ları temizle
    );

    // 🎯 Kullanıcıya bilgi ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Başarıyla çıkış yapıldı!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}