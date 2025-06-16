import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:consistify/db/database_helper.dart';
import 'package:consistify/utils/navigation_utils.dart';

class WeeklySummaryScreen extends StatefulWidget {
  final int userId;
  
  const WeeklySummaryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  Map<String, dynamic>? weeklyStats;
  List<Map<String, dynamic>> dailyBreakdown = [];
  List<Map<String, dynamic>> achievements = [];
  int userCoins = 0;
  bool isLoading = true;

  DateTime selectedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWeeklySummary();
  }

  Future<void> _loadWeeklySummary() async {
    try {
      setState(() => isLoading = true);
      
      // Haftalık istatistikleri yükle
      final weekly = await DatabaseHelper.instance.getWeeklyStats(widget.userId);
      
      // Günlük breakdown'ı yükle
      final daily = await _getDailyBreakdown();
      
      // Bu haftaki başarımları yükle
      final weeklyAchievements = await _getWeeklyAchievements();
      
      // Kullanıcı coin'lerini yükle
      await _loadUserCoins();
      
      setState(() {
        weeklyStats = weekly;
        dailyBreakdown = daily;
        achievements = weeklyAchievements;
        isLoading = false;
      });
      
    } catch (e) {
      print('❌ Haftalık özet yükleme hatası: $e');
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getDailyBreakdown() async {
    final db = await DatabaseHelper.instance.database;
    
    // ✅ YENİ KOD - selectedWeek yerine DateTime.now() kullan
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
    
    String startDate = startOfWeek.toIso8601String().split('T')[0];
    String endDate = endOfWeek.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_tasks,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_tasks,
        SUM(CASE WHEN is_completed = 1 THEN coin_reward ELSE 0 END) as coins_earned
      FROM tasks  -- ✅ DÜZELTİLDİ: todos → tasks
      WHERE user_id = ? AND DATE(created_at) BETWEEN ? AND ?
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [widget.userId, startDate, endDate]);
    
    // Eksik günleri ekle (0 görev ile)
    List<Map<String, dynamic>> fullWeek = [];
    for (int i = 0; i < 7; i++) {
      DateTime currentDay = startOfWeek.add(Duration(days: i));
      String currentDate = currentDay.toIso8601String().split('T')[0];
      
      var dayData = result.firstWhere(
        (day) => day['date'] == currentDate,
        orElse: () => {
          'date': currentDate,
          'total_tasks': 0,
          'completed_tasks': 0,
          'coins_earned': 0,
        },
      );
      
      fullWeek.add({
        ...dayData,
        'day_name': _getDayName(currentDay.weekday),
        'day_number': currentDay.day,
      });
    }
    
    return fullWeek;
  }

  Future<List<Map<String, dynamic>>> _getWeeklyAchievements() async {
    final db = await DatabaseHelper.instance.database;
      
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    String startDate = startOfWeek.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        a.title,
        a.description,
        a.icon,
        a.coin_reward,
        ua.earned_at
      FROM user_achievements ua
      JOIN achievements a ON ua.achievement_id = a.id
      WHERE ua.user_id = ? AND DATE(ua.earned_at) >= ?
      ORDER BY ua.earned_at DESC
      LIMIT 5
    ''', [widget.userId, startDate]);
    
    return result;
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
        userCoins = result.first['coins'] as int? ?? 0;
      });
    }
  }

  String _getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Status bar ayarları
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
              // ÜST BAR
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
                    // Geri dön butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF404040),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    // WEEKLY SUMMARY başlığı
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'WEEKLY SUMMARY',
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
                    
                    // Coin
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
                  ],
                ),
              ),

              // İçerik alanı
              Expanded(
                child: isLoading 
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWeeklySummary,
                      color: Color(0xFF10B981),
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📊 HAFTALIK ÖZET KARTI
                            _buildWeeklySummaryCard(),
                            SizedBox(height: 20),
                            
                            // 📅 GÜNLÜK BREAKDOWN
                            _buildDailyBreakdownCard(),
                            SizedBox(height: 20),
                            
                            // 🏆 BU HAFTAKI BAŞARIMLAR
                            if (achievements.isNotEmpty) ...[
                              _buildAchievementsCard(),
                              SizedBox(height: 20),
                            ],
                            
                            // 🎯 HAFTALIK HEDEFLER
                            _buildWeeklyGoalsCard(),
                            
                            // Alt boşluk
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),

      // ALT NAVIGATION BAR
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
              onTap: () => NavigationUtils.goToTodo(context, widget.userId),
            ),
            _buildNavButton(
              icon: Icons.assignment_outlined,
              color: Color(0xFF06B6D4),
              onTap: () => NavigationUtils.goToDaily(context, widget.userId),
            ),
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

  Widget _buildWeeklySummaryCard() {
    if (weeklyStats == null) return SizedBox();
    
    double completionRate = weeklyStats!['completion_rate'] ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '📊',
            style: TextStyle(fontSize: 40),
          ),
          SizedBox(height: 12),
          Text(
            'Bu Hafta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                '${weeklyStats!['completed_tasks']}',
                'Tamamlanan',
                '✅',
              ),
              _buildSummaryItem(
                '${(completionRate * 100).toStringAsFixed(0)}%',
                'Başarı Oranı',
                '🎯',
              ),
              _buildSummaryItem(
                '${weeklyStats!['total_coins']}',
                'Coin',
                '🪙',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreakdownCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_view_week,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Günlük Detay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...dailyBreakdown.map((day) => _buildDayItem(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day) {
    int completed = day['completed_tasks'] ?? 0;
    int total = day['total_tasks'] ?? 0;
    int coins = day['coins_earned'] ?? 0;
    double progress = total > 0 ? completed / total : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF404040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progress == 1.0 ? Color(0xFF10B981) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Gün adı
          Container(
            width: 50,
            child: Column(
              children: [
                Text(
                  day['day_name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${day['day_number']}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16),
          
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completed/$total görev',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (coins > 0)
                      Text(
                        '$coins 🪙',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Color(0xFF10B981) : Color(0xFF06B6D4),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16),
          
          // Başarı ikonu
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: progress == 1.0 ? Color(0xFF10B981) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: progress == 1.0 ? Color(0xFF10B981) : Colors.white30,
                width: 2,
              ),
            ),
            child: progress == 1.0 
              ? Icon(Icons.check, color: Colors.white, size: 18)
              : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Bu Haftaki Başarımlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...achievements.take(3).map((achievement) => 
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF404040),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    achievement['icon'] ?? '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          achievement['description'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${achievement['coin_reward']} 🪙',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎯',
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(height: 12),
          Text(
            'Gelecek Hafta Hedefi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getWeeklyGoalMessage(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getWeeklyGoalMessage() {
    if (weeklyStats == null) return 'Yeni hedefler belirleniyor...';
    
    double completionRate = weeklyStats!['completion_rate'] ?? 0.0;
    int completedTasks = weeklyStats!['completed_tasks'] ?? 0;
    
    if (completionRate >= 0.9) {
      return 'Mükemmel performans! Gelecek hafta ${completedTasks + 5} görev hedefleyelim! 🚀';
    } else if (completionRate >= 0.7) {
      return 'Harika gidiyorsun! Gelecek hafta %90 başarı oranını hedefleyelim! 💪';
    } else if (completionRate >= 0.5) {
      return 'İyi bir başlangıç! Gelecek hafta ${(completedTasks * 1.5).round()} görev tamamlayalım! 📈';
    } else {
      return 'Her yeni hafta yeni bir fırsat! Bu hafta daha düzenli olalım! ✨';
    }
  }



  
}
