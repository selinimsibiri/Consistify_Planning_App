// lib/widgets/personality_type_card.dart
import 'package:flutter/material.dart';

class PersonalityTypeCard extends StatelessWidget {
  final String personalityType;
  final double completionRate;

  const PersonalityTypeCard({
    Key? key,
    required this.personalityType,
    required this.completionRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final personality = _getPersonalityData(personalityType);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: personality['colors'],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: personality['colors'][0].withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  personality['emoji'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Personality Type',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      personalityType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Description
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              personality['description'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Completion Rate',
                '${completionRate.round()}%',
                Icons.percent,
              ),
              _buildStatColumn(
                'Level',
                personality['level'],
                Icons.star,
              ),
              _buildStatColumn(
                'Streak Potential',
                personality['potential'],
                Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getPersonalityData(String type) {
    switch (type) {
      case '🏆 Görev Makinesi':
        return {
          'emoji': '🏆',
          'colors': [Color(0xFFFFD700), Color(0xFFFFA500)],
          'description': 'Sen gerçek bir performans canavarısın! Görevleri tamamlamak senin için nefes almak kadar doğal.',
          'level': 'Master',
          'potential': 'Unlimited',
        };
      case '⚡ Süper Verimli':
        return {
          'emoji': '⚡',
          'colors': [Color(0xFF10B981), Color(0xFF059669)],
          'description': 'Verimlilik senin süper gücün! Hedeflerine ulaşmak için gereken kararlılığa sahipsin.',
          'level': 'Expert',
          'potential': 'Very High',
        };
      case '🎯 Hedef Odaklı':
        return {
          'emoji': '🎯',
          'colors': [Color(0xFF06B6D4), Color(0xFF0891B2)],
          'description': 'Hedeflerine odaklanmış bir şekilde ilerliyorsun. Bu kararlılık seni başarıya götürüyor.',
          'level': 'Advanced',
          'potential': 'High',
        };
      case '📈 Gelişen Kahraman':
        return {
          'emoji': '📈',
          'colors': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          'description': 'Her gün biraz daha güçleniyorsun. Gelişim yolculuğunda kararlı adımlarla ilerliyorsun.',
          'level': 'Intermediate',
          'potential': 'Growing',
        };
      case '🌱 Büyüyen Tohum':
        return {
          'emoji': '🌱',
          'colors': [Color(0xFFF59E0B), Color(0xFFD97706)],
          'description': 'Büyüme potansiyelin çok yüksek! Küçük adımlarla büyük değişimlere gidiyorsun.',
          'level': 'Beginner',
          'potential': 'Promising',
        };
      default:
        return {
          'emoji': '💪',
          'colors': [Color(0xFFEC4899), Color(0xFFDB2777)],
          'description': 'İçinde büyük bir potansiyel var! Sadece harekete geçmen yeterli.',
          'level': 'Starter',
          'potential': 'Hidden',
        };
    }
  }
}
