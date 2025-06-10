import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await DatabaseHelper.instance.generateDailyTasksForUser(widget.userId);
    await _loadTasks();
    await _loadUserCoins();
    await _loadCompletedTasks();
  }

  Future<void> _loadTasks() async {
    final db = await DatabaseHelper.instance.database;

    final oneTimeResults = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ?',
      whereArgs: [widget.userId, 'one_time'],
      orderBy: 'id ASC',
    );
    
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

  Future<void> _loadUserCoins() async {
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
      await db.update(
        'tasks',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      
      await db.insert('task_completion', {
        'task_id': taskId,
      });
      
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
      await db.delete(
        'task_completion',
        where: 'task_id = ? AND DATE(completed_at) = ?',
        whereArgs: [taskId, DateTime.now().toIso8601String().split('T')[0]],
      );
      
      await db.update(
        'tasks',
        {'is_completed': 0},
        where: 'id = ?',
        whereArgs: [taskId],
      );
    }
    
    _loadCompletedTasks();
    _loadTasks();
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
      // Status bar'ı koyu yap
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Color(0xFF1A1A1A), // Üst bar ile aynı renk
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF1A1A1A), // Status bar rengi
            statusBarIconBrightness: Brightness.light, // İkonlar beyaz
            statusBarBrightness: Brightness.dark, // iOS için
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 46, 46, 46), // Tek renk
            ],
            stops: [1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🎯 Üst Bar - Alt navigation ile aynı arka plan
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A), // Alt navigation ile aynı renk
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 2), // Aşağı doğru gölge
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // ⚙️ Settings icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF404040),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    
                    // 📝 TO DO LIST başlığı - Dinamik genişlik
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'TO DO LIST',
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
                    
                    // 🔥 Streak counter
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
                              '$streakCount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text('🔥', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🎯 Task Listesi - Canva tasarımına uygun
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      
                      // One-time tasks
                      ...sortedOneTimeTasks.map((task) => _buildTaskItem(
                        task['id'],
                        task['title'] ?? 'to do',
                        completedTaskIds.contains(task['id']),
                        false, // one-time task
                      )),
                      
                      // Ayırıcı - Canva'da görünen çizgi
                      if (sortedOneTimeTasks.isNotEmpty && sortedDailyTasks.isNotEmpty)
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 20),
                          height: 1,
                          color: Color(0xFF404040),
                        ),
                      
                      // Daily tasks
                      ...sortedDailyTasks.map((task) => _buildTaskItem(
                        task['id'],
                        task['title'] ?? 'daily',
                        completedTaskIds.contains(task['id']),
                        true, // daily task
                      )),
                      
                      SizedBox(height: 100), // Alt navigation için boşluk
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 🎯 Floating Action Button - Canva tasarımına uygun
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
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
              isActive: true,
              onTap: () {},
            ),
            _buildNavButton(
              icon: Icons.assignment_outlined,
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
            SizedBox(width: 70),
            _buildNavButton(
              icon: Icons.person_outline,
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
    );
  }

  // Task Item
  Widget _buildTaskItem(int taskId, String title, bool isCompleted, bool isDaily) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTask(taskId, !isCompleted),
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
                    : Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isCompleted ? null : [
                  BoxShadow(
                    color: Color(0xFF4F46E5).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                title,
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

  // Navigation Button  
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
          color: Color(0xFF6B7280),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
      'type': 'one_time',
      'coin_reward': 5,
    });

    widget.onTaskAdded();
    Navigator.pop(context);
    
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
