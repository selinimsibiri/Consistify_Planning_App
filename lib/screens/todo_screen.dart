import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/daily_screen.dart';
import 'package:sayfa_yonlendirme/screens/profile_screen.dart';

class TodoScreen extends StatefulWidget {
  final int userId;

  const TodoScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> oneTimeTasks = [];
  List<Map<String, dynamic>> dailyTasks = [];
  List<int> completedTaskIds = [];
  int userCoins = 0;
  int streakCount = 13;

  @override
  void initState() {
    super.initState();
    _initializeTodoScreen();
  }

  Future<void> _initializeTodoScreen() async {
    // 1. Önce daily'leri kontrol et ve oluştur
    await DatabaseHelper.instance.generateDailyTasksForUser(widget.userId);
    
    // 2. Sonra task'ları yükle
    await _loadTasks();
    await _loadUserCoins();
    await _loadCompletedTasks();
  }

  Future<void> _loadTasks() async {
    final db = await DatabaseHelper.instance.database;

    // One-time tasks
    final oneTimeResults = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ?',
      whereArgs: [widget.userId, 'one_time'],
      orderBy: 'id ASC',
    );
    
    // Daily tasks
    final dailyResults = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ?',
      whereArgs: [widget.userId, 'daily'],
      orderBy: 'id ASC',
    );
    setState(() {
      oneTimeTasks = oneTimeResults;
      dailyTasks = dailyResults;
    });
    print('📋 Yüklenen görevler: ${oneTimeTasks.length} one-time, ${dailyTasks.length} daily');
  }

  Future<void> _loadCompletedTasks() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // is_completed = 1 olan task'ları al
    final results = await db.query(
      'tasks',
      columns: ['id'],
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [widget.userId],
    );
    
    setState(() {
      completedTaskIds = results.map((e) => e['id'] as int).toList();
    });
  }

  Future<void> _loadUserCoins() async { //imdat
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: [widget.userId],
    );
    
    if (result.isNotEmpty) {
      setState(() {
        userCoins = result.first['coins'] as int;
      });
    }
  }

  Future<void> _toggleTask(int taskId, bool isCompleted) async {
    final db = await DatabaseHelper.instance.database;
    
    if (isCompleted) {
       // Task'ı tamamlandı olarak işaretle
      await db.update(
        'tasks',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      // Task'ı tamamlananlara kaydet. 
      //tarih eklenmeli mi? istatistikler için imdat
      await db.insert('task_completion', {
        'task_id': taskId,
      });
      
      // Coin ödülü ver
      final task = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
      if (task.isNotEmpty) {
        int coinReward = task.first['coin_reward'] as int;
        await db.update(
          'users',
          {'coins': userCoins + coinReward},
          where: 'id = ?',
          whereArgs: [widget.userId],
        );
        
        setState(() {
          userCoins += coinReward;
        });

        print('💰 Coin ödülü verildi: +$coinReward');
      }
    } else {
      // Task'ı tamamlanmamış olarak işaretle
      await db.delete( //burada ne oluyor amk imdat
        'task_completion',
        where: 'task_id = ? AND DATE(completed_at) = ?',
        whereArgs: [taskId, DateTime.now().toIso8601String().split('T')[0]],
      );
      
      // Task'ı tamamlanmamış olarak işaretle
      await db.update(
        'tasks',
        {'is_completed': 0},
        where: 'id = ?',
        whereArgs: [taskId],
      );
    }
    
    _loadCompletedTasks();
    _loadTasks(); // 🎯 Task listesini yenile
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AddTaskDialog(
          userId: widget.userId,
          onTaskAdded: _loadTasks,
        );
      },
    );
  }

  // 🎯 Görevleri sırala: Tamamlanmayanlar üstte, tamamlananlar altta
  List<Map<String, dynamic>> _sortTasks(List<Map<String, dynamic>> tasks) {
    final notCompleted = tasks.where((task) => 
      !completedTaskIds.contains(task['id'])
    ).toList();
    
    final completed = tasks.where((task) => 
      completedTaskIds.contains(task['id'])
    ).toList();
    
    return [...notCompleted, ...completed];
  }

  @override
  Widget build(BuildContext context) {
    final sortedOneTimeTasks = _sortTasks(oneTimeTasks);
    final sortedDailyTasks = _sortTasks(dailyTasks);

    return Scaffold(
      backgroundColor: Color(0xFF2D2D2D),
      body: SafeArea(
        child: Column(
          children: [
            // 🎯 Üst Bar
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 24),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TO DO LIST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$streakCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🔥', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🎯 Task Listesi
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // One-time tasks
                    ...sortedOneTimeTasks.map((task) => _buildTaskItem(
                      task['id'],
                      task['title'] ?? 'to do',
                      completedTaskIds.contains(task['id']),
                    )),
                    
                    // Ayırıcı çizgi
                    if (sortedOneTimeTasks.isNotEmpty && sortedDailyTasks.isNotEmpty)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        height: 1,
                        color: Colors.white24,
                      ),
                    
                    // Daily tasks
                    ...sortedDailyTasks.map((task) => _buildTaskItem(
                      task['id'],
                      task['title'] ?? 'daily',
                      completedTaskIds.contains(task['id']),
                    )),
                  ],
                ),
              ),
            ),

            // 🎯 Add Task Button
            Padding(
              padding: EdgeInsets.all(16),
              child: FloatingActionButton(
                onPressed: _showAddTaskDialog,
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),

            // 🎯 Alt Navigation Bar
            Container(
              height: 80,
              color: Color(0xFF2D2D2D),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    icon: Icons.check_circle,
                    color: Color(0xFF8B5CF6),
                    isActive: true,
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.assignment,
                    color: Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.home,
                    color: Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.trending_up,
                    color: Color(0xFFEC4899),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(int taskId, String title, bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(taskId, !isCompleted),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Color(0xFF8B5CF6) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted ? Color(0xFF8B5CF6) : Colors.white,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          SizedBox(width: 12),
          
          // Task container
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey[600] : Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final int userId;
  final VoidCallback onTaskAdded;

  const AddTaskDialog({
    Key? key,
    required this.userId,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF6B7280), // Gri renk
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Başlık Input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'to do name',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 🎯 Açıklama Input (Büyük)
            Container(
              height: 120,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'info',
                  hintStyle: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 🎯 Alt Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // İptal Butonu (X)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Ekle Butonu (+)
                GestureDetector(
                  onTap: _addTask,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
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

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      // Boş başlık uyarısı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen görev başlığı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('tasks', {
      'user_id': widget.userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'is_active': '1',
      'type': 'one_time', // Sadece one_time görevler
      'coin_reward': 5,
    });

    widget.onTaskAdded();
    Navigator.pop(context);
    
    // Başarı mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Görev başarıyla eklendi!'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
