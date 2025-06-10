import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class MarketSection extends StatefulWidget {
  final int userId; 
  final void Function(String category, String imagePath)? onItemSelected;

  const MarketSection({Key? key, required this.userId, this.onItemSelected}) : super(key: key);

  @override
  _MarketSectionState createState() => _MarketSectionState();
}

class _MarketSectionState extends State<MarketSection> with TickerProviderStateMixin {
  Map<String, String> selectedItems = {};
  late int userId;
  late AnimationController _categoryController;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadUserSelectedItems();
    
    // 🎯 Kategori animasyonu
    _categoryController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  List<Map<String, String>> categories = [
    {'name': 'body', 'icon': 'assets/category_icons/body.png'},
    {'name': 'eyes', 'icon': 'assets/category_icons/eyes.png'},
    {'name': 'mouth', 'icon': 'assets/category_icons/mouth.png'},
    {'name': 'hair', 'icon': 'assets/category_icons/hair.png'},
    {'name': 'top', 'icon': 'assets/category_icons/top.png'},
    {'name': 'bottom', 'icon': 'assets/category_icons/bottom.png'},
    {'name': 'shoes', 'icon': 'assets/category_icons/shoes.png'},
    {'name': 'accs', 'icon': 'assets/category_icons/accs.png'},
    {'name': 'hat', 'icon': 'assets/category_icons/hat.png'},
  ];

  Map<String, int> categoryIds = {
    'body': 1, 'eyes': 2, 'mouth': 3, 'hair': 4, 'top': 5,
    'bottom': 6, 'shoes': 7, 'accs': 8, 'hat': 9,
  };

  String selectedCategory = 'body';

  Future<void> _loadUserSelectedItems() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT s.name, s.category_id, c.name as category_name
      FROM user_selected_items u
      JOIN shop_items s ON u.item_id = s.id
      JOIN categories c ON s.category_id = c.id
      WHERE u.user_id = ?
    ''', [userId]);

    setState(() {
      selectedItems.clear();
      for (var row in result) {
        final category = row['category_name'] as String;
        final itemName = row['name'] as String;
        selectedItems[category] = 'assets/items/$category/$itemName.png';
      }
    });
  }

  Future<List<Map<String, dynamic>>> getItemsForSelectedCategory() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'shop_items',
      where: 'category_id = ?',
      whereArgs: [categoryIds[selectedCategory]],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF404040),
            Color(0xFF2D2D2D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Market başlığı
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'MARKET',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // 🎯 Kategori Butonları - Geliştirilmiş
          Container(
            height: 70,
            margin: EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['name'] == selectedCategory;

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat['name']!;
                      });
                      _categoryController.forward().then((_) {
                        _categoryController.reverse();
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Color(0xFF6B6B6B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Color(0xFF8B5CF6).withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            cat['icon']!,
                            fit: BoxFit.contain,
                            color: Colors.white,
                            height: 28,
                          ),
                          SizedBox(height: 2),
                          Text(
                            cat['name']!.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🎯 Grid Items - Geliştirilmiş
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getItemsForSelectedCategory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Yükleniyor...",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white30,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Bu kategoriye ait item bulunamadı.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data!;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      String imagePath = 'assets/items/$selectedCategory/${item['name']}.png';
                      bool isItemSelected = selectedItems[selectedCategory] == imagePath;

                      return GestureDetector(
                        onTap: () async {
                          final db = await DatabaseHelper.instance.database;

                          await db.delete(
                            'user_selected_items',
                            where: 'user_id = ? AND item_id IN (SELECT id FROM shop_items WHERE category_id = ?)',
                            whereArgs: [userId, categoryIds[selectedCategory]],
                          );

                          await db.insert('user_selected_items', {
                            'user_id': userId,
                            'item_id': item['id'],
                          });

                          if (widget.onItemSelected != null) {
                            widget.onItemSelected!(selectedCategory, imagePath);
                          }

                          setState(() {
                            selectedItems[selectedCategory] = imagePath;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: isItemSelected 
                                ? LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6).withOpacity(0.3),
                                      Color(0xFF7C3AED).withOpacity(0.3),
                                    ],
                                  )
                                : null,
                            color: isItemSelected ? null : Color(0xFF6B6B6B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isItemSelected
                                  ? Color(0xFF8B5CF6)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isItemSelected ? [
                              BoxShadow(
                                color: Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ] : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: 16), // Alt boşluk
        ],
      ),
    );
  }
}
