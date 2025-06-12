import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🆕 Eklendi
import 'package:sayfa_yonlendirme/screens/daily_screen.dart';
import 'package:sayfa_yonlendirme/screens/login_page.dart';
import 'package:sayfa_yonlendirme/screens/market_section.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/planning_screen.dart';
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
  int userCoins = 0;

  final List<String> layerOrder = [
    'body', 'shoes', 'bottom', 'top', 'mouth', 'eyes', 'hair', 'accs', 'hat',
  ];

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadSelectedItems();
    _loadUserCoins();
  }

  Future<void> _loadUserCoins() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      setState(() {
        userCoins = result.first['coins'] as int? ?? 0;
      });
    }
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
    _loadUserCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🆕 Status bar ayarları - TodoScreen ile aynı
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF1A1A1A),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      body: Container(
        // 🆕 Arka plan gradient - TodoScreen ile aynı
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 46, 46, 46),
            ],
            stops: [1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🆕 ÜST BAR - TodoScreen ile aynı stil
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Sol -🚪 Logout icon
                    GestureDetector(
                      onTap: _showLogoutDialog,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF404040),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    // 🆕 PROFILE başlığı - TodoScreen ile aynı stil
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'PROFILE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 🆕 Coin - TodoScreen streak ile aynı stil
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$userCoins',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('🪙', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🆕 İçerik alanı - Market alt bara bitişik olacak
              Expanded(
                child: Column(
                  children: [
                    // 🎯 Karakter Görseli - Padding ile
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF8F9FA),
                                  Color(0xFFE9ECEF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFF8B5CF6).withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF8B5CF6).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Karakter katmanları
                                ...layerOrder.map((category) {
                                  if (selectedItems.containsKey(category)) {
                                    return Image.asset(
                                      selectedItems[category]!,
                                      fit: BoxFit.contain,
                                      height: 200,
                                    );
                                  }
                                  return SizedBox.shrink();
                                }).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // 🆕 Market Alanı - Expanded ile kalan tüm alanı kapla
                    Expanded(
                      child: MarketSection(
                        onItemSelected: updateSelectedItem, 
                        userId: userId,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 🆕 ALT NAVIGATION BAR - TodoScreen ile tamamen aynı
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              icon: Icons.check_circle_outline,
              color: Color(0xFF8B5CF6),
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
              icon: Icons.assignment_outlined,
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
              icon: Icons.schedule,
              color: Color(0xFF10B981),
              onTap: () {
                print('📅 Planning sayfasına geçiliyor...');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanningScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildNavButton(
              icon: Icons.person_outline,
              color: Color(0xFFF59E0B),
              isActive: true,
              onTap: () {},
            ),
            _buildNavButton(
              icon: Icons.trending_up,
              color: Color(0xFFEC4899),
              onTap: () async {
                try {
                  await DatabaseHelper.instance.exportDatabaseToJson();
                  _showSnackBar('📄 Database başarıyla export edildi!', Colors.green);
                } catch (e) {
                  _showSnackBar('❌ Export hatası: $e', Colors.red);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Navigation Button - TodoScreen ile aynı
  Widget _buildNavButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Çıkış Yap',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC4899),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
      (route) => false,
    );
    _showSnackBar('Başarıyla çıkış yapıldı!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
