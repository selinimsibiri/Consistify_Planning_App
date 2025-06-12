import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/todo_screen.dart';
import 'package:sayfa_yonlendirme/screens/profile_screen.dart';

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
    
    final results = await db.query(
      'daily_templates',
      where: 'user_id = ? AND is_active = 1',
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
      barrierDismissible: true, // 🔧 Dışarıya tıklayınca kapanır
      builder: (BuildContext context) {
        return AddDailyDialog(
          userId: widget.userId,
          onDailyAdded: _loadDailyTasks,
        );
      },
    );
  }

  void _showEditDailyDialog(Map<String, dynamic> daily) {
    showDialog(
      context: context,
      barrierDismissible: true, // 🔧 Dışarıya tıklayınca kapanır
      builder: (BuildContext context) {
        return EditDailyDialog(
          userId: widget.userId,
          daily: daily,
          onDailyUpdated: _loadDailyTasks,
        );
      },
    );
  }

  Future<void> _deleteDailyTask(int dailyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Daily Görevi Sil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Silmek istediğine emin misin?',
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
      ),
    );
    
    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteDailyTemplate(dailyId);
        _loadDailyTasks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily görevi ve ilgili task\'lardan yapmadıkların tamamen silindi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Status bar'ı koyu yap
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
      body: Stack( // 🆕 Stack eklendi
        children: [
          Container(
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
                  // 🎯 Üst Bar
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
                        // 🚪 Logout icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFF404040),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        // 📝 DAILIES başlığı - Dinamik genişlik
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
                                'DAILIES',
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
                        
                        // 🔥 Streak counter
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
                                  '$streakCount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text('🔥', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🎯 Daily Task Listesi
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          ...dailyTasks.map((daily) => _buildDailyItem(daily)),
                          SizedBox(height: 100), // Alt navigation için boşluk
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 🆕 Sağ alt köşede + butonu - Alt bara bitişik
          Positioned(
            right: 0, // Sağa tam bitişik
            bottom: 90, // Alt barın hemen üstü
            child: GestureDetector(
              onTap: _showAddDailyDialog,
              child: Container(
                width: 70,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)], // Daily renkleri
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    bottomLeft: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF06B6D4).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(-3, 0), // Sola doğru gölge
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
      
      // 🆕 Alt Navigation Bar - 5 buton
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 🔧 5 buton eşit dağılım
          children: [
            _buildNavButton(
              icon: Icons.check_circle_outline,
              color: Color(0xFF8B5CF6),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodoScreen(userId: widget.userId),
                  ),
                );
                if (result == 'refresh') {
                  _loadDailyTasks();
                }
              },
            ),
            _buildNavButton(
              icon: Icons.assignment_outlined,
              color: Color(0xFF06B6D4),
              isActive: true, // Daily aktif
              onTap: () {},
            ),
            // 🆕 Yeni Ajanda/Planlama butonu - Ortada
            _buildNavButton(
              icon: Icons.schedule,
              color: Color(0xFF10B981), // 🟢 Yeşil renk
              onTap: () {
                // TODO: Ajanda/Planlama sayfasına git
                print('📅 Ajanda sayfasına gidilecek');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📅 Ajanda özelliği yakında gelecek!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
            ),
            _buildNavButton(
              icon: Icons.person_outline,
              color: Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildNavButton(
              icon: Icons.trending_up,
              color: Color(0xFFEC4899),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Daily Item
  Widget _buildDailyItem(Map<String, dynamic> daily) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key('daily_${daily['id']}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(0.1), Colors.red],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Color(0xFF333333),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Daily Görevi Sil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4F46E5).withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  daily['title'] ?? 'daily',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 16),
            
            // Edit butonu
            GestureDetector(
              onTap: () => _showEditDailyDialog(daily),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6B7280).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_calendar_outlined,
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

  // Navigation Button  
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
}

// Dialog sınıfları aynı kalacak...
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
  late double _coinReward; // 🆕 Coin slider değeri
  
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  List<String> dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.daily['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.daily['description'] ?? '');
    _coinReward = (widget.daily['coin_reward'] ?? 3).toDouble(); // 🆕 Mevcut coin değeri
    
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
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D), // 🎨 Todo ile aynı renk
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Title Input - Todo ile aynı tasarım
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Daily name...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Description Input - Todo ile aynı tasarım
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Daily description (optional)...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🆕 COIN SELECTION SECTION - Todo ile aynı tasarım
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF06B6D4).withOpacity(0.1),
                    Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Coin header and value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Difficulty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF06B6D4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF06B6D4).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_coinReward.round()}',
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
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 🎯 Slider - Daily renkleri ile
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        elevation: 4,
                      ),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: Color(0xFF06B6D4),
                      inactiveTrackColor: Color(0xFF404040),
                      thumbColor: Colors.white,
                      overlayColor: Color(0xFF06B6D4).withOpacity(0.2),
                      valueIndicatorColor: Color(0xFF06B6D4),
                      valueIndicatorTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: _coinReward,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (value) {
                        setState(() {
                          _coinReward = value;
                        });
                      },
                    ),
                  ),
                  
                  // Difficulty level descriptions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Easy',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Medium',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Hard',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Days Selection - Mevcut tasarım korundu
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF404040),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(7, (index) {
                      double screenWidth = MediaQuery.of(context).size.width;
                      double availableWidth = screenWidth * 0.85 - 32;
                      double dayButtonWidth = (availableWidth / 7) - 6;
                      dayButtonWidth = dayButtonWidth.clamp(28.0, 40.0);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDays[index] = !selectedDays[index];
                          });
                        },
                        child: Container(
                          width: dayButtonWidth,
                          height: dayButtonWidth,
                          decoration: BoxDecoration(
                            gradient: selectedDays[index] 
                                ? LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                                  )
                                : null,
                            color: selectedDays[index] ? null : Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selectedDays[index] ? [
                              BoxShadow(
                                color: Color(0xFF06B6D4).withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dayButtonWidth > 35 ? 12 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 28),
            
            // 🎯 Update Daily Button - Todo ile aynı tasarım
            GestureDetector(
              onTap: _updateDaily,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)], // 🎨 Update için yeşil
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Update Daily',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
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
          content: Text('Please enter a daily name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!selectedDays.any((day) => day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    String oldSelectedDays = widget.daily['selected_days'] ?? '0,0,0,0,0,0,0';
    String selectedDaysString = selectedDays.map((e) => e ? '1' : '0').join(',');
    
    await db.update(
      'daily_templates',
      {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'selected_days': selectedDaysString,
        'coin_reward': _coinReward.round(), // 🆕 Slider değeri
      },
      where: 'id = ?',
      whereArgs: [widget.daily['id']],
    );

    if (oldSelectedDays != selectedDaysString) {
      await _checkAndDeactivateTodayTask();
    }

    widget.onDailyUpdated();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily updated successfully! (${_coinReward.round()} 🪙)'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _checkAndDeactivateTodayTask() async {
    try {
      final today = DateTime.now();
      final todayWeekday = today.weekday;
      int todayIndex = todayWeekday == 7 ? 6 : todayWeekday - 1;
      bool isTodaySelected = selectedDays[todayIndex];
      
      if (!isTodaySelected) {
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
  double _coinReward = 3.0; // 🆕 Default 3 coins
  
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  List<String> dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Title Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Daily name...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Description Input
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Daily description (optional)...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // 🆕 COIN SELECTION SECTION
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF06B6D4).withOpacity(0.1),
                    Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF06B6D4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Coin header and value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Difficulty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF06B6D4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF06B6D4).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_coinReward.round()}',
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
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 🎯 Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        elevation: 4,
                      ),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: Color(0xFF06B6D4),
                      inactiveTrackColor: Color(0xFF404040),
                      thumbColor: Colors.white,
                      overlayColor: Color(0xFF06B6D4).withOpacity(0.2),
                      valueIndicatorColor: Color(0xFF06B6D4),
                      valueIndicatorTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: _coinReward,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (value) {
                        setState(() {
                          _coinReward = value;
                        });
                      },
                    ),
                  ),
                  
                  // Difficulty level descriptions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Easy',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Medium',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Hard',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Days Selection
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF404040),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(7, (index) {
                      double screenWidth = MediaQuery.of(context).size.width;
                      double availableWidth = screenWidth * 0.85 - 32;
                      double dayButtonWidth = (availableWidth / 7) - 6;
                      dayButtonWidth = dayButtonWidth.clamp(28.0, 40.0);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDays[index] = !selectedDays[index];
                          });
                        },
                        child: Container(
                          width: dayButtonWidth,
                          height: dayButtonWidth,
                          decoration: BoxDecoration(
                            gradient: selectedDays[index] 
                                ? LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                                  )
                                : null,
                            color: selectedDays[index] ? null : Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selectedDays[index] ? [
                              BoxShadow(
                                color: Color(0xFF06B6D4).withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dayButtonWidth > 35 ? 12 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 28),
            
            // 🎯 Add Daily Button
            GestureDetector(
              onTap: _addDaily,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF06B6D4).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Add Daily',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
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
          content: Text('Please enter a daily name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!selectedDays.any((day) => day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    
    String selectedDaysString = selectedDays.map((e) => e ? '1' : '0').join(',');
    
    await db.insert('daily_templates', {
      'user_id': widget.userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'selected_days': selectedDaysString,
      'coin_reward': _coinReward.round(),
      'is_active': 1,
    });

    await DatabaseHelper.instance.generateDailyTasksForUser(widget.userId);

    Navigator.pop(context);
    widget.onDailyAdded(); // 🔧 Bu satırı popup kapandıktan sonra çağır
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily added successfully! (+${_coinReward.round()} 🪙)'),
        backgroundColor: Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
