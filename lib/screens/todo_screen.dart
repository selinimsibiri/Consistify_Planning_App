import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/utils/dialog_utils.dart';
import 'package:sayfa_yonlendirme/utils/navigation_utils.dart';
import 'package:sayfa_yonlendirme/widgets/animations/coin_animation_overlay.dart';

class TodoScreen extends StatefulWidget {
  /*
 * Todo görevleri ana ekranı
 * - Kullanıcının todo listesini görüntüler
 * - Todo ekleme, düzenleme, silme ve tamamlama işlemlerini yönetir
 * - Coin sistemi ile entegre çalışır
 */
  final int userId;

  const TodoScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  /*
 * Todo ekranının State sınıfı
 * - One-time ve daily görevleri yükler ve görüntüler
 * - Görev tamamlama/geri alma işlemlerini yönetir
 * - Coin ödüllerini ve başarıları gösterir
 * - Alt navigasyon barı ile diğer ekranlara geçiş sağlar
 * - Floating action button ile yeni görev ekleme
 * - Tamamlanan görevleri listenin altına taşır
 */
  List<Map<String, dynamic>> oneTimeTasks = [];
  List<Map<String, dynamic>> dailyTasks = [];
  List<int> completedTaskIds = [];
  int userCoins = 0;
  int streakCount = 13;

  @override
  void initState() {
    super.initState();
    _initializeTodoScreen();
  }

  Future<void> _initializeTodoScreen() async {
    // Eski görevleri inactive yap ve yeni görevleri oluştur
    await DatabaseHelper.instance.resetAndGenerateDailyTasks(widget.userId);
    await _loadTasks();
    await _loadUserCoins();
    await _loadCompletedTasks();
  }

  Future<void> _loadTasks() async {
    final db = await DatabaseHelper.instance.database;

    final oneTimeResults = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ? AND is_active = 1',
      whereArgs: [widget.userId, 'one_time'],
      orderBy: 'id ASC',
    );
    
    final dailyResults = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ? AND is_active = 1',
      whereArgs: [widget.userId, 'daily'],
      orderBy: 'id ASC',
    );
    
    setState(() {
      oneTimeTasks = oneTimeResults;
      dailyTasks = dailyResults;
    });
    print('📋 Yüklenen görevler: ${oneTimeTasks.length} one-time, ${dailyTasks.length} daily');
  }


  Future<void> _loadCompletedTasks() async {
    print('🔄 Completed tasks yükleniyor...');
    final db = await DatabaseHelper.instance.database;
    
    // 🎯 Bugün tamamlanan tüm taskları al (tarih filtresiz)
    final results = await db.query(
      'tasks',
      columns: ['id'],
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [widget.userId],
    );
    
    setState(() {
      completedTaskIds = results.map((e) => e['id'] as int).toList();
    });
    
    print('✅ Completed task IDs: $completedTaskIds');
  }

  Future<void> _loadUserCoins() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: [widget.userId],
    );
    
    if (result.isNotEmpty) {
      setState(() {
        userCoins = result.first['coins'] as int;
      });
    }
  }

  Future<void> _toggleTask(int taskId, bool isCompleted) async {
    print('🔄 Toggle başladı: taskId=$taskId, isCompleted=$isCompleted');
    
    try {
      final result = await DatabaseHelper.instance.toggleTaskCompletion(
        taskId, 
        widget.userId, 
        isCompleted
      );
            
      if (result['success']) {
    
        // ÖNCE UI GÜNCELLENİR
        setState(() {
          if (isCompleted) {
            if (!completedTaskIds.contains(taskId)) {
              completedTaskIds.add(taskId);
            }
          } else {
            completedTaskIds.remove(taskId);
          }
        });
        
        // Coin işlemleri
        int coinReward = result['coinReward'] as int;
        if (coinReward != 0) {
          setState(() {
            userCoins = result['newCoinTotal'] as int;
          });
          
          if (coinReward > 0) {
            CoinAnimationOverlay.showCoinDrop(context, coinReward);
            print('Coin ödülü verildi: +$coinReward');
          }
        }

        // ACHIEVEMENT KONTROLÜ EKLENDİ
        if (isCompleted) {
          await DatabaseHelper.instance.checkAndUnlockAchievements(widget.userId);
        }
        
        // Başarılar
        List<String> achievements = result['achievements'] as List<String>;
        if (achievements.isNotEmpty) {
          for (String achievement in achievements) {
            _showAchievementDialog(achievement);
          }
        }
        
      } else {
        print('DB işlemi başarısız: ${result['error']}');
      }
      
    } catch (e) {
      print('Toggle işlemi hatası: $e');
    }
    
    // SONRA DB'DEN YENİDEN YÜK ALINIR (güvenlik için)
    await _loadCompletedTasks();
    await _loadTasks();
    
    print('Toggle tamamlandı - Completed IDs: $completedTaskIds');
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // 🔧 Dışarıya tıklayınca kapanır
      builder: (BuildContext context) {
        return AddTaskDialog(
          userId: widget.userId,
          onTaskAdded: _loadTasks,
        );
      },
    );
  }


  List<Map<String, dynamic>> _sortTasks(List<Map<String, dynamic>> tasks) {
    final notCompleted = tasks.where((task) => 
      !completedTaskIds.contains(task['id'])
    ).toList();
    
    final completed = tasks.where((task) => 
      completedTaskIds.contains(task['id'])
    ).toList();
    
    return [...notCompleted, ...completed];
  }

  @override
  Widget build(BuildContext context) {
    final sortedOneTimeTasks = _sortTasks(oneTimeTasks);
    final sortedDailyTasks = _sortTasks(dailyTasks);

    return Scaffold(
      // Status bar'ı koyu yap
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Color(0xFF1A1A1A), // Üst bar ile aynı renk
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF1A1A1A), // Status bar rengi
            statusBarIconBrightness: Brightness.light, // İkonlar beyaz
            statusBarBrightness: Brightness.dark, // iOS için
          ),
        ),
      ),
      body: Stack( // Stack eklendi
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 46, 46, 46), // Tek renk
                ],
                stops: [1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 🎯 Üst Bar - Alt navigation ile aynı arka plan
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A), // Alt navigation ile aynı renk
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 2), // Aşağı doğru gölge
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => DialogUtils.showLogoutDialog(context),
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
                        
                        // 📝 TO DO LIST başlığı - Dinamik genişlik
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
                                'TO DO LIST',
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

                  // 🎯 Task Listesi - Canva tasarımına uygun
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          
                          // One-time tasks
                          ...sortedOneTimeTasks.map((task) => _buildTaskItem(
                            task['id'],
                            task['title'] ?? 'to do',
                            completedTaskIds.contains(task['id']),
                            false, // one-time task
                          )),
                          
                          // Ayırıcı - Canva'da görünen çizgi
                          if (sortedOneTimeTasks.isNotEmpty && sortedDailyTasks.isNotEmpty)
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 20),
                              height: 1,
                              color: Color(0xFF404040),
                            ),
                          
                          // Daily tasks
                          ...sortedDailyTasks.map((task) => _buildTaskItem(
                            task['id'],
                            task['title'] ?? 'daily',
                            completedTaskIds.contains(task['id']),
                            true, // daily task
                          )),
                          
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
            right: 0, // 🔧 Sağa tam bitişik
            bottom: 90, // 🔧 Alt barın hemen üstü
            child: GestureDetector(
              onTap: _showAddTaskDialog,
              child: Container(
                width: 70,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), // 🔧 Sadece sol üst köşe yuvarlak
                    bottomLeft: Radius.circular(30), // 🔧 Sadece sol alt köşe yuvarlak
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(-3, 0), // 🔧 Sola doğru gölge
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
              isActive: true,
              onTap: () {},
            ),
            // Daily butonu
            _buildNavButton(
              icon: Icons.assignment_outlined,
              color: Color(0xFF06B6D4),
              onTap: () => NavigationUtils.goToDaily(context, widget.userId),
            ),

            // Planning sayfası
              _buildNavButton(
                icon: Icons.schedule,
                color: Color(0xFF10B981),
                onTap: () => NavigationUtils.goToPlanning(context, widget.userId),
              ),
            _buildNavButton(
              icon: Icons.person_outline,
              color: Color(0xFFF59E0B),
              onTap: () => NavigationUtils.goToProfile(context, widget.userId),
            ),
            _buildNavButton(
              icon: Icons.trending_up,
              color: Color(0xFFEC4899),
              onTap: () => NavigationUtils.goToStatistics(context, widget.userId),
            ),
          ],
        ),
      ),
    );
  }

  // Task Item
  Widget _buildTaskItem(int taskId, String title, bool isCompleted, bool isDaily) {
    print('🎨 Task render: ID=$taskId, title=$title, completed=$isCompleted');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              print('👆 Task tıklandı: ID=$taskId, mevcut durum=$isCompleted');
              _toggleTask(taskId, !isCompleted);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Color(0xFF1A1A1A), size: 18)
                  : null,
            ),
          ),
          SizedBox(width: 16),
          
          // Task container
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Color(0xFF404040) 
                    : Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isCompleted ? null : [
                  BoxShadow(
                    color: Color(0xFF4F46E5).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ],
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

  // 🏆 Başarı dialog'u göster
  void _showAchievementDialog(String achievement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Yeni Başarı!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              achievement,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Harika! 🎊',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

class AddTaskDialog extends StatefulWidget {
  /*
 * Yeni görev ekleme dialog'u
 * - One-time görev oluşturma formu gösterir
 * - Başlık girişi ve coin ödülü seçimi sağlar
 * - Yeni görevi veritabanına kaydeder
 * - İşlem tamamlandığında ana sayfayı yeniler
 */
  final int userId;
  final VoidCallback onTaskAdded;

  const AddTaskDialog({
    Key? key,
    required this.userId,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  /*
 * AddTaskDialog'un State sınıfı
 * - Görev başlığı ve açıklama girişi için text controller'ları yönetir
 * - Coin ödülü seçimi için slider kontrolü sağlar
 * - Form validasyonu ve görev kaydetme işlemlerini gerçekleştirir
 * - Başarılı kayıt sonrası dialog'u kapatır ve ana sayfayı yeniler
 */
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _coinReward = 3.0;

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
            // Title Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF8B5CF6).withOpacity(0.2),
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
                  hintText: 'Task title...',
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
            
            // Description Input
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF8B5CF6).withOpacity(0.2),
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
                  hintText: 'Task description (optional)...',
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
            
            // Coin selection
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF59E0B).withOpacity(0.1),
                    Color(0xFFEC4899).withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFFF59E0B).withOpacity(0.3),
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
                        'Task Difficulty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        elevation: 4,
                      ),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: Color(0xFFF59E0B),
                      inactiveTrackColor: Color(0xFF404040),
                      thumbColor: Colors.white,
                      overlayColor: Color(0xFFF59E0B).withOpacity(0.2),
                      valueIndicatorColor: Color(0xFFF59E0B),
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
                          color: Color(0xFFF59E0B),
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
            
            SizedBox(height: 28),
            
            // Add Task Button
            GestureDetector(
              onTap: _addTask,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Add Task',
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

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    
    await db.insert('tasks', {
      'user_id': widget.userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'is_active': '1',
      'type': 'one_time',
      'coin_reward': _coinReward.round(),
    });

    widget.onTaskAdded();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
