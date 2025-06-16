// lib/widgets/today_performance_card.dart
import 'package:flutter/material.dart';
import 'package:consistify/widgets/colored_progress_ring.dart';

class TodayPerformanceCard extends StatelessWidget {
  final Map<String, dynamic> todayStats;
  final VoidCallback? onPerformanceDetailsTap; // 👈 YENİ EKLENEN

  const TodayPerformanceCard({
    Key? key,
    required this.todayStats,
    this.onPerformanceDetailsTap, // 👈 YENİ EKLENEN
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completionRate = (todayStats['completion_rate'] as num).toDouble();
    final completedTasks = todayStats['completed_tasks'] as int;
    final totalTasks = todayStats['total_tasks'] as int;
    final coinsEarned = todayStats['coins_earned'] as int;
    final performanceGrade = todayStats['performance_grade'] as String;
    final gradeColor = _getGradeColor(performanceGrade);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradeColor.withOpacity(0.3),
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
      child: Material( // 👈 YENİ EKLENEN - Tıklama efekti için
        color: Colors.transparent,
        child: InkWell( // 👈 YENİ EKLENEN - Tıklama efekti
          borderRadius: BorderRadius.circular(16),
          onTap: onPerformanceDetailsTap, // 👈 YENİ EKLENEN
          child: Padding( // 👈 DEĞİŞTİRİLDİ - padding Container'dan Padding'e taşındı
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gradeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Performance',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateTime.now().toString().split(' ')[0],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Grade Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gradeColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        performanceGrade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Progress Ring ve Stats
                Row(
                  children: [
                    // Progress Ring
                    ColoredProgressRing(
                      progress: completionRate / 100,
                      size: 100,
                      color: gradeColor,
                      centerText: '${completionRate.round()}%',
                      centerSubText: _getPerformanceText(completionRate),
                    ),
                    
                    SizedBox(width: 24),
                    
                    // Stats
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '✅',
                                  'Completed',
                                  '$completedTasks/$totalTasks',
                                  gradeColor,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  '🪙',
                                  'Earned',
                                  '$coinsEarned',
                                  Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Performance Message
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gradeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getPerformanceMessage(completionRate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 👈 YENİ EKLENEN - Tıklama ipucu
                if (onPerformanceDetailsTap != null) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white54,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  String _getPerformanceText(double rate) {
    if (rate >= 90) return 'EXCELLENT';
    if (rate >= 80) return 'GREAT';
    if (rate >= 70) return 'GOOD';
    if (rate >= 50) return 'FAIR';
    return 'NEEDS WORK';
  }

  String _getPerformanceMessage(double rate) {
    if (rate >= 90) return 'Outstanding work! You\'re crushing it today! 🏆';
    if (rate >= 80) return 'Great job! Keep up the momentum! 🔥';
    if (rate >= 70) return 'Good progress! Push a little harder! ⚡';
    if (rate >= 50) return 'Not bad! You can do better! 💪';
    return 'Fresh start! Every expert was once a beginner! 🌱';
  }
}
