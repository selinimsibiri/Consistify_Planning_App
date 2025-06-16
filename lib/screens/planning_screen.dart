import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:consistify/db/database_helper.dart';
import 'package:consistify/utils/dialog_utils.dart';
import 'package:consistify/utils/navigation_utils.dart';
import 'package:consistify/widgets/animations/coin_animation_overlay.dart';

class PlanningScreen extends StatefulWidget {
  /*
 * Planlama ekranı
 * - Kullanıcının haftalık/aylık görev planlamasını gösterir
 * - Takvim görünümü ile görev dağılımını visualize eder
 * - Gelecek görevlerin planlanması ve düzenlenmesi için arayüz sağlar
 */
  final int userId;

  const PlanningScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  /*
 * PlanningScreen'in State sınıfı
 * - Seçilen tarihe ait günlük planları yükler ve görüntüler
 * - Tarih seçici ile farklı günlerin planlarına geçiş sağlar
 * - Aktif zaman dilimindeki planları vurgular
 * - Plan ekleme, düzenleme ve silme işlemlerini yönetir
 * - Plan kartlarına tıklayarak görev detaylarını gösterir
 * - Alt navigasyon ile diğer ekranlara geçiş sağlar
 */
  List<Map<String, dynamic>> dailyPlans = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  int userCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCoins();
    _loadDailyPlans();
  }

  Future<void> _loadUserCoins() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: [widget.userId],
    );
    
    if (result.isNotEmpty && mounted) {
      setState(() {
        userCoins = result.first['coins'] as int;
      });
    }
  }

  Future<void> _loadDailyPlans() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
            
      final result = await db.query(
        'plans',
        where: 'user_id = ? AND date = ?',
        whereArgs: [widget.userId, dateString],
        orderBy: 'time_slot ASC',
      );

      if (mounted) {
        setState(() {
          dailyPlans = result;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Plan yükleme hatası: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF1A1A1A),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 46, 46, 46),
                ],
                stops: [1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Üst Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Logout icon
                        GestureDetector(
                          onTap: () => DialogUtils.showLogoutDialog(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(0xFF404040),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Daily Planning başlığı
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF06B6D4).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'DAILY PLANNING',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // 🪙 Coins
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$userCoins',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text('🪙', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ana İçerik
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          _buildDateSelector(),
                          SizedBox(height: 16),
                          isLoading
                              ? Container(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF06B6D4),
                                    ),
                                  ),
                                )
                              : _buildPlanList(),
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sağ alt köşede + butonu
          Positioned(
            right: 0,
            bottom: 90,
            child: GestureDetector(
              onTap: _showAddPlanDialog,
              child: Container(
                width: 70,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF06B6D4).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(-3, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Alt Navigation Bar
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              icon: Icons.check_circle_outline,
              color: Color(0xFF8B5CF6),
              onTap: () => NavigationUtils.goToTodo(
                context, 
                widget.userId, 
              ),
            ),
            _buildNavButton(
              icon: Icons.assignment_outlined,
              color: Color(0xFF06B6D4),
              onTap: () => NavigationUtils.goToDaily(context, widget.userId),
            ),
            _buildNavButton(
              icon: Icons.schedule,
              color: Color(0xFF10B981),
              isActive: true,
              onTap: () {},
            ),
            _buildNavButton(
              icon: Icons.person_outline,
              color: Color(0xFFF59E0B),
              onTap: () => NavigationUtils.goToProfile(context, widget.userId),
            ),
            _buildNavButton(
              icon: Icons.trending_up,
              color: Color(0xFFEC4899),
              onTap: () => NavigationUtils.goToStatistics(context, widget.userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.subtract(Duration(days: 1));
                });
                _loadDailyPlans();
              },
              icon: Icon(Icons.chevron_left, color: Colors.white),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('dd MMMM yyyy - EEEE').format(selectedDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.add(Duration(days: 1));
                });
                _loadDailyPlans();
              },
              icon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    if (dailyPlans.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No plans for this day',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Tap + to add your first plan',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: dailyPlans.map((plan) => _buildPlanCard(plan)).toList(),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    // Aktif plan mı kontrol edilir
    final bool isActivePlan = _isCurrentlyActive(plan);
    
    return GestureDetector(
      onTap: () => _showPlanTasksDialog(plan),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isActivePlan 
                  ? Color(0xFFE879F9)
                  : Color(0xFF06B6D4),
              width: 4,
            ),
          ),
          boxShadow: isActivePlan ? [
            BoxShadow(
              color: Color(0xFFE879F9).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isActivePlan) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFFE879F9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            plan['title'] ?? 'Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey[400], size: 20),
                        onPressed: () => _editPlan(plan),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                        onPressed: () => _deletePlan(plan['id']),
                      ),
                    ],
                  ),
                ],
              ),
              if (plan['description'] != null && plan['description'].isNotEmpty)
                Text(
                  plan['description'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              SizedBox(height: 8),
              Text(
                plan['time_slot'],
                style: TextStyle(
                  color: isActivePlan 
                      ? Color(0xFFE879F9)
                      : Color(0xFF06B6D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Aktif plan kontrolü
  bool _isCurrentlyActive(Map<String, dynamic> plan) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    try {
      // "HH.MM - HH.MM" formatını parse et
      final timeSlot = plan['time_slot'] as String;
      final parts = timeSlot.split(' - ');
      
      if (parts.length != 2) return false;
      
      final startParts = parts[0].split('.');
      final endParts = parts[1].split('.');
      
      if (startParts.length != 2 || endParts.length != 2) return false;
      
      final startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      
      final endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      
      // Şu anki saati dakika cinsinden hesapla
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      // Gece yarısını geçen planlar için kontrol
      if (endMinutes < startMinutes) {
        // Örnek: 23:00 - 01:00
        return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
      } else {
        // Normal saat aralığı
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      }
    } catch (e) {
      print('❌ Saat parse hatası: $e');
      return false;
    }
  }


  void _showPlanTasksDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => PlanTasksDialog(
        userId: widget.userId,
        plan: plan,
        onTaskCompleted: () {
          _loadUserCoins();
        },
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _showAddPlanDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPlanDialog(
        userId: widget.userId,
        selectedDate: selectedDate,
        onPlanAdded: _loadDailyPlans,
      ),
    );
  }

  void _editPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AddPlanDialog(
        userId: widget.userId,
        selectedDate: selectedDate,
        onPlanAdded: _loadDailyPlans,
        existingPlan: plan,
      ),
    );
  }

  Future<void> _deletePlan(int planId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('plans', where: 'id = ?', whereArgs: [planId]);
      _loadDailyPlans();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan deleted successfully'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Plan silme hatası: $e');
    }
  }
}

class AddPlanDialog extends StatefulWidget {
  /*
  * Plan ekleme/düzenleme dialog'u
  * - Yeni günlük plan oluşturma veya mevcut planı düzenleme formu
  * - Başlık, açıklama ve zaman dilimi girişi sağlar
  * - Mevcut plan verileri ile dialog'u doldurabilir (düzenleme modu)
  * - Plan kaydedildikten sonra ana sayfayı yeniler
  */
  final int userId;
  final DateTime selectedDate;
  final VoidCallback onPlanAdded; 
  final Map<String, dynamic>? existingPlan;

  const AddPlanDialog({
    Key? key,
    required this.userId,
    required this.selectedDate, 
    required this.onPlanAdded, 
    this.existingPlan,
  }) : super(key: key);

  @override
  State<AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<AddPlanDialog> {
  /*
  * AddPlanDialog'un State sınıfı
  * - Plan başlığı, açıklama ve zaman aralığı girişi için form yönetimi
  * - Mevcut plan düzenleme durumunda form alanlarını önceden doldurur
  * - Başlangıç ve bitiş saati seçimi için time picker'lar sağlar
  * - Saat çakışmalarını önlemek için otomatik düzeltme yapar
  * - Plan süresini hesaplar ve görüntüler
  * - Yeni plan ekleme veya mevcut plan güncelleme işlemlerini gerçekleştirir
  */
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _titleController.text = widget.existingPlan!['title'] ?? '';
      _descriptionController.text = widget.existingPlan!['description'] ?? '';        
      _parseExistingTimeSlot();
    }
  }

  void _parseExistingTimeSlot() {
    try {
      final timeSlot = widget.existingPlan!['time_slot'] as String;
      final parts = timeSlot.split(' - ');
      
      if (parts.length == 2) {
        final startParts = parts[0].split('.');
        final endParts = parts[1].split('.');
        
        if (startParts.length == 2 && endParts.length == 2) {
          _startTime = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]),
          );
          _endTime = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]),
          );
        }
      }
    } catch (e) {
      print('Mevcut saat parse hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              widget.existingPlan != null ? 'Edit Plan' : 'Add New Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),

            // Plan Title
            _buildTextField(
              controller: _titleController,
              label: 'Plan Title',
              hint: 'e.g., Morning Workout',
            ),
            SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Add some details...',
              maxLines: 3,
            ),
            SizedBox(height: 24),

            // Time Selection
            _buildTimeSelectionSection(),
            SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF06B6D4),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.existingPlan != null ? 'Update' : 'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        
        // Time Selection Cards
        Row(
          children: [
            // Start Time
            Expanded(
              child: _buildTimeCard(
                label: 'Start Time',
                time: _startTime,
                onTap: () => _selectTime(true),
              ),
            ),
            SizedBox(width: 16),
            
            // Arrow
            Icon(Icons.arrow_forward, color: Color(0xFF06B6D4)),
            SizedBox(width: 16),
            
            // End Time
            Expanded(
              child: _buildTimeCard(
                label: 'End Time',
                time: _endTime,
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Duration Display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFF06B6D4).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: Color(0xFF06B6D4), size: 16),
              SizedBox(width: 8),
              Text(
                'Duration: ${_calculateDuration()}',
                style: TextStyle(
                  color: Color(0xFF06B6D4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF06B6D4).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _formatTime(time),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF06B6D4), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Color(0xFF2A2A2A),
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: Color(0xFF06B6D4),
              dialBackgroundColor: Color(0xFF1A1A1A),
              hourMinuteColor: Color(0xFF1A1A1A),
              dayPeriodColor: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Eğer başlangıç saati bitiş saatinden sonraysa, bitiş saatini güncelle
          if (_isTimeAfter(_startTime, _endTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
          // Eğer bitiş saati başlangıç saatinden önce ise, başlangıç saatini güncelle
          if (_isTimeAfter(_startTime, _endTime)) {
            _startTime = TimeOfDay(
              hour: _endTime.hour > 0 ? _endTime.hour - 1 : 23,
              minute: _endTime.minute,
            );
          }
        }
      });
    }
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour || 
          (time1.hour == time2.hour && time1.minute > time2.minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    int startMinutes = _startTime.hour * 60 + _startTime.minute;
    int endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    int duration;
    if (endMinutes < startMinutes) {
      // Gece yarısını geçen süre
      duration = (24 * 60) - startMinutes + endMinutes;
    } else {
      duration = endMinutes - startMinutes;
    }
    
    int hours = duration ~/ 60;
    int minutes = duration % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _savePlan() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a plan title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final timeSlot = '${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
      final planData = {
        'user_id': widget.userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'time_slot': timeSlot,
        'date': widget.selectedDate.toIso8601String().split('T')[0],
      };

      if (widget.existingPlan != null) {
        await db.update(
          'plans',
          planData,
          where: 'id = ?',
          whereArgs: [widget.existingPlan!['id']],
        );
      } else {
        await db.insert('plans', planData);
      }

      // Parent'ı bilgilendir
      widget.onPlanAdded();
      
      Navigator.pop(context, true);
    } catch (e) {
      print('Plan kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class EditPlanDialog extends StatefulWidget {
  /*
    * Plan düzenleme dialog'u
    * - Mevcut planın bilgilerini düzenleme formu sağlar
    * - Plan başlığı, açıklama ve zaman dilimi güncellemesi yapılabilir
    * - Güncelleme işlemi tamamlandıktan sonra ana sayfayı yeniler
  */
  final Map<String, dynamic> plan;
  final VoidCallback onPlanUpdated;

  const EditPlanDialog({
    Key? key,
    required this.plan,
    required this.onPlanUpdated,
  }) : super(key: key);

  @override
  State<EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<EditPlanDialog> {
  /*
    * EditPlanDialog'un State sınıfı
    * - Mevcut plan verilerini form alanlarına yükler ve düzenleme imkanı sağlar
    * - Plan başlığı, açıklama ve zaman dilimi güncelleme işlemlerini yönetir
    * - Form validasyonu ile boş alan kontrolü yapar
    * - Loading durumu gösterir ve güncelleme işlemini asenkron olarak gerçekleştirir
    * - Başarılı/hatalı işlem sonuçlarını kullanıcıya bildirir
    * - Güncelleme sonrası ana sayfayı yeniler ve dialog'u kapatır
  */
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan['title']);
    _descriptionController = TextEditingController(text: widget.plan['description'] ?? '');
    _timeController = TextEditingController(text: widget.plan['time_slot']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Edit Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Zaman Aralığı
            Text(
              'Time Slot',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _timeController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., 07:00 - 08:00',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: 16),

            // Başlık
            Text(
              'Title',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Morning Workout',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: 16),

            // Açıklama
            Text(
              'Description (Optional)',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add some notes...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[600]!),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF06B6D4),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Update',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlan() async {
    if (_titleController.text.trim().isEmpty || _timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in time slot and title'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        'plans',
        {
          'time_slot': _timeController.text.trim(),
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        },
        where: 'id = ?',
        whereArgs: [widget.plan['id']],
      );


      widget.onPlanUpdated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Plan güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update plan'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class PlanTasksDialog extends StatefulWidget {
  /*
    * Plan görevleri dialog'u
    * - Seçilen plana ait görevleri listeler ve yönetir
    * - Görev tamamlama/geri alma işlemlerini sağlar
    * - Yeni görev ekleme ve mevcut görevleri düzenleme imkanı sunar
    * - Görev durumu değiştiğinde ana sayfayı bilgilendirir
 */
  final int userId;
  final Map<String, dynamic> plan;
  final VoidCallback? onTaskCompleted;

  const PlanTasksDialog({
    Key? key,
    required this.userId,
    required this.plan,
    this.onTaskCompleted,
  }) : super(key: key);

  @override
  State<PlanTasksDialog> createState() => _PlanTasksDialogState();
}

class _PlanTasksDialogState extends State<PlanTasksDialog> {
  /*
    * PlanTasksDialog'un State sınıfı
    * - Seçilen plana atanmış görevleri ve mevcut görevleri yönetir
    * - Görev tamamlama durumlarını takip eder ve veritabanında günceller
    * - to-do tarzı checkbox'lı görev listesi sunar
    * - Görev tamamlandığında coin ödülü animasyonu gösterir
    * - Mevcut görevlerden plana yeni görev atama imkanı sağlar
    * - Tamamlanan görevleri listenin altında, tamamlanmayanları üstte gösterir
    * - İki ayrı dialog: ana görev listesi ve mevcut görevler seçimi
    * - Görev durumu değişikliklerini ana sayfaya bildirir
 */
  List<Map<String, dynamic>> availableTasks = [];
  List<Map<String, dynamic>> assignedTasks = [];
  List<int> completedTaskIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {    
    final db = await DatabaseHelper.instance.database;
    
    final results = await db.query(
      'tasks',
      columns: ['id'],
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [widget.userId],
    );
    
    setState(() {
      completedTaskIds = results.map((e) => e['id'] as int).toList();
    });
    print('Planning Completed task IDs: $completedTaskIds');
  }

  Future<void> _loadTasks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Kullanıcının aktif task'larını al
      final allTasks = await db.query(
        'tasks',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [widget.userId],
        orderBy: 'created_at DESC',
      );

      // Bu plana atanmış task'ları al
      final assignedTaskIds = await db.rawQuery('''
        SELECT t.*, pt.id as plan_task_id
        FROM tasks t
        INNER JOIN plan_tasks pt ON t.id = pt.task_id
        WHERE pt.plan_id = ?
        ORDER BY t.created_at DESC
      ''', [widget.plan['id']]);

      // Atanmış task ID'lerini topla
      final assignedIds = assignedTaskIds.map((t) => t['id']).toSet();

      // Henüz atanmamış task'ları filtrele (sadece tamamlanmamış olanlar)
      final available = allTasks.where((task) => 
        !assignedIds.contains(task['id']) && 
        !completedTaskIds.contains(task['id'])
      ).toList();

      if (mounted) {
        setState(() {
          availableTasks = available;
          assignedTasks = assignedTaskIds;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Task yükleme hatası: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTask(int taskId, bool isCompleted) async {
    print('Plan Task tıklandı: ID=$taskId, yeni durum=$isCompleted');
    
    try {
      // DatabaseHelper'daki toggleTaskCompletion fonksiyonunu kullan
      final result = await DatabaseHelper.instance.toggleTaskCompletion(
        taskId, 
        widget.userId, 
        isCompleted
      );
      
      print('DB sonucu: $result');
      
      if (result['success'] == true) {        
        // Coin ödülü animasyonu
        if (result['coinReward'] > 0) {
          print('Coin ödülü verildi: +${result['coinReward']}');
          if (mounted) {
            CoinAnimationOverlay.showCoinDrop(context, result['coinReward']);
          }
        }
        
        // Parent'ı bilgilendir (coin güncelleme için)
        if (widget.onTaskCompleted != null) {
          widget.onTaskCompleted!();
        }
        
        // Achievment kontrolü
        if (isCompleted) {
          await DatabaseHelper.instance.checkAndUnlockAchievements(widget.userId);
        }

        // Local state'i güncelle
        setState(() {
          if (isCompleted) {
            completedTaskIds.add(taskId);
          } else {
            completedTaskIds.remove(taskId);
          }
        });
        
        print('Planning task toggle tamamlandı');
      } else {
        print('Task toggle başarısız: ${result['error']}');
      }
    } catch (e) {
      print('Planning task toggle hatası: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  // Atanmış task'ları sırala: tamamlanmayanlar önce
  List<Map<String, dynamic>> _sortAssignedTasks() {
    final notCompleted = assignedTasks.where((task) => 
      !completedTaskIds.contains(task['id'])
    ).toList();
    
    final completed = assignedTasks.where((task) => 
      completedTaskIds.contains(task['id'])
    ).toList();
    
    return [...notCompleted, ...completed];
  }

  @override
  Widget build(BuildContext context) {
    final sortedAssignedTasks = _sortAssignedTasks();

    return Dialog(
      backgroundColor: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Tasks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${widget.plan['time_slot']} - ${widget.plan['title']}',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Atanmış Task'lar Listesi
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                  : sortedAssignedTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No tasks assigned yet',
                                style: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add tasks using the button below',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: 8),
                              
                              // Atanmış tasklar
                              ...sortedAssignedTasks.map((task) {
                                final isCompleted = completedTaskIds.contains(task['id']);
                                return _buildTodoStyleTask(task, isCompleted);
                              }),
                              
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),

            // Add Task Button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAvailableTasksDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF06B6D4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Add Task to Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Task item
  Widget _buildTodoStyleTask(Map<String, dynamic> task, bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(task['id'], !isCompleted),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Color(0xFF1A1A1A), size: 18)
                  : null,
            ),
          ),
          SizedBox(width: 16),
          
          // Task container
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Color(0xFF404040) 
                    : Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isCompleted ? null : [
                  BoxShadow(
                    color: Color(0xFF06B6D4).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                task['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Available Tasks Dialog
  void _showAvailableTasksDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎯 Başlık
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Tasks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Available Tasks List
              Expanded(
                child: availableTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No available tasks',
                              style: TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create tasks in TODO screen first',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableTasks.length,
                        itemBuilder: (context, index) {
                          final task = availableTasks[index];
                          return _buildAvailableTaskCard(task);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF06B6D4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          task['title'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: task['description'] != null && task['description'].toString().isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  task['description'],
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: ElevatedButton(
          onPressed: () {
            _assignTaskToPlan(task['id']);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10B981),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _assignTaskToPlan(int taskId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.insert('plan_tasks', {
        'plan_id': widget.plan['id'],
        'task_id': taskId,
      });

      _loadTasks(); // Listeyi yenile
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task assigned to plan!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Task atama hatası: $e');
    }
  }
}
