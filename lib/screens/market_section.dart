import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class MarketSection extends StatefulWidget {
  const MarketSection({super.key});

  @override
  _MarketSectionState createState() => _MarketSectionState();
}

class _MarketSectionState extends State<MarketSection> {

  final ScrollController _scrollController = ScrollController();

  // 🔹 Kategoriler: name ve icon path
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori Icon Row'u
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat['name'] == selectedCategory;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = cat['name']!;
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueGrey.shade700 : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Image.asset(cat['icon']!, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16),

        // Expanded ile sarıyoruz
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>( 
            future: getItemsForSelectedCategory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("Bu kategoriye ait item bulunamadı."));
              }

              final items = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];

                  // Kategori adı ve item adı ile dinamik bir dosya yolu oluşturuyoruz
                  String imagePath = 'assets/items/$selectedCategory/${item['name']}.png';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Image.asset(imagePath), // Dinamik olarak oluşturulan dosya yolunu kullanıyoruz
                  );
                },
              );
            },
          ),
        ),
      ],
    );

  }
}
