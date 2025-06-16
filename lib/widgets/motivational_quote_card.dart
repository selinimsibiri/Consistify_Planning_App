// lib/widgets/motivational_quote_card.dart
import 'package:flutter/material.dart';

class MotivationalQuoteCard extends StatelessWidget {
  final String quote;
  final String performanceLevel;

  const MotivationalQuoteCard({
    Key? key,
    required this.quote,
    required this.performanceLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors(performanceLevel);
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quote Icon
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Daily Motivation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMotivationEmoji(performanceLevel),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Quote Text
          Text(
            quote,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12),
          
          // Performance Level
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMotivationLevel(performanceLevel),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String level) {
    switch (level) {
      case 'high_performance':
        return [Color(0xFF10B981), Color(0xFF059669)]; // Yeşil
      case 'good_performance':
        return [Color(0xFF06B6D4), Color(0xFF0891B2)]; // Mavi
      case 'moderate_performance':
        return [Color(0xFFF59E0B), Color(0xFFD97706)]; // Turuncu
      case 'low_performance':
        return [Color(0xFF8B5CF6), Color(0xFF7C3AED)]; // Mor
      default:
        return [Color(0xFF667eea), Color(0xFF764ba2)]; // Default
    }
  }

  String _getMotivationEmoji(String level) {
    switch (level) {
      case 'high_performance': return '🔥';
      case 'good_performance': return '⚡';
      case 'moderate_performance': return '🌱';
      case 'low_performance': return '💪';
      default: return '✨';
    }
  }

  String _getMotivationLevel(String level) {
    switch (level) {
      case 'high_performance': return '🔥 CHAMPION MODE';
      case 'good_performance': return '⚡ STRONG PERFORMANCE';
      case 'moderate_performance': return '🌱 GROWTH MODE';
      case 'low_performance': return '💪 POTENTIAL MODE';
      default: return '✨ MOTIVATION MODE';
    }
  }
}
