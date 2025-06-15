import 'package:flutter/material.dart';

class WeeklyComparisonChart extends StatelessWidget {
  final Map<String, dynamic> weeklyData;

  const WeeklyComparisonChart({
    Key? key,
    required this.weeklyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final thisWeek = weeklyData['this_week'] as Map<String, dynamic>;
    final lastWeek = weeklyData['last_week'] as Map<String, dynamic>;
    final improvements = weeklyData['improvements'] as Map<String, dynamic>;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
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
                Icons.trending_up,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Weekly Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: improvements['is_improving'] 
                      ? Color(0xFF10B981).withOpacity(0.2)
                      : Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  improvements['is_improving'] ? '📈 Improving' : '📉 Needs Focus',
                  style: TextStyle(
                    color: improvements['is_improving'] 
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Comparison Bars
          _buildComparisonRow(
            'Completed Tasks',
            thisWeek['completed_tasks'],
            lastWeek['completed_tasks'],
            improvements['task_change'],
            Icons.assignment_turned_in,
            Color(0xFF8B5CF6),
          ),
          
          SizedBox(height: 16),
          
          _buildComparisonRow(
            'Coins Earned',
            thisWeek['coins_earned'],
            lastWeek['coins_earned'],
            improvements['coin_change'],
            Icons.monetization_on,
            Color(0xFFF59E0B),
          ),
          
          SizedBox(height: 16),
          
          _buildComparisonRow(
            'Completion Rate',
            '${thisWeek['avg_completion_rate'].toStringAsFixed(1)}%',
            '${lastWeek['avg_completion_rate'].toStringAsFixed(1)}%',
            '${improvements['rate_change'].toStringAsFixed(1)}%',
            Icons.percent,
            Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    dynamic thisWeekValue,
    dynamic lastWeekValue,
    dynamic change,
    IconData icon,
    Color color,
  ) {
    final isImprovement = change is num ? change >= 0 : false;
    final changeText = change is num 
        ? (change >= 0 ? '+$change' : '$change')
        : change.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isImprovement 
                    ? Color(0xFF10B981).withOpacity(0.2)
                    : Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                changeText,
                style: TextStyle(
                  color: isImprovement ? Color(0xFF10B981) : Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        Row(
          children: [
            // This Week
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$thisWeekValue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // VS
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'vs',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Last Week
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Week',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$lastWeekValue',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
