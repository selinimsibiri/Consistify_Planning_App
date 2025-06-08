import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class MarketSection extends StatefulWidget {
  final int userId; 
  final void Function(String category, String imagePath)? onItemSelected;

  const MarketSection({Key? key, required this.userId, this.onItemSelected}) : super(key: key);

  @override
  _MarketSectionState createState() => _MarketSectionState();
}

class _MarketSectionState extends State<MarketSection> {
  Map<String, String> selectedItems = {};
  late int userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadUserSelectedItems();
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
    'body': 1,
    'eyes': 2,
    'mouth': 3,
    'hair': 4,
    'top': 5,
    'bottom': 6,
    'shoes': 7,
    'accs': 8,
    'hat': 9,
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
        color: Color(0xFF404040), // Koyu gri arkaplan
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          
          // 🎯 Kategori Butonları
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['name'] == selectedCategory;

                return Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 16 : 4,
                    right: index == categories.length - 1 ? 16 : 4,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat['name']!;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Color(0xFF8B5CF6) // Mor (seçili)
                            : Color(0xFF6B6B6B), // Gri (seçili değil)
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Color(0xFF7C3AED) // Koyu mor border
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        cat['icon']!,
                        fit: BoxFit.contain,
                        color: Colors.white, // Icon beyaz
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12),

          // 🎯 Grid Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getItemsForSelectedCategory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Bu kategoriye ait item bulunamadı.",
                        style: TextStyle(color: Colors.white70),
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
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      String imagePath = 'assets/items/$selectedCategory/${item['name']}.png';

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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF6B6B6B), // Gri arkaplan
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedItems[selectedCategory] == imagePath
                                  ? Color(0xFF8B5CF6) // Mor border (seçili)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
