// lib/widgets/daily_analytics_card.dart
import 'package:flutter/material.dart';

class DailyAnalyticsCard extends StatelessWidget {
  final List<Map<String, dynamic>> dailyAnalytics;

  const DailyAnalyticsCard({
    Key? key,
    required this.dailyAnalytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Color(0xFF06B6D4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Daily Task Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                'Last 30 Days',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Analytics List
          if (dailyAnalytics.isEmpty)
            _buildEmptyState()
          else
            ...dailyAnalytics.take(3).map((daily) => _buildDailyItem(daily)).toList(),
          
          if (dailyAnalytics.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Tüm daily'leri göster
                  },
                  child: Text(
                    'View All (${dailyAnalytics.length})',
                    style: TextStyle(
                      color: Color(0xFF06B6D4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyItem(Map<String, dynamic> daily) {
    // Null-safe değer alma
    final completionRate = _safeDouble(daily['completion_rate']);
    final grade = _safeString(daily['performance_grade']) ?? 'N/A';
    final title = _safeString(daily['title']) ?? 'Unknown Task';
    final completedCount = _safeInt(daily['completed_count']);
    final totalGenerated = _safeInt(daily['total_generated']);
    final color = _getGradeColor(grade);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Grade Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '$completedCount/$totalGenerated completed',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Completion Rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${completionRate.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (completionRate / 100).clamp(0.0, 1.0), // 👈 Clamp eklendi
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.white30,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No daily tasks found',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
          Text(
            'Create some daily tasks to see analytics',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) { // 👈 Case-insensitive yapıldı
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
      case 'N/A':
      default:
        return Color(0xFF6B7280);
    }
  }

  // Null-safe helper methods
  String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

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
}
