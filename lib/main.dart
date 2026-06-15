// ignore_for_file: use_build_context_synchronously


import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const backendBaseUrl = 'http://localhost:3000';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  runApp(
    LiquidGlassWidgets.wrap(
      child: const MainApp(),
      adaptiveQuality: true, // auto-benchmarks device, degrades gracefully
      theme: GlassThemeData.simple(
        // optional app-wide glass defaults
        blur: 10,
        thickness: 30,
        quality: GlassQuality.premium,
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      // The first screen shown is the login page.
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  static const String _validUsername = '1';
  static const String _validPassword = '1';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Validate the entered credentials.
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกทั้ง Username และ Password';
      });
      return;
    }

    if (username == _validUsername && password == _validPassword) {
      // Route to the home page after successful login.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return;
    }

    setState(() {
      _errorMessage = 'Username หรือ Password ไม่ถูกต้อง';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: Image.asset('../assets/wallpaper2.jpg', fit: BoxFit.cover),
      appBar: GlassAppBar(title: const Text('Login')),
      statusBarStyle: GlassStatusBarStyle.light,
      body: GlassContainer(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GlassTextField(
              controller: _usernameController,
              placeholder: 'Username2',
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _passwordController,
              placeholder: "Password2",
              obscureText: true,
            ),
            const SizedBox(height: 16),

            GlassButton.custom(
              onTap: _attemptLogin,
              shape: LiquidRoundedRectangle(borderRadius: 12),
              glowHitTestBehavior: HitTestBehavior.translucent,
              style: GlassButtonStyle.filled,
              ambientBaseLight: 0.08,
              child: Text('Login'),
            ),

            // GlassButton(
            //   settings: LiquidGlassSettings(
                
            //   ),
            //   enabled: true,
            //   icon: Icon(Icons.play_arrow),
            //   onTap: _attemptLogin,
            //   label: 'Login',
            //   iconColor: Colors.greenAccent,
            //   style: GlassButtonStyle.filled,
            //   glowHitTestBehavior: HitTestBehavior.opaque,
            //   shape: LiquidRoundedRectangle(borderRadius: 12),
            // ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'ทดสอบ: Username = 1, Password = 1',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class Habit {
  final int id;
  final String title;
  final String details;
  bool done;

  Habit({
    required this.id,
    required this.title,
    required this.details,
    required this.done,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as int,
    title: json['title'] as String,
    details: json['details'] as String? ?? '',
    done: json['done'] as bool,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Habit> _habits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(Uri.parse('$backendBaseUrl/habits'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _habits.clear();
          _habits.addAll(
            data.map((json) => Habit.fromJson(json as Map<String, dynamic>)),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load habits';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateHabitStatus(Habit habit, bool newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$backendBaseUrl/habits/${habit.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'done': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          habit.done = newStatus;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update habit')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มรายการ'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'ชื่อ'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final response = await http.post(
                    Uri.parse('$backendBaseUrl/habits'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'details': detailsController.text.trim(),
                      'done': false,
                    }),
                  );

                  if (response.statusCode == 201) {
                    final newHabit = Habit.fromJson(jsonDecode(response.body));
                    setState(() {
                      _habits.insert(0, newHabit);
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add habit')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailDialog(Habit habit) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(habit.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รายละเอียด:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(habit.details.isNotEmpty ? habit.details : 'ไม่มีรายละเอียด'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('สถานะ: '),
                Text(habit.done ? 'สำเร็จ' : 'ยังไม่เสร็จ'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: Image.asset('../assets/wallpaper2.jpg', fit: BoxFit.cover),
      appBar: GlassAppBar(
        title: const Text('LiquidGlass Test'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHabits),
        ],
        preferredSize: const Size.fromHeight(60.0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHabits,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            )
          : _habits.isEmpty
          ? const Center(child: Text('ยังไม่มีรายการ'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                return GlassCard(
                  margin: EdgeInsetsDirectional.only(bottom: 20),
                  child: InkWell(
                    onTap: () => _showDetailDialog(habit),
                    child: CheckboxListTile(
                      value: habit.done,
                      onChanged: (v) => _updateHabitStatus(habit, v ?? false),
                      title: Text(habit.title),
                      subtitle: habit.details.isNotEmpty
                          ? Text(habit.details)
                          : null,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: GlassButton(onTap: _showAddDialog, icon: Icon(Icons.add),),
    );
  }
}

class AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
