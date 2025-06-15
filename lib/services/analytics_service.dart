// lib/services/analytics_service.dart
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class AnalyticsService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Today's Performance Analysis
  Future<Map<String, dynamic>> getTodayPerformanceAnalysis(int userId) async {
    try {
      final todayStats = await _databaseHelper.getTodayTaskStats(userId);
      
      // Null kontrolü
      if (todayStats.isEmpty) {
        return {
          'total_tasks': 0,
          'completed_tasks': 0,
          'completion_rate': 0.0,
          'performance_grade': 'F',
          'performance_level': 'low_performance',
          'performance_color': _getGradeColor('F'),
          'performance_emoji': _getPerformanceEmoji('F'),
          'coins_earned': 0,
          'active_duration': 0,
          'avg_task_duration': 0,
          'category_performance': [],
        };
      }
      
      // Güvenli tip dönüşümü
      final completionRate = _safeDouble(todayStats['completion_rate']);
      final performanceGrade = _calculatePerformanceGrade(completionRate);
      final performanceLevel = _getPerformanceLevel(completionRate);
      
      return {
        ...todayStats,
        'performance_grade': performanceGrade,
        'performance_level': performanceLevel,
        'performance_color': _getGradeColor(performanceGrade),
        'performance_emoji': _getPerformanceEmoji(performanceGrade),
      };
    } catch (e) {
      print('❌ getTodayPerformanceAnalysis hatası: $e');
      return {
        'total_tasks': 0,
        'completed_tasks': 0,
        'completion_rate': 0.0,
        'performance_grade': 'F',
        'performance_level': 'low_performance',
        'performance_color': _getGradeColor('F'),
        'performance_emoji': _getPerformanceEmoji('F'),
        'coins_earned': 0,
        'active_duration': 0,
        'avg_task_duration': 0,
        'category_performance': [],
      };
    }
  }

  // Daily Analytics with Performance Grades (Son 7 gün)
  // lib/services/analytics_service.dart içinde

  Future<List<Map<String, dynamic>>> getDailyAnalyticsWithGrades(int userId) async {
    try {
      final db = await _databaseHelper.database;
      
      // Daily template ve task ilişkisini kullanarak analiz et
      final result = await db.rawQuery('''
        SELECT 
          dt.title,
          dt.id,
          COUNT(t.id) as total_generated,
          SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) as completed_count,
          ROUND(
            (SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) * 100.0) / 
            NULLIF(COUNT(t.id), 0), 
            2
          ) as completion_rate
        FROM daily_templates dt
        LEFT JOIN tasks t ON dt.id = t.daily_template_id
        WHERE dt.user_id = ? 
          AND t.created_at >= date('now', '-30 days')
        GROUP BY dt.id, dt.title
        HAVING COUNT(t.id) > 0
        ORDER BY completion_rate DESC
      ''', [userId]);

      return result.map((row) {
        final completionRate = _safeDouble(row['completion_rate']);
        final grade = _calculateGrade(completionRate);
        
        return {
          'title': row['title']?.toString() ?? 'Unknown Task',
          'total_generated': _safeInt(row['total_generated']),
          'completed_count': _safeInt(row['completed_count']),
          'completion_rate': completionRate,
          'performance_grade': grade,
        };
      }).toList();
      
    } catch (e) {
      print('❌ getDailyAnalyticsWithGrades hatası: $e');
      return [];
    }
  }


  // Helper methods (eğer yoksa ekleyin)
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _calculateGrade(double completionRate) {
    if (completionRate >= 95) return 'A+';
    if (completionRate >= 90) return 'A';
    if (completionRate >= 85) return 'A-';
    if (completionRate >= 80) return 'B+';
    if (completionRate >= 75) return 'B';
    if (completionRate >= 70) return 'B-';
    if (completionRate >= 65) return 'C+';
    if (completionRate >= 60) return 'C';
    if (completionRate >= 50) return 'C-';
    return 'F';
  }


  // Weekly Comparison Analysis
  Future<Map<String, dynamic>> getWeeklyComparisonAnalysis(int userId) async {
    try {
      final weeklyComparison = await _databaseHelper.getWeeklyComparison(userId);
      
      // Null kontrolü
      if (weeklyComparison.isEmpty) {
        return _getEmptyWeeklyComparison();
      }
      
      final thisWeek = weeklyComparison['this_week'] as Map<String, dynamic>? ?? {};
      final lastWeek = weeklyComparison['last_week'] as Map<String, dynamic>? ?? {};
      final improvements = weeklyComparison['improvements'] as Map<String, dynamic>? ?? {};
      
      // Güvenli tip dönüşümü
      final thisWeekRate = _safeDouble(thisWeek['avg_completion_rate']);
      final lastWeekRate = _safeDouble(lastWeek['avg_completion_rate']);
      final thisWeekGrade = _calculatePerformanceGrade(thisWeekRate);
      final lastWeekGrade = _calculatePerformanceGrade(lastWeekRate);
      
      // rate_change değerini önceden double'a çevirelim
      final rateChange = _safeDouble(improvements['rate_change']);
      
      return {
        'this_week': {
          ...thisWeek,
          'performance_grade': thisWeekGrade,
          'grade_color': _getGradeColor(thisWeekGrade),
        },
        'last_week': {
          ...lastWeek,
          'performance_grade': lastWeekGrade,
          'grade_color': _getGradeColor(lastWeekGrade),
        },
        'improvements': {
          ...improvements,
          'improvement_level': _getImprovementLevel(
            _safeInt(improvements['task_change']), 
            _safeInt(improvements['coin_change']), 
            rateChange  // Önceden dönüştürülmüş değeri kullan
          ),
          'improvement_emoji': _getImprovementEmoji(improvements['is_improving'] ?? false),
        }
      };
    } catch (e) {
      print('❌ getWeeklyComparisonAnalysis hatası: $e');
      return _getEmptyWeeklyComparison();
    }
  }


  // Boş haftalık karşılaştırma verisi
  Map<String, dynamic> _getEmptyWeeklyComparison() {
    return {
      'this_week': {
        'completed_tasks': 0,
        'avg_completion_rate': 0.0,
        'performance_grade': 'F',
        'grade_color': _getGradeColor('F'),
        'coins_earned': 0,
      },
      'last_week': {
        'completed_tasks': 0,
        'avg_completion_rate': 0.0,
        'performance_grade': 'F',
        'grade_color': _getGradeColor('F'),
        'coins_earned': 0,
      },
      'improvements': {
        'task_change': 0,
        'coin_change': 0,
        'rate_change': 0.0,
        'is_improving': false,
        'improvement_level': 'needs_improvement',
        'improvement_emoji': '📉',
      }
    };
  }

  // Motivational Quote Based on Performance
  Map<String, dynamic> getMotivationalContent(double completionRate) {
    final performanceLevel = _getPerformanceLevel(completionRate);
    final quotes = _getQuotesForLevel(performanceLevel);
    
    // Random quote selection based on day
    final randomIndex = DateTime.now().day % quotes.length;
    
    return {
      'quote': quotes[randomIndex],
      'performance_level': performanceLevel,
      'motivation_color': _getMotivationColor(performanceLevel),
      'motivation_emoji': _getMotivationEmoji(performanceLevel),
    };
  }

  // Monthly Trends Analysis
  Future<Map<String, dynamic>> getMonthlyTrendsAnalysis(int userId) async {
    try {
      final db = await _databaseHelper.database;
      
      final monthlyData = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', date) as month,
          AVG(completion_rate) as avg_completion_rate,
          SUM(completed_tasks) as total_completed,
          SUM(coins_earned) as total_coins,
          MAX(streak_count) as best_streak,
          COUNT(DISTINCT date) as active_days
        FROM user_stats 
        WHERE user_id = ? AND date >= date('now', '-6 months')
        GROUP BY strftime('%Y-%m', date)
        ORDER BY month DESC
      ''', [userId]);
      
      if (monthlyData.isEmpty) {
        return {
          'monthly_data': [],
          'overall_trend': 'stable',
        };
      }
      
      final processedData = monthlyData.map((month) {
        // Güvenli tip dönüşümü
        final completionRate = _safeDouble(month['avg_completion_rate']);
        final grade = _calculatePerformanceGrade(completionRate);
        
        return {
          ...month,
          'performance_grade': grade,
          'grade_color': _getGradeColor(grade),
          'month_formatted': _formatMonth(_safeString(month['month'])),
        };
      }).toList();
      
      return {
        'monthly_data': processedData,
        'overall_trend': _calculateOverallTrend(monthlyData),
      };
    } catch (e) {
      print('❌ getMonthlyTrendsAnalysis hatası: $e');
      return {
        'monthly_data': [],
        'overall_trend': 'stable',
      };
    }
  }

  // Most Completed Tasks Analysis
  Future<List<Map<String, dynamic>>> getMostCompletedTasksAnalysis(int userId) async {
    try {
      final mostCompleted = await _databaseHelper.getMostCompletedTasks(userId, limit: 5);
      
      if (mostCompleted.isEmpty) {
        return [];
      }
      
      return mostCompleted.map((task) {
        // Güvenli tip dönüşümü
        final completionCount = _safeInt(task['completion_count']);
        final type = _safeString(task['type']);
        
        return {
          ...task,
          'task_emoji': type == 'daily' ? '🔄' : '✅',
          'performance_level': _getTaskPerformanceLevel(completionCount),
          'performance_color': _getTaskPerformanceColor(completionCount),
        };
      }).toList();
    } catch (e) {
      print('❌ getMostCompletedTasksAnalysis hatası: $e');
      return [];
    }
  }

  // Least Completed Dailies Analysis
  Future<Map<String, dynamic>> getLeastCompletedDailiesAnalysis(int userId) async {
    try {
      final db = await _databaseHelper.database;
      
      // Daily tasks'ları analiz et - daily_templates ve tasks tablolarını kullanarak
      final result = await db.rawQuery('''
        SELECT 
          dt.title,
          dt.id,
          COUNT(t.id) as total_generated,
          SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) as completed_count,
          ROUND(
            (SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) * 100.0) / 
            NULLIF(COUNT(t.id), 0), 
            2
          ) as completion_rate
        FROM daily_templates dt
        LEFT JOIN tasks t ON dt.id = t.daily_template_id
        WHERE dt.user_id = ? 
          AND t.created_at >= date('now', '-30 days')
          AND t.type = 'daily'
        GROUP BY dt.id, dt.title
        HAVING COUNT(t.id) > 0
        ORDER BY completion_rate ASC  -- En düşük completion rate'ler önce
      ''', [userId]);

      // Geri kalan kod aynı kalabilir...
      List<Map<String, dynamic>> needsImprovement = [];
      List<Map<String, dynamic>> goodPerformance = [];

      for (var row in result) {
        final completionRate = _safeDouble(row['completion_rate']);
        final grade = _calculatePerformanceGrade(completionRate);
        
        final item = {
          'title': row['title']?.toString() ?? 'Unknown Task',
          'total_generated': _safeInt(row['total_generated']),
          'completed_count': _safeInt(row['completed_count']),
          'completion_rate': completionRate,
          'performance_grade': grade,
          'grade_color': _getGradeColor(grade),
          'suggestion': _getDailySuggestion(completionRate),
          'improvement_needed': completionRate < 80,
        };

        if (completionRate < 80.0) {
          needsImprovement.add(item);
        } else {
          goodPerformance.add(item);
        }
      }

      // Debug için konsola yazdır
      print('🔍 Daily Analytics Debug:');
      print('Needs Improvement Count: ${needsImprovement.length}');
      for (var item in needsImprovement) {
        print('- ${item['title']}: ${item['completion_rate']}%');
      }
      print('Good Performance Count: ${goodPerformance.length}');
      for (var item in goodPerformance) {
        print('- ${item['title']}: ${item['completion_rate']}%');
      }

      return {
        'needs_improvement': needsImprovement,
        'good_performance': goodPerformance,
        'total_analyzed': result.length,
      };
      
    } catch (e) {
      print('❌ getLeastCompletedDailiesAnalysis hatası: $e');
      return {
        'needs_improvement': <Map<String, dynamic>>[],
        'good_performance': <Map<String, dynamic>>[],
        'total_analyzed': 0,
      };
    }
  }



  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Performance Grade Calculator
  String _calculatePerformanceGrade(double completionRate) {
    if (completionRate >= 95) return 'A+';
    if (completionRate >= 90) return 'A';
    if (completionRate >= 85) return 'A-';
    if (completionRate >= 80) return 'B+';
    if (completionRate >= 75) return 'B';
    if (completionRate >= 70) return 'B-';
    if (completionRate >= 65) return 'C+';
    if (completionRate >= 60) return 'C';
    if (completionRate >= 55) return 'C-';
    if (completionRate >= 50) return 'D+';
    if (completionRate >= 45) return 'D';
    return 'F';
  }

  // Performance Level for Motivation
  String _getPerformanceLevel(double completionRate) {
    if (completionRate >= 80) return 'high_performance';
    if (completionRate >= 60) return 'good_performance';
    if (completionRate >= 40) return 'moderate_performance';
    return 'low_performance';
  }

  // Grade Colors
  int _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return 0xFF10B981; // Green
      case 'A-':
      case 'B+':
        return 0xFF06B6D4; // Cyan
      case 'B':
      case 'B-':
        return 0xFFF59E0B; // Yellow
      case 'C+':
      case 'C':
      case 'C-':
        return 0xFFEF4444; // Red
      case 'D+':
      case 'D':
        return 0xFF8B5CF6; // Purple
      default:
        return 0xFF6B7280; // Gray
    }
  }

  // Diğer metodlar aynı kalacak...

  // Performance Emojis
  String _getPerformanceEmoji(String grade) {
    switch (grade) {
      case 'A+': return '🏆';
      case 'A': return '🔥';
      case 'A-': return '⭐';
      case 'B+': return '💪';
      case 'B': return '👍';
      case 'B-': return '👌';
      case 'C+': return '📈';
      case 'C': return '🎯';
      case 'C-': return '⚡';
      case 'D+': return '🌱';
      case 'D': return '💭';
      default: return '🚀';
    }
  }

  // Motivation Colors & Emojis
  int _getMotivationColor(String level) {
    switch (level) {
      case 'high_performance': return 0xFF10B981;
      case 'good_performance': return 0xFF06B6D4;
      case 'moderate_performance': return 0xFFF59E0B;
      case 'low_performance': return 0xFF8B5CF6;
      default: return 0xFF667eea;
    }
  }

  String _getMotivationEmoji(String level) {
    switch (level) {
      case 'high_performance': return '🔥';
      case 'good_performance': return '💪';
      case 'moderate_performance': return '📈';
      case 'low_performance': return '🌱';
      default: return '✨';
    }
  }

  // Improvement Level & Emoji
  String _getImprovementLevel(int taskChange, int coinChange, double rateChange) {
    final totalScore = (taskChange >= 0 ? 1 : 0) + 
                     (coinChange >= 0 ? 1 : 0) + 
                     (rateChange >= 0 ? 1 : 0);
    
    if (totalScore == 3) return 'excellent_improvement';
    if (totalScore == 2) return 'good_improvement';
    if (totalScore == 1) return 'slight_improvement';
    return 'needs_improvement';
  }

  String _getImprovementEmoji(bool isImproving) {
    return isImproving ? '📈' : '📉';
  }

  // Task Performance Levels
  String _getTaskPerformanceLevel(int completionCount) {
    if (completionCount >= 20) return 'champion';
    if (completionCount >= 10) return 'expert';
    if (completionCount >= 5) return 'regular';
    return 'beginner';
  }

  int _getTaskPerformanceColor(int completionCount) {
    if (completionCount >= 20) return 0xFFFFD700; // Gold
    if (completionCount >= 10) return 0xFFC0C0C0; // Silver
    if (completionCount >= 5) return 0xFFCD7F32; // Bronze
    return 0xFF6B7280; // Gray
  }

  // Daily Suggestions
  String _getDailySuggestion(double completionRate) {
    if (completionRate < 30) return 'Bu görevi daha küçük parçalara bölebilirsin!';
    if (completionRate < 50) return 'Hatırlatıcı kurarak bu görevi daha düzenli yapabilirsin!';
    if (completionRate < 70) return 'İyi gidiyorsun! Biraz daha odaklanırsan mükemmel olacak!';
    return 'Harika performans! Böyle devam et!';
  }

  // Helper Functions
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return '${date.day}/${date.month} ${weekdays[date.weekday - 1]}';
    } catch (e) {
      print('❌ Tarih formatı hatası: $e');
      return '';
    }
  }

  String _formatMonth(String monthString) {
    try {
      final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 
                     'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      final parts = monthString.split('-');
      if (parts.length < 2) return '';
      
      final monthIndex = int.tryParse(parts[1]);
      if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return '';
      
      return '${months[monthIndex - 1]} ${parts[0]}';
    } catch (e) {
      print('❌ Ay formatı hatası: $e');
      return '';
    }
  }

  String _calculateOverallTrend(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.length < 2) return 'stable';
    
    try {
      final recent = _safeDouble(monthlyData.first['avg_completion_rate']);
      final older = _safeDouble(monthlyData.last['avg_completion_rate']);
      
      if (recent > older + 10) return 'improving';
      if (recent < older - 10) return 'declining';
      return 'stable';
    } catch (e) {
      print('❌ Trend hesaplama hatası: $e');
      return 'stable';
    }
  }

  // Motivational Quotes by Performance Level
  List<String> _getQuotesForLevel(String level) {
    switch (level) {
      case 'high_performance':
        return [
          "Sen gerçek bir şampiyon gibi davranıyorsun! 🏆",
          "Bu performans ile sınırların yok! ⚡",
          "Mükemmellik senin doğan! Böyle devam! 🌟",
          "Harika gidiyorsun! Başarı senin için bir alışkanlık olmuş! 🔥",
        ];
      case 'good_performance':
        return [
          "İyi bir tempoda ilerliyorsun! 💪",
          "Kararlılığın seni başarıya götürüyor! 🎯",
          "Her gün biraz daha güçleniyorsun! 📈",
          "Hedeflerine odaklanmış bir şekilde ilerliyorsun! 🚀",
        ];
      case 'moderate_performance':
        return [
          "Sen yapabilirsin! Küçük adımlar büyük değişimler yaratır! 🌱",
          "Her gün yeni bir fırsat! Bugün daha iyisini yapabilirsin! ✨",
          "İlerleme kaydediyorsun, böyle devam et! 📊",
          "Azmin seni hedefe götürecek! 💪",
        ];
      case 'low_performance':
        return [
          "Her büyük yolculuk tek bir adımla başlar! 🚶‍♂️",
          "Potansiyelin sonsuz, sadece harekete geç! 💎",
          "Bugün yeni bir başlangıç! Sen yapabilirsin! 🌅",
          "Küçük adımlar büyük değişimlere yol açar! 🌿",
        ];
      default:
        return [
          "Bugün harika bir gün! Hadi başlayalım! ✨",
          "Sen eşsizsin ve başarabilirsin! 🌟",
          "Her an yeni bir fırsat! 🚀",
        ];
    }
  }
}
