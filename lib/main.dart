// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/constants.dart';
import 'core/firebase_service.dart';
import 'core/auth_service.dart';
import 'core/test_data.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/admin_register_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await seedTestData(); // Seed demo data for testing
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edutrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.teal,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.teal,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.teal.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin-register': (context) => const AdminRegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/users': (context) => const UserManagementScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

// Placeholder screens for each module
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (_selectedRole == null ||
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all fields and select a role.'),
        ),
      );
      return;
    }
    try {
      if (_selectedRole == 'admin') {
        // Admin login: check Firestore for admin user
        final user = await AuthService().signIn(
          _nameController.text,
          _passwordController.text,
        );
        if (user != null && user.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DashboardScreen(userRole: 'admin', userName: user.name),
            ),
          );
        } else {
          setState(() {
            _error = 'Invalid admin credentials';
          });
        }
      } else {
        // Teacher: check Firestore for user
        final user = await AuthService().signIn(
          _nameController.text,
          _passwordController.text,
        );
        if (user != null && user.role == _selectedRole) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DashboardScreen(userRole: user.role, userName: user.name),
            ),
          );
        } else {
          // Not registered, prompt to register
          final shouldRegister = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Not Registered'),
              content: const Text(
                'User not found. Would you like to register?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Register'),
                ),
              ],
            ),
          );
          if (shouldRegister == true) {
            Navigator.pushNamed(context, '/register');
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edutrack',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Select Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  ],
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Not registered? Register here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String userRole;
  final String userName;
  const DashboardScreen({
    super.key,
    this.userRole = 'teacher',
    this.userName = '',
  });

  String get _roleLabel {
    switch (userRole) {
      case 'admin':
        return 'Admin';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      default:
        return userRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == 'admin') {
      return const AdminDashboardPage();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ($_roleLabel)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Role: $_roleLabel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            if (userRole == 'teacher') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Attendance'),
                onPressed: () => Navigator.pushNamed(context, '/attendance'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('View Reports'),
                onPressed: () => Navigator.pushNamed(context, '/reports'),
              ),
            ] else if (userRole == 'student') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Attendance'),
                onPressed: () => Navigator.pushNamed(context, '/attendance'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('View My Attendance'),
                onPressed: () => Navigator.pushNamed(context, '/reports'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- AttendanceScreen with slot selection ---
class AttendanceScreen extends StatelessWidget {
  final String userName;
  final String userRole;
  const AttendanceScreen({
    super.key,
    this.userName = '',
    this.userRole = 'student',
  });

  void _markAttendance(
    BuildContext context,
    String method, [
    String slot = '',
  ]) {
    AttendanceStore().add(userName, method);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Attendance marked by $method!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BarcodeScannerPage(),
                  ),
                );
                if (result == true) _markAttendance(context, 'barcode', '');
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text('Face Recognition'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FaceRecognitionPage(),
                  ),
                );
                if (result == true) _markAttendance(context, 'face', '');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- In-memory Attendance Store ---
class AttendanceRecord {
  final String userName;
  final DateTime date;
  final String method; // 'barcode' or 'face'
  AttendanceRecord(this.userName, this.date, this.method);
}

class AttendanceStore {
  static final AttendanceStore _instance = AttendanceStore._();
  factory AttendanceStore() => _instance;
  AttendanceStore._();
  final List<AttendanceRecord> _records = [];
  void add(String userName, String method) {
    // Remove any previous record for this user/date (only one per day)
    _records.removeWhere(
      (r) =>
          r.userName == userName &&
          r.date.year == DateTime.now().year &&
          r.date.month == DateTime.now().month &&
          r.date.day == DateTime.now().day,
    );
    _records.add(AttendanceRecord(userName, DateTime.now(), method));
  }

  // Removed all slot-based helpers

  List<AttendanceRecord> forUser(String userName) =>
      _records.where((r) => r.userName == userName).toList();
  List<AttendanceRecord> all() => List.unmodifiable(_records);
}

// --- Barcode Scanner Page ---
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String? barcode;
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final code = capture.barcodes.first.rawValue;
                if (code != null && !scanned) {
                  setState(() {
                    barcode = code;
                    scanned = true;
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Barcode: $code')));
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.pop(context, true);
                  });
                }
              },
            ),
          ),
          if (barcode != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Scanned: $barcode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Face Recognition Page (Demo) ---
class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});
  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  File? _image;
  String? _result;
  bool detected = false;

  @override
  void initState() {
    super.initState();
    // Prompt for live photo as soon as the page opens
    Future.microtask(_pickImage);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      await _detectFaces(File(picked.path));
    }
  }

  Future<void> _detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);
    setState(() {
      _result = faces.isNotEmpty
          ? 'Face(s) detected: ${faces.length}'
          : 'No face detected.';
      detected = faces.isNotEmpty;
    });
    faceDetector.close();
    if (detected) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, width: 200)
                : const Icon(Icons.face, size: 100),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Capture Face'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(_result!, style: Theme.of(context).textTheme.titleMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teachers found.'));
          }
          final teachers = snapshot.data!.docs;
          return ListView.separated(
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final doc = teachers[i];
              return ListTile(
                title: Text(doc['name'] ?? ''),
                subtitle: Text(doc['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Teacher'),
                        content: Text(
                          'Are you sure you want to delete ${doc['name']}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .delete();
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/users');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  Future<void> _exportCSV(BuildContext context) async {
    final records = AttendanceStore().all();
    final buffer = StringBuffer();
    buffer.writeln('Name,Date,Method');
    for (final r in records) {
      buffer.writeln(
        '"${r.userName}","${r.date.toIso8601String()}","${r.method}"',
      );
    }
    final csv = buffer.toString();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/attendance_export.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Attendance Data Export');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  final String userName;
  final String userRole;
  const ReportsScreen({
    super.key,
    this.userName = '',
    this.userRole = 'student',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        actions: [
          if (userRole == 'admin' || userRole == 'teacher')
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: () => _exportCSV(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: userRole == 'admin'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'student')
                        .get(),
                    builder: (context, studentSnap) {
                      if (studentSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final students = studentSnap.data?.docs ?? [];
                      return Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Students: ${students.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.bar_chart),
                                label: const Text('Analytics & Reports'),
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/reports'),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LMS Analytics',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('attendance')
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          }
                                          final records =
                                              snapshot.data?.docs ?? [];
                                          final totalAttendance =
                                              records.length;
                                          final uniqueStudents = <String>{};
                                          for (final doc in records) {
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            if (data['userName'] != null)
                                              uniqueStudents.add(
                                                data['userName'],
                                              );
                                          }
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Attendance Records: $totalAttendance',
                                              ),
                                              Text(
                                                'Unique Students Attended: ${uniqueStudents.length}',
                                              ),
                                              // Add more analytics as needed
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('attendance')
                        .get(),
                    builder: (context, attSnap) {
                      if (attSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final records = attSnap.data?.docs ?? [];
                      if (records.isEmpty) {
                        return const Text('No attendance records found.');
                      }
                      final freq = <String, int>{};
                      for (final doc in records) {
                        final data = doc.data() as Map<String, dynamic>;
                        final studentId =
                            data['studentId'] ?? data['userId'] ?? data['id'];
                        if (studentId != null) {
                          freq[studentId] = (freq[studentId] ?? 0) + 1;
                        }
                      }
                      return Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Frequency per Student',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...freq.entries.map(
                                (e) => Text(
                                  'Student ID: ${e.key}, Attendance Records: ${e.value}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('attendance')
                          .get(),
                      builder: (context, attSnap) {
                        if (attSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final records = attSnap.data?.docs ?? [];
                        if (records.isEmpty) {
                          return const Text('No attendance records found.');
                        }
                        return ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final r = records[i].data() as Map<String, dynamic>;
                            if (r['method'] != null && r['date'] != null) {
                              return ListTile(
                                leading: Icon(
                                  (r['method'] ?? '') == 'barcode'
                                      ? Icons.qr_code
                                      : Icons.face,
                                ),
                                title: Text(
                                  r['userName'] ??
                                      r['studentName'] ??
                                      r['name'] ??
                                      '',
                                ),
                                subtitle: Text(
                                  '${r['method'] ?? ''} | ${r['date'] ?? ''}',
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            : FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('userName', isEqualTo: userName)
                    .get(),
                builder: (context, attSnap) {
                  if (attSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final records = attSnap.data?.docs ?? [];
                  if (records.isEmpty) {
                    return const Center(
                      child: Text('No attendance records yet.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final r = records[i].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: Icon(
                          (r['method'] ?? '') == 'barcode'
                              ? Icons.qr_code
                              : Icons.face,
                        ),
                        title: Text(
                          r['userName'] ?? r['studentName'] ?? r['name'] ?? '',
                        ),
                        subtitle: Text(
                          '${r['method'] ?? ''} | ${r['date'] ?? ''}',
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
