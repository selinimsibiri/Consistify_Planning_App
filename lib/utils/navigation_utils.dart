// lib/utils/navigation_utils.dart
import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/utils/app_routes.dart';
import 'package:sayfa_yonlendirme/utils/app_routes.dart';
import '../screens/todo_screen.dart';
import '../screens/daily_screen.dart';
import '../screens/planning_screen.dart';
import '../screens/profile_screen.dart';

class NavigationUtils {
  
  // 🎯 Todo sayfasına git (refresh callback ile)
  static Future<void> goToTodo(BuildContext context, int userId, {VoidCallback? onRefresh}) async {
    final result = await Navigator.push(
      context,
      AppRoutes.createRoute(
        TodoScreen(userId: userId),
        type: RouteType.fade,
      ),
    );
    
    if (result == 'refresh' && onRefresh != null) {
      onRefresh();
    }
  }
  
  // 🎯 Daily sayfasına git
  static void goToDaily(BuildContext context, int userId) {
    Navigator.push(
      context,
      AppRoutes.createRoute(
        DailyScreen(userId: userId),
        type: RouteType.fade,
      ),
    );
  }
  
  // 🎯 Planning sayfasına git
  static void goToPlanning(BuildContext context, int userId) {
    print('📅 Planning sayfasına geçiliyor...');
    Navigator.push(
      context,
      AppRoutes.createRoute(
        PlanningScreen(userId: userId),
        type: RouteType.fade,
      ),
    );
  }
  
  // 🎯 Profile sayfasına git
  static void goToProfile(BuildContext context, int userId) {
    Navigator.push(
      context,
      AppRoutes.createRoute(
        ProfileScreen(userId: userId),
        type: RouteType.fade,
      ),
    );
  }
  
  // 🎯 Geri git
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
  
  // 🎯 Tüm sayfaları temizleyip yeni sayfaya git
  static void goToAndClearAll(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      AppRoutes.createRoute(page, type: RouteType.fade),
      (Route<dynamic> route) => false,
    );
  }
  
  // 🎯 Sayfayı değiştir (replace)
  static void replacePage(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      AppRoutes.createRoute(page, type: RouteType.fade),
    );
  }
}
