// // lib/screens/statistics_screen.dart
// import 'package:flutter/material.dart';
// import 'package:sayfa_yonlendirme/services/analytics_service.dart';
// import 'package:sayfa_yonlendirme/widgets/colored_progress_ring.dart';

// class StatisticsScreen extends StatefulWidget {
//   final int userId;

//   const StatisticsScreen({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   State<StatisticsScreen> createState() => _StatisticsScreenState();
// }

// class _StatisticsScreenState extends State<StatisticsScreen>
//     with SingleTickerProviderStateMixin {
//   final AnalyticsService _analyticsService = AnalyticsService();
//   late TabController _tabController;
  
//   bool _isLoading = true;
//   Map<String, dynamic> _todayPerformance = {};
//   Map<String, dynamic> _motivationalContent = {};
//   List<Map<String, dynamic>> _dailyAnalytics = [];
//   Map<String, dynamic> _weeklyComparison = {};
//   List<Map<String, dynamic>> _mostCompletedTasks = [];
//   List<Map<String, dynamic>> _leastCompletedDailies = [];
//   Map<String, dynamic> _monthlyTrends = {};

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadAllAnalytics();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   // GÜVENLİ TİP DÖNÜŞÜM FONKSİYONLARI
//   int _safeInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is double) return value.toInt();
//     if (value is String) {
//       final parsed = int.tryParse(value);
//       return parsed ?? 0;
//     }
//     return 0;
//   }

//   double _safeDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       final parsed = double.tryParse(value);
//       return parsed ?? 0.0;
//     }
//     return 0.0;
//   }

//   String _safeString(dynamic value) {
//     if (value == null) return '';
//     return value.toString();
//   }

//   // 🛡️ VERİ İŞLEME FONKSİYONLARI
//   Map<String, dynamic> _processTodayPerformance(Map<String, dynamic> data) {
//     return {
//       'total_tasks': _safeInt(data['total_tasks']),
//       'completed_tasks': _safeInt(data['completed_tasks']),
//       'completion_rate': _safeDouble(data['completion_rate']),
//       'performance_grade': _safeString(data['performance_grade']),
//       'performance_emoji': _safeString(data['performance_emoji']),
//       'performance_color': _safeInt(data['performance_color']),
//       'coins_earned': _safeInt(data['coins_earned']),
//       'first_task_time': data['first_task_time'],
//       'last_task_time': data['last_task_time'],
//       'active_duration': _safeInt(data['active_duration']),
//       'avg_task_duration': _safeInt(data['avg_task_duration']),
//       'category_performance': data['category_performance'] ?? [],
//     };
//   }

//   List<Map<String, dynamic>> _processDailyAnalytics(List<Map<String, dynamic>> data) {
//     return data.map((item) {
//       return {
//         'date': _safeString(item['date']),
//         'date_formatted': _safeString(item['date_formatted']),
//         'completion_rate': _safeDouble(item['completion_rate']),
//         'performance_grade': _safeString(item['performance_grade']),
//         'grade_color': _safeInt(item['grade_color']),
//         'streak_count': _safeInt(item['streak_count']),
//       };
//     }).toList();
//   }

//   Map<String, dynamic> _processWeeklyComparison(Map<String, dynamic> data) {
//     final thisWeek = data['this_week'] as Map<String, dynamic>? ?? {};
//     final lastWeek = data['last_week'] as Map<String, dynamic>? ?? {};
//     final improvements = data['improvements'] as Map<String, dynamic>? ?? {};
    
//     return {
//       'this_week': {
//         'completed_tasks': _safeInt(thisWeek['completed_tasks']),
//         'avg_completion_rate': _safeDouble(thisWeek['avg_completion_rate']),
//         'performance_grade': _safeString(thisWeek['performance_grade']),
//         'grade_color': _safeInt(thisWeek['grade_color']),
//         'coins_earned': _safeInt(thisWeek['coins_earned']),
//       },
//       'last_week': {
//         'completed_tasks': _safeInt(lastWeek['completed_tasks']),
//         'avg_completion_rate': _safeDouble(lastWeek['avg_completion_rate']),
//         'performance_grade': _safeString(lastWeek['performance_grade']),
//         'grade_color': _safeInt(lastWeek['grade_color']),
//         'coins_earned': _safeInt(lastWeek['coins_earned']),
//       },
//       'improvements': {
//         'task_change': _safeInt(improvements['task_change']),
//         'coin_change': _safeInt(improvements['coin_change']),
//         'rate_change': _safeDouble(improvements['rate_change']),
//         'is_improving': improvements['is_improving'] ?? false,
//       }
//     };
//   }

//   List<Map<String, dynamic>> _processMostCompletedTasks(List<Map<String, dynamic>> data) {
//     return data.map((item) {
//       return {
//         'title': _safeString(item['title']),
//         'completion_count': _safeInt(item['completion_count']),
//         'task_emoji': _safeString(item['task_emoji']),
//       };
//     }).toList();
//   }

//   List<Map<String, dynamic>> _processLeastCompletedDailies(List<Map<String, dynamic>> data) {
//     return data.map((item) {
//       return {
//         'title': _safeString(item['title']),
//         'completion_rate': _safeDouble(item['completion_rate']),
//         'suggestion': _safeString(item['suggestion']),
//       };
//     }).toList();
//   }

//   Map<String, dynamic> _processMonthlyTrends(Map<String, dynamic> data) {
//     final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];
    
//     return {
//       'overall_trend': _safeString(data['overall_trend']),
//       'monthly_data': monthlyData.map((item) {
//         final monthMap = item as Map<String, dynamic>? ?? {};
//         return {
//           'month_formatted': _safeString(monthMap['month_formatted']),
//           'avg_completion_rate': _safeDouble(monthMap['avg_completion_rate']),
//           'performance_grade': _safeString(monthMap['performance_grade']),
//           'grade_color': _safeInt(monthMap['grade_color']),
//           'total_completed': _safeInt(monthMap['total_completed']),
//         };
//       }).toList(),
//     };
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         action: SnackBarAction(
//           label: 'Tekrar Dene',
//           textColor: Colors.white,
//           onPressed: _loadAllAnalytics,
//         ),
//       ),
//     );
//   }

//   Future<void> _loadAllAnalytics() async {
//     setState(() => _isLoading = true);
    
//     try {
//       // Her bir servisi ayrı ayrı çağırarak hata yakalayalım
//       Map<String, dynamic> todayData = {};
//       List<Map<String, dynamic>> dailyData = [];
//       Map<String, dynamic> weeklyData = {};
//       List<Map<String, dynamic>> mostCompletedData = [];
//       List<Map<String, dynamic>> leastCompletedData = [];
//       Map<String, dynamic> monthlyData = {};
      
//       try {
//         todayData = await _analyticsService.getTodayPerformanceAnalysis(widget.userId);
//         print('✅ Today Performance yüklendi');
//       } catch (e) {
//         print('❌ Today Performance yükleme hatası: $e');
//         todayData = {};
//       }
      
//       try {
//         dailyData = await _analyticsService.getDailyAnalyticsWithGrades(widget.userId);
//         print('✅ Daily Analytics yüklendi');
//       } catch (e) {
//         print('❌ Daily Analytics yükleme hatası: $e');
//         dailyData = [];
//       }
      
//       try {
//         weeklyData = await _analyticsService.getWeeklyComparisonAnalysis(widget.userId);
//         print('✅ Weekly Comparison yüklendi');
//       } catch (e) {
//         print('❌ Weekly Comparison yükleme hatası: $e');
//         weeklyData = {};
//       }
      
//       try {
//         mostCompletedData = await _analyticsService.getMostCompletedTasksAnalysis(widget.userId);
//         print('✅ Most Completed Tasks yüklendi');
//       } catch (e) {
//         print('❌ Most Completed Tasks yükleme hatası: $e');
//         mostCompletedData = [];
//       }
      
//       try {
//         leastCompletedData = await _analyticsService.getLeastCompletedDailiesAnalysis(widget.userId);
//         print('✅ Least Completed Dailies yüklendi');
//       } catch (e) {
//         print('❌ Least Completed Dailies yükleme hatası: $e');
//         leastCompletedData = [];
//       }
      
//       try {
//         monthlyData = await _analyticsService.getMonthlyTrendsAnalysis(widget.userId);
//         print('✅ Monthly Trends yüklendi');
//       } catch (e) {
//         print('❌ Monthly Trends yükleme hatası: $e');
//         monthlyData = {};
//       }
      
//       setState(() {
//         _todayPerformance = _processTodayPerformance(todayData);
//         _dailyAnalytics = _processDailyAnalytics(dailyData);
//         _weeklyComparison = _processWeeklyComparison(weeklyData);
//         _mostCompletedTasks = _processMostCompletedTasks(mostCompletedData);
//         _leastCompletedDailies = _processLeastCompletedDailies(leastCompletedData);
//         _monthlyTrends = _processMonthlyTrends(monthlyData);
        
//         // Motivational content'i today performance'a göre oluştur
//         final completionRate = _safeDouble(_todayPerformance['completion_rate']);
//         _motivationalContent = _analyticsService.getMotivationalContent(completionRate);
        
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('📊 Analytics yükleme genel hatası: $e');
//       setState(() => _isLoading = false);
//       _showErrorSnackBar('Veriler yüklenirken hata oluştu: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('İstatistiklerim'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Günlük'),
//             Tab(text: 'Haftalık'),
//             Tab(text: 'Aylık'),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildDailyTab(),
//                 _buildWeeklyTab(),
//                 _buildMonthlyTab(),
//               ],
//             ),
//     );
//   }

//   Widget _buildDailyTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildTodayPerformanceCard(),
//           const SizedBox(height: 16),
//           _buildMotivationalCard(),
//           const SizedBox(height: 16),
//           _buildDailyAnalyticsCard(),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeeklyTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildWeeklyComparisonCard(),
//           const SizedBox(height: 16),
//           _buildMostCompletedTasksCard(),
//           const SizedBox(height: 16),
//           _buildLeastCompletedDailiesCard(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMonthlyTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildMonthlyTrendsCard(),
//         ],
//       ),
//     );
//   }

//   // Kart widget'ları burada yer alacak
//   Widget _buildTodayPerformanceCard() {
//     final completionRate = _safeDouble(_todayPerformance['completion_rate']);
//     final completedTasks = _safeInt(_todayPerformance['completed_tasks']);
//     final totalTasks = _safeInt(_todayPerformance['total_tasks']);
//     final grade = _safeString(_todayPerformance['performance_grade']);
//     final emoji = _safeString(_todayPerformance['performance_emoji']);
//     final color = _safeInt(_todayPerformance['performance_color']);
    
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Bugünkü Performans',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   '$emoji $grade',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(color),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ColoredProgressRing(
//                   progress: completionRate / 100,
//                   color: Color(color),
//                   size: 100,  // radius'un 50 olduğunu düşünerek size'ı 100 olarak ayarladım
//                   strokeWidth: 10,  // lineWidth yerine strokeWidth kullanılıyor
//                   centerText: '${completionRate.toStringAsFixed(0)}%',
//                   centerSubText: 'Tamamlama',
//                   animate: true,
//                 ),

//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildStatRow('Tamamlanan', '$completedTasks/$totalTasks'),
//                     const SizedBox(height: 8),
//                     _buildStatRow(
//                       'Kazanılan Puan',
//                       '${_safeInt(_todayPerformance['coins_earned'])} 🪙',
//                     ),
//                     const SizedBox(height: 8),
//                     _buildStatRow(
//                       'Aktif Süre',
//                       '${_formatDuration(_safeInt(_todayPerformance['active_duration']))}',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMotivationalCard() {
//     final quote = _safeString(_motivationalContent['quote']);
//     final emoji = _safeString(_motivationalContent['motivation_emoji']);
//     final color = _safeInt(_motivationalContent['motivation_color']);
    
//     return Card(
//       elevation: 4,
//       color: Color(color).withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Color(color), width: 1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Text(
//               emoji,
//               style: const TextStyle(fontSize: 40),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 quote,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontStyle: FontStyle.italic,
//                   color: Color(color),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDailyAnalyticsCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Son 7 Gün',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _dailyAnalytics.isEmpty
//                 ? const Center(
//                     child: Text('Henüz veri bulunmuyor'),
//                   )
//                 : Column(
//                     children: _dailyAnalytics.map((day) {
//                       final date = _safeString(day['date_formatted']);
//                       final completionRate = _safeDouble(day['completion_rate']);
//                       final grade = _safeString(day['performance_grade']);
//                       final color = _safeInt(day['grade_color']);
                      
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: 2,
//                               child: Text(date),
//                             ),
//                             Expanded(
//                               flex: 5,
//                               child: LinearProgressIndicator(
//                                 value: completionRate / 100,
//                                 backgroundColor: Colors.grey[200],
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Color(color),
//                                 ),
//                                 minHeight: 10,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               '${completionRate.toStringAsFixed(0)}%',
//                               style: const TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(width: 8),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Color(color),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 grade,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWeeklyComparisonCard() {
//     final thisWeek = _weeklyComparison['this_week'] as Map<String, dynamic>? ?? {};
//     final lastWeek = _weeklyComparison['last_week'] as Map<String, dynamic>? ?? {};
//     final improvements = _weeklyComparison['improvements'] as Map<String, dynamic>? ?? {};
    
//     final thisWeekRate = _safeDouble(thisWeek['avg_completion_rate']);
//     final lastWeekRate = _safeDouble(lastWeek['avg_completion_rate']);
//     final thisWeekGrade = _safeString(thisWeek['performance_grade']);
//     final lastWeekGrade = _safeString(lastWeek['performance_grade']);
//     final thisWeekColor = _safeInt(thisWeek['grade_color']);
//     final lastWeekColor = _safeInt(lastWeek['grade_color']);
    
//     final taskChange = _safeInt(improvements['task_change']);
//     final coinChange = _safeInt(improvements['coin_change']);
//     final rateChange = _safeDouble(improvements['rate_change']);
//     final isImproving = improvements['is_improving'] ?? false;
    
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Haftalık Karşılaştırma',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildWeeklyComparisonColumn(
//                     'Bu Hafta',
//                     thisWeekRate,
//                     thisWeekGrade,
//                     thisWeekColor,
//                     _safeInt(thisWeek['completed_tasks']),
//                     _safeInt(thisWeek['coins_earned']),
//                   ),
//                 ),
//                 Container(
//                   height: 100,
//                   width: 1,
//                   color: Colors.grey[300],
//                 ),
//                 Expanded(
//                   child: _buildWeeklyComparisonColumn(
//                     'Geçen Hafta',
//                     lastWeekRate,
//                     lastWeekGrade,
//                     lastWeekColor,
//                     _safeInt(lastWeek['completed_tasks']),
//                     _safeInt(lastWeek['coins_earned']),
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   isImproving ? '📈 İlerleme Var' : '📉 Düşüş Var',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: isImproving ? Colors.green : Colors.red,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             _buildImprovementRow(
//               'Görev Tamamlama',
//               taskChange,
//               '${taskChange > 0 ? '+' : ''}$taskChange görev',
//             ),
//             _buildImprovementRow(
//               'Puan Kazanma',
//               coinChange,
//               '${coinChange > 0 ? '+' : ''}$coinChange puan',
//             ),
//             _buildImprovementRow(
//               'Tamamlama Oranı',
//               rateChange.toInt(),
//               '${rateChange > 0 ? '+' : ''}${rateChange.toStringAsFixed(1)}%',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWeeklyComparisonColumn(
//     String title,
//     double rate,
//     String grade,
//     int color,
//     int tasks,
//     int coins,
//   ) {
//     return Column(
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Color(color).withOpacity(0.2),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 grade,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Color(color),
//                 ),
//               ),
//               Text(
//                 '${rate.toStringAsFixed(0)}%',
//                 style: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text('$tasks görev'),
//         Text('$coins puan'),
//       ],
//     );
//   }

//   Widget _buildImprovementRow(String label, int change, String changeText) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Row(
//             children: [
//               Icon(
//                 change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
//                 color: change >= 0 ? Colors.green : Colors.red,
//                 size: 16,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 changeText,
//                 style: TextStyle(
//                   color: change >= 0 ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMostCompletedTasksCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'En Çok Tamamlanan Görevler',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _mostCompletedTasks.isEmpty
//                 ? const Center(
//                     child: Text('Henüz veri bulunmuyor'),
//                   )
//                 : Column(
//                     children: _mostCompletedTasks.map((task) {
//                       final title = _safeString(task['title']);
//                       final count = _safeInt(task['completion_count']);
//                       final emoji = _safeString(task['task_emoji']);
                      
//                       return ListTile(
//                         leading: Text(
//                           emoji,
//                           style: const TextStyle(fontSize: 24),
//                         ),
//                         title: Text(title),
//                         trailing: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.blue,
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Text(
//                             '$count kez',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLeastCompletedDailiesCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Geliştirilebilecek Günlük Görevler',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _leastCompletedDailies.isEmpty
//                 ? const Center(
//                     child: Text('Henüz veri bulunmuyor'),
//                   )
//                 : Column(
//                     children: _leastCompletedDailies.map((daily) {
//                       final title = _safeString(daily['title']);
//                       final rate = _safeDouble(daily['completion_rate']);
//                       final suggestion = _safeString(daily['suggestion']);
                      
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     title,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                                 Text(
//                                   '${rate.toStringAsFixed(0)}%',
//                                   style: TextStyle(
//                                     color: rate < 50 ? Colors.red : Colors.orange,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             LinearProgressIndicator(
//                               value: rate / 100,
//                               backgroundColor: Colors.grey[200],
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 rate < 50 ? Colors.red : Colors.orange,
//                               ),
//                               minHeight: 8,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               suggestion,
//                               style: const TextStyle(
//                                 fontStyle: FontStyle.italic,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMonthlyTrendsCard() {
//     final monthlyData = _monthlyTrends['monthly_data'] as List<dynamic>? ?? [];
//     final overallTrend = _safeString(_monthlyTrends['overall_trend']);
    
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Aylık Performans Trendi',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 _buildTrendIndicator(overallTrend),
//               ],
//             ),
//             const SizedBox(height: 16),
//             monthlyData.isEmpty
//                 ? const Center(
//                     child: Text('Henüz veri bulunmuyor'),
//                   )
//                 : Column(
//                     children: List.generate(monthlyData.length, (index) {
//                       final month = monthlyData[index] as Map<String, dynamic>? ?? {};
//                       final monthFormatted = _safeString(month['month_formatted']);
//                       final rate = _safeDouble(month['avg_completion_rate']);
//                       final grade = _safeString(month['performance_grade']);
//                       final color = _safeInt(month['grade_color']);
//                       final totalCompleted = _safeInt(month['total_completed']);
                      
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   monthFormatted,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Row(
//                                   children: [
//                                     Text(
//                                       '${rate.toStringAsFixed(0)}% ',
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 4,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Color(color),
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                       child: Text(
//                                         grade,
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             LinearProgressIndicator(
//                               value: rate / 100,
//                               backgroundColor: Colors.grey[200],
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 Color(color),
//                               ),
//                               minHeight: 10,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               'Toplam $totalCompleted görev tamamlandı',
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendIndicator(String trend) {
//     IconData icon;
//     Color color;
//     String text;
    
//     switch (trend) {
//       case 'improving':
//         icon = Icons.trending_up;
//         color = Colors.green;
//         text = 'Yükseliyor';
//         break;
//       case 'declining':
//         icon = Icons.trending_down;
//         color = Colors.red;
//         text = 'Düşüyor';
//         break;
//       default:
//         icon = Icons.trending_flat;
//         color = Colors.blue;
//         text = 'Sabit';
//     }
    
//     return Row(
//       children: [
//         Icon(icon, color: color, size: 16),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey[600],
//           ),
//         ),
//         Text(
//           value,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(int minutes) {
//     if (minutes < 60) {
//       return '$minutes dk';
//     } else {
//       final hours = minutes ~/ 60;
//       final remainingMinutes = minutes % 60;
//       return '$hours sa ${remainingMinutes > 0 ? '$remainingMinutes dk' : ''}';
//     }
//   }
// }
