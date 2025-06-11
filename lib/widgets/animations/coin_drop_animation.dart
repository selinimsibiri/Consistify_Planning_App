import 'package:flutter/material.dart';

class CoinDropAnimation extends StatefulWidget {
  final int coinAmount;
  final VoidCallback? onComplete;

  const CoinDropAnimation({
    Key? key,
    required this.coinAmount,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CoinDropAnimation> createState() => _CoinDropAnimationState();
}

class _CoinDropAnimationState extends State<CoinDropAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  
  late Animation<double> _coin1Position;
  late Animation<double> _coin2Position;
  late Animation<double> _coin1Rotation;
  late Animation<double> _coin2Rotation;
  late Animation<double> _coin1Scale;
  late Animation<double> _coin2Scale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Ana animasyon controller'ı
    _controller = AnimationController(
      duration: Duration(milliseconds: 1800), // 2 saniye
      vsync: this,
    );
    
    // Fade out controller'ı
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    // 🪙 İlk coin animasyonları (önde olan)
    _coin1Position = Tween<double>(
      begin: -100, // Ekranın üstünden başla
      end: MediaQuery.of(context).size.height + 100, // Ekranın altına git
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInQuart, // Hızlanarak düş
    ));

    _coin1Rotation = Tween<double>(
      begin: 0,
      end: 8, // 8 tam tur dön
    ).animate(_controller);

    _coin1Scale = Tween<double>(
      begin: 1.0,
      end: 0.6, // Düşerken biraz küçül
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 🪙 İkinci coin animasyonları (arkada olan - biraz gecikmeli)
    _coin2Position = Tween<double>(
      begin: -150, // Biraz daha yukardan başla
      end: MediaQuery.of(context).size.height + 50,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 1.0, curve: Curves.easeInQuart), // 0.1 saniye gecikme
    ));

    _coin2Rotation = Tween<double>(
      begin: 0,
      end: -6, // Ters yönde dön
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 1.0),
    ));

    _coin2Scale = Tween<double>(
      begin: 0.8, // Daha küçük başla
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 1.0, curve: Curves.easeOut),
    ));

    // Fade out animasyonu
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);

    // Animasyonu başlat
    _startAnimation();
  }

  void _startAnimation() async {
    await _controller.forward();
    
    // Son 0.5 saniyede fade out yap
    await _fadeController.forward();
    
    // Animasyon tamamlandı
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _fadeController]),
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer( // Tıklamayı engelle
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // 🪙 İkinci coin (arkada)
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.45, // Biraz sola
                    top: _coin2Position.value,
                    child: Transform.rotate(
                      angle: _coin2Rotation.value,
                      child: Transform.scale(
                        scale: _coin2Scale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            '🪙',
                            style: TextStyle(
                              fontSize: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 🪙 İlk coin (önde)
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.55, // Biraz sağa
                    top: _coin1Position.value,
                    child: Transform.rotate(
                      angle: _coin1Rotation.value,
                      child: Transform.scale(
                        scale: _coin1Scale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF59E0B).withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            '🪙',
                            style: TextStyle(
                              fontSize: 50, // Önde olan daha büyük
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 💰 Coin miktarı metni (ortada, yukarıda)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.3,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFEAB308),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFF59E0B).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${widget.coinAmount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '🪙',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
