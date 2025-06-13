import 'package:flutter/material.dart';

class AppRoutes {
  static Route<T> createRoute<T>(Widget page, {RouteType type = RouteType.fade}) {
    switch (type) {
      case RouteType.fade:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, _) => page,
          transitionDuration: Duration(milliseconds: 250),
          reverseTransitionDuration: Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
      
      case RouteType.slide:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, _) => page,
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      
      case RouteType.scale:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, _) => page,
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.9,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
    }
  }
}

enum RouteType { fade, slide, scale }
