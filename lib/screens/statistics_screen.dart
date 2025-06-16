// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:consistify/services/analytics_service.dart';
import 'package:consistify/utils/navigation_utils.dart';
import 'package:consistify/widgets/today_performance_card.dart';
import 'package:consistify/widgets/personality_type_card.dart';
import 'package:consistify/widgets/weekly_comparison_chart.dart';
import 'package:consistify/widgets/motivational_quote_card.dart';
import 'package:consistify/widgets/daily_analytics_card.dart';
import 'package:consistify/db/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;
  final Function? onRefreshNeeded;

  const StatisticsScreen({
    Key? key,
    required this.userId,
    this.onRefreshNeeded,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // Data holders
  Map<String, dynamic>? todayPerformance;
  Map<String, dynamic>? weeklyComparison;
  Map<String, dynamic>? motivationalContent;
  List<Map<String, dynamic>> dailyAnalytics = [];
  List<Map<String, dynamic>> monthlyTrends = [];
  List<Map<String, dynamic>> mostCompletedTasks = [];
  Map<String, dynamic> leastCompletedDailies = {};
  
  int userCoins = 0;
  bool isLoading = true;
  String selectedTimeFrame = 'week'; // week, month, all

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();

    WidgetsBinding.instance.addObserver(AppLifecycleObserver(
      onResume: () {
        if (mounted) {
          _loadAllAnalytics();
        }
      },
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(AppLifecycleObserver());
    super.dispose();
  }

  Future<void> _loadAllAnalytics() async {
    try {
      setState(() => isLoading = true);

      // Paralel olarak tüm verileri yükle
      final results = await Future.wait([
        _analyticsService.getTodayPerformanceAnalysis(widget.userId),
        _analyticsService.getWeeklyComparisonAnalysis(widget.userId),
        _analyticsService.getDailyAnalyticsWithGrades(widget.userId),
        _analyticsService.getMonthlyTrendsAnalysis(widget.userId),
        _analyticsService.getMostCompletedTasksAnalysis(widget.userId),
        _analyticsService.getLeastCompletedDailiesAnalysis(widget.userId), // 👈 Artık Map döndürüyor
        _loadUserCoins(),
      ]);

      // Motivational content'i completion rate'e göre oluştur
      final todayData = results[0] as Map<String, dynamic>;
      final completionRate = _safeDouble(todayData['completion_rate']);
      final motivational = _analyticsService.getMotivationalContent(completionRate);

      setState(() {
        todayPerformance = results[0] as Map<String, dynamic>;
        weeklyComparison = results[1] as Map<String, dynamic>;
        dailyAnalytics = results[2] as List<Map<String, dynamic>>;
        
        // Monthly trends için güvenli cast
        final monthlyData = results[3] as Map<String, dynamic>;
        monthlyTrends = (monthlyData['monthly_data'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
        
        mostCompletedTasks = results[4] as List<Map<String, dynamic>>;
        
        // ⚠️ Bu satırı değiştirin:
        leastCompletedDailies = results[5] as Map<String, dynamic>; // 👈 Map olarak cast
        
        motivationalContent = motivational;
        isLoading = false;
      });

    } catch (e) {
      print('❌ Analytics yükleme hatası: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics could not be loaded. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAllAnalytics,
            ),
          ),
        );
      }
    }
  }



  Future<int> _loadUserCoins() async {  // 👈 void yerine Future<int>
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'users',
        columns: ['coins'],
        where: 'id = ?',
        whereArgs: [widget.userId],
      );

      if (result.isNotEmpty) {
        final coins = result.first['coins'] as int? ?? 0;
        setState(() {
          userCoins = coins;
        });
        return coins;  // 👈 Coins'i return et
      }
      return 0;  // 👈 Default değer return et
    } catch (e) {
      print('❌ Coins yükleme hatası: $e');
      return 0;
    }
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
              _buildTopBar(),

              // İçerik alanı
              Expanded(
                child: isLoading 
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: _loadAllAnalytics,
                      color: Color(0xFF10B981),
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            
                            // 📊 BUGÜNKÜ PERFORMANS
                            if (todayPerformance != null)
                              TodayPerformanceCard(
                                todayStats: todayPerformance!,
                                onPerformanceDetailsTap: _showPerformanceDetails,
                              ),

                            // 🎯 MOTİVASYONEL QUOTE
                            if (motivationalContent != null)
                              MotivationalQuoteCard(
                                quote: motivationalContent!['quote'],
                                performanceLevel: motivationalContent!['performance_level'],
                              ),

                            // 🏆 KİŞİLİK TİPİ
                            if (todayPerformance != null)
                              PersonalityTypeCard(
                                personalityType: _getPersonalityType(
                                  _safeDouble(todayPerformance!['completion_rate'])
                                ),
                                completionRate: _safeDouble(todayPerformance!['completion_rate']),
                              ),

                            // 📈 HAFTALIK KARŞILAŞTIRMA
                            if (weeklyComparison != null)
                              WeeklyComparisonChart(
                                weeklyData: weeklyComparison!,
                              ),

                            // 📊 GÜNLÜK ANALİTİK
                            if (dailyAnalytics.isNotEmpty)
                              DailyAnalyticsCard(
                                dailyAnalytics: dailyAnalytics,
                              ),

                            // 🎯 EN ÇOK TAMAMLANAN GÖREVLER
                            if (mostCompletedTasks.isNotEmpty)
                              _buildMostCompletedTasksCard(),

                            // ⚠️ İYİLEŞTİRME GEREKTİREN GÖREVLER
                            if (leastCompletedDailies.isNotEmpty)
                              _buildImprovementNeededCard(),

                            // 📅 AYLIK TREND
                            if (monthlyTrends.isNotEmpty)
                              _buildMonthlyTrendsCard(),

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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopBar() {
    return Container(
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
          
          // STATISTICS başlığı
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEC4899).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'STATISTICS',
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFEC4899),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Analyzing your performance...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostCompletedTasksCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Most Completed Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...mostCompletedTasks.take(3).map((task) => _buildTaskItem(
            task,
            Color(0xFF10B981),
            true,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildImprovementNeededCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFEF4444).withOpacity(0.3),
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
                  color: Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Needs Improvement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Burada boş durum kontrolü yapılıyor
          (leastCompletedDailies['needs_improvement'] as List<Map<String, dynamic>>? ?? []).isEmpty
            ? Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All your tasks are in good shape!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: (leastCompletedDailies['needs_improvement'] as List<Map<String, dynamic>>)
                  .take(3)
                  .map((daily) => _buildTaskItem(
                    daily,
                    Color(0xFFEF4444),
                    false,
                  ))
                  .toList(),
              ),
        ],
      ),
    );
  }


  Widget _buildTaskItem(Map<String, dynamic> task, Color color, bool isPositive) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              isPositive ? '🏆' : '⚠️',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? 'Unknown Task',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task['suggestion'] != null)
                  Text(
                    task['suggestion'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            isPositive 
              ? '${task['completion_count']}x'
              : '${_safeDouble(task['completion_rate']).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF8B5CF6).withOpacity(0.3),
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
                  color: Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Monthly Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...monthlyTrends.take(3).map((month) => _buildMonthItem(month)).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthItem(Map<String, dynamic> month) {
    final completionRate = _safeDouble(month['avg_completion_rate']);
    final grade = month['performance_grade'] as String;
    final color = _getGradeColor(grade);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month['month_formatted'] ?? 'Unknown Month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${month['total_completed']} tasks completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${completionRate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
            onTap: () {}, // Mevcut sayfa
            isActive: true,
          ),
        ],
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

  // Performance details modal
  void _showPerformanceDetails() {
    if (todayPerformance == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Performance Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Detailed stats burada gösterilebilir
                    Text(
                      'Detailed performance analysis will be shown here.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getPersonalityType(double completionRate) {
    if (completionRate >= 90) return '🏆 Görev Makinesi';
    if (completionRate >= 80) return '⚡ Süper Verimli';
    if (completionRate >= 70) return '🎯 Hedef Odaklı';
    if (completionRate >= 60) return '📈 Gelişen Kahraman';
    if (completionRate >= 50) return '🌱 Büyüyen Tohum';
    return '💪 Potansiyel Dolu';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Color(0xFF10B981);
      case 'A-':
      case 'B+':
        return Color(0xFF06B6D4);
      case 'B':
      case 'B-':
        return Color(0xFFF59E0B);
      case 'C+':
      case 'C':
        return Color(0xFFEF4444);
      default:
        return Color(0xFF6B7280);
    }
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}


class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResume;
  
  AppLifecycleObserver({this.onResume});
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && onResume != null) {
      onResume!();
    }
  }
}

