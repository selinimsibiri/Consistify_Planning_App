import 'package:flutter/material.dart';
import 'dart:math';

class CoinAnimationOverlay {
  static void showCoinDrop(BuildContext context, int coinAmount) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => CoinDropAnimation(
        coinAmount: coinAmount,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

class CoinDropAnimation extends StatefulWidget {
  final int coinAmount;
  final VoidCallback onComplete;
  
  const CoinDropAnimation({
    Key? key,
    required this.coinAmount,
    required this.onComplete,
  }) : super(key: key);
  
  @override
  _CoinDropAnimationState createState() => _CoinDropAnimationState();
}

class _CoinDropAnimationState extends State<CoinDropAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fallAnimations;
  late List<Animation<double>> _rotateAnimations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations; // 🆕 Şeffaflık animasyonu
  late List<Offset> _startPositions;
  
  late double screenWidth;
  late double screenHeight;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    final coinCount = (widget.coinAmount / 5).clamp(3, 8).toInt();
    
    _controllers = List.generate(
      coinCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 80)),
        vsync: this,
      ),
    );
    
    // 🔧 Daha yukarıda biten düşme
    _fallAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: screenHeight * 0.45, // 🔧 Daha yukarıda bitir
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
    
    _rotateAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 2 * pi,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));
    }).toList();
    
    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(0.0, 0.2, curve: Curves.elasticOut),
      ));
    }).toList();
    
    // 🔧 Daha erken kaybolmaya başla
    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(0.4, 1.0, curve: Curves.easeOut), // 🔧 %40'tan sonra kaybol
      ));
    }).toList();
    
    // 🆕 Şeffaflık animasyonu - yarıda kaybolmaya başlar
    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut), // 🎯 %50'den sonra kaybol
      ));
    }).toList();
    
    _startPositions = List.generate(
      coinCount,
      (index) => Offset(
        screenWidth * 0.2 + (Random().nextDouble() * screenWidth * 0.6),
        screenHeight * 0.1,
      ),
    );
    
    // Animasyonları başlat
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () { // 🔧 Daha hızlı başlatma
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
    
    // 🔧 Daha kısa temizleme süresi
    Future.delayed(Duration(milliseconds: 1800), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          
          // 🔧 Düşen coin'ler - titreme yok, yumuşak kaybolma
          ...List.generate(_controllers.length, (index) {
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Positioned(
                  left: _startPositions[index].dx, // 🔧 Yan hareket kaldırıldı
                  top: _startPositions[index].dy + _fallAnimations[index].value,
                  child: Opacity(
                    opacity: _opacityAnimations[index].value, // 🆕 Şeffaflık
                    child: Transform.scale(
                      scale: _scaleAnimations[index].value,
                      child: Transform.rotate(
                        angle: _rotateAnimations[index].value,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '🪙',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
