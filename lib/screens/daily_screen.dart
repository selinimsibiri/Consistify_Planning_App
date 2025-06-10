import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/todo_screen.dart';

class DailyScreen extends StatefulWidget {
  final int userId;

  const DailyScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DailyScreenState createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  List<Map<String, dynamic>> dailyTasks = [];
  int streakCount = 13;

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
  }

  Future<void> _loadDailyTasks() async {
    final db = await DatabaseHelper.instance.database;
    
    // 🎯 Sadece aktif daily template'leri getir (is_active = 1)
    final results = await db.query(
      'daily_templates',
      where: 'user_id = ? AND is_active = 1', // 🎯 is_active kontrolü ekledik
      whereArgs: [widget.userId],
      orderBy: 'id DESC',
    );
    
    setState(() {
      dailyTasks = results;
    });
    
    print('📋 Aktif daily task\'lar yüklendi: ${dailyTasks.length}');
  }

  void _showAddDailyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AddDailyDialog(
          userId: widget.userId,
          onDailyAdded: () {
            _loadDailyTasks(); // 🎯 Daily ekranını güncelle
          },
        );
      },
    );
  }

  void _showEditDailyDialog(Map<String, dynamic> daily) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditDailyDialog(
          userId: widget.userId,
          daily: daily,
          onDailyUpdated: () {
            _loadDailyTasks(); // 🎯 Daily ekranını güncelle
          },
        );
      },
    );
  }

  Future<void> _deleteDailyTask(int dailyId) async {
    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Daily Görevi Sil'),
        content: Text('Silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // 🎯 Database helper'daki yeni fonksiyonu kullan
        await DatabaseHelper.instance.deleteDailyTemplate(dailyId);
        
        // UI'yi güncelle
        _loadDailyTasks(); // Daily ekranını güncelle

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily görevi ve ilgili task\'lardan yapmadıkların tamamen silindi!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2D2D2D),
      body: SafeArea(
        child: Column(
          children: [
            // 🎯 Üst Bar
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 24),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DAILIES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$streakCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🔥', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🎯 Daily Task Listesi
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ...dailyTasks.map((daily) => _buildDailyItem(daily)),
                  ],
                ),
              ),
            ),

            // 🎯 Add Daily Button
            Padding(
              padding: EdgeInsets.all(16),
              child: FloatingActionButton(
                onPressed: _showAddDailyDialog,
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),

            // 🎯 Alt Navigation Bar
            Container(
              height: 80,
              color: Color(0xFF2D2D2D),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    icon: Icons.check_circle,
                    color: Color(0xFF8B5CF6), // Mor
                     onTap: () async {
                      // ✅ Todo ekranına git ve geri dönüşte refresh yap
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TodoScreen(userId: widget.userId),
                        ),
                      );
                      // Todo ekranından geri dönüldüğünde daily'leri yenile
                      if (result == 'refresh') {
                        _loadDailyTasks();
                      }
                    }
                  ),
                  _buildNavButton(
                    icon: Icons.assignment,
                    color: Color(0xFF06B6D4),
                    isActive: true,
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.home,
                    color: Color(0xFFF59E0B),
                    onTap: () => Navigator.pop(context, 'refresh'),
                  ),
                  _buildNavButton(
                    icon: Icons.trending_up,
                    color: Color(0xFFEC4899),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyItem(Map<String, dynamic> daily) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('daily_${daily['id']}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: 30,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Color(0xFF6B7280),
                title: Text(
                  'Daily Görevi Sil',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  '"${daily['title']}" daily görevini ve ona bağlı tüm task\'ları silmek istediğinizden emin misiniz?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('İptal', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Sil', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ) ?? false;
        },
        onDismissed: (direction) {
          _deleteDailyTask(daily['id']);
        },
        child: Row(
          children: [
            // Daily container
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  daily['title'] ?? 'daily',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 12),
            
            // 🎯 Edit butonu
            GestureDetector(
              onTap: () => _showEditDailyDialog(daily),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
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
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

// 🎯 Edit Daily Dialog
class EditDailyDialog extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> daily;
  final VoidCallback onDailyUpdated;

  const EditDailyDialog({
    Key? key,
    required this.userId,
    required this.daily,
    required this.onDailyUpdated,
  }) : super(key: key);

  @override
  _EditDailyDialogState createState() => _EditDailyDialogState();
}

class _EditDailyDialogState extends State<EditDailyDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  List<String> dayNames = ['m', 't', 'w', 'th', 'f', 's', 'su'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.daily['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.daily['description'] ?? '');
    
    // Mevcut günleri yükle
    String savedDays = widget.daily['selected_days'] ?? '0,0,0,0,0,0,0';
    List<String> days = savedDays.split(',');
    for (int i = 0; i < days.length && i < 7; i++) {
      selectedDays[i] = days[i] == '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF6B7280),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Başlık Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'daily name',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 🎯 Açıklama Input
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'info',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 🎯 Gün Seçimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDays[index] = !selectedDays[index];
                    });
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: selectedDays[index] ? Color(0xFF8B5CF6) : Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Alt Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // İptal Butonu (X)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Güncelle Butonu (✓)
                GestureDetector(
                  onTap: _updateDaily,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDaily() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen daily adı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!selectedDays.any((day) => day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen en az bir gün seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    // 🎯 YENİ: Eski günleri al (karşılaştırma için)
    String oldSelectedDays = widget.daily['selected_days'] ?? '0,0,0,0,0,0,0';
    
    // Seçili günleri string olarak kaydet
    String selectedDaysString = selectedDays.map((e) => e ? '1' : '0').join(',');
    
    await db.update(
      'daily_templates',
      {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'selected_days': selectedDaysString,
      },
      where: 'id = ?',
      whereArgs: [widget.daily['id']],
    );

    // 🎯 YENİ: Günler değiştiyse bugünkü task'ı kontrol et
    if (oldSelectedDays != selectedDaysString) {
      await _checkAndDeactivateTodayTask();
    }

    widget.onDailyUpdated();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily görev başarıyla güncellendi!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  // 🎯 YENİ FONKSİYON: Bugünkü task'ı kontrol et
  Future<void> _checkAndDeactivateTodayTask() async {
    try {
      final today = DateTime.now();
      final todayWeekday = today.weekday; // 1=Pazartesi, 7=Pazar
      
      // Flutter weekday'i database formatına çevir (0=Pazartesi, 6=Pazar)
      int todayIndex = todayWeekday == 7 ? 6 : todayWeekday - 1;
      
      // Bugün seçili günler arasında var mı?
      bool isTodaySelected = selectedDays[todayIndex];
      
      if (!isTodaySelected) {
        // Bugün artık seçili değilse, bugünkü task'ı deaktif et
        await DatabaseHelper.instance.deactivateTodayTaskForDaily(
          widget.daily['id'],
          today,
        );
        
        print('🔄 Daily güncellenince bugünkü task deaktif edildi');
      }
    } catch (e) {
      print('❌ Bugünkü task deaktif etme hatası: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// 🎯 Add Daily Dialog (aynı kalacak, sadece onDailyAdded callback'i kullanacak)
class AddDailyDialog extends StatefulWidget {
  final int userId;
  final VoidCallback onDailyAdded;

  const AddDailyDialog({
    Key? key,
    required this.userId,
    required this.onDailyAdded,
  }) : super(key: key);

  @override
  _AddDailyDialogState createState() => _AddDailyDialogState();
}

class _AddDailyDialogState extends State<AddDailyDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  List<String> dayNames = ['m', 't', 'w', 'th', 'f', 's', 'su'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF6B7280),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Başlık Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'daily name',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 🎯 Açıklama Input
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'info',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 🎯 Gün Seçimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDays[index] = !selectedDays[index];
                    });
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: selectedDays[index] ? Color(0xFF8B5CF6) : Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Alt Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // İptal Butonu (X)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Ekle Butonu (+)
                GestureDetector(
                  onTap: _addDaily,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDaily() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen daily adı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!selectedDays.any((day) => day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen en az bir gün seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    
    // Seçili günleri string olarak kaydet
    String selectedDaysString = selectedDays.map((e) => e ? '1' : '0').join(',');
    
    await db.insert('daily_templates', {
      'user_id': widget.userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'selected_days': selectedDaysString,
      'coin_reward': 5,
      'is_active': 1,
    });

    // 🎯 Yeni daily eklendikten sonra bugün için task oluştur
    await DatabaseHelper.instance.generateDailyTasksForUser(widget.userId);

    widget.onDailyAdded();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily görev başarıyla eklendi!'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
