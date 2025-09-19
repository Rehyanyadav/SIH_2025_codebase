// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:convert'; // Unused
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/firebase_service.dart';
import 'core/auth_service.dart';
import 'core/test_data.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/admin_register_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'admin_dashboard_page.dart';

// Conditional import for web CSV download
import 'web_csv_download_stub.dart'
    if (dart.library.html) 'web_csv_download.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline_attendance');
  await FirebaseService.initialize();
  // await seedTestData(); // Removed: no random attendance in Firebase
  await syncOfflineAttendance();
  runApp(const AttendanceApp());
}

Future<void> syncOfflineAttendance() async {
  final box = Hive.box('offline_attendance');
  final List list = box.get('records', defaultValue: []) as List;
  if (list.isNotEmpty) {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      for (final record in List<Map>.from(list)) {
        await FirebaseFirestore.instance
            .collection('attendance')
            .add(Map<String, dynamic>.from(record));
      }
      await box.put('records', []);
    }
  }
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
        // '/reports': (context) => const ReportsScreen(), // Removed: now requires teacherName
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
        // Admin login: check for hardcoded admin or Firestore
        if (_nameController.text == 'admin@admin.com' &&
            _passwordController.text == 'admin123') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userRole: 'admin',
                userName: 'Administrator',
                userEmail: 'admin@admin.com',
              ),
            ),
          );
        } else {
          // Try Firestore admin login
          final user = await AuthService().signIn(
            _nameController.text,
            _passwordController.text,
          );
          if (user != null && user.role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  userRole: 'admin',
                  userName: user.name,
                  userEmail: user.email,
                ),
              ),
            );
          } else {
            setState(() {
              _error = 'Invalid admin credentials';
            });
          }
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
              builder: (context) => DashboardScreen(
                userRole: user.role,
                userName: user.name,
                userEmail: user.email,
              ),
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
  final String userEmail;
  const DashboardScreen({
    super.key,
    this.userRole = 'teacher',
    this.userName = '',
    this.userEmail = '',
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceScreen(
                      userName: userName,
                      userRole: userRole,
                      userEmail: userEmail,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('View Reports'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReportsScreen(teacherEmail: userEmail),
                  ),
                ),
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

// --- AttendanceScreen ---
class AttendanceScreen extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  const AttendanceScreen({
    Key? key,
    this.userName = '',
    this.userRole = 'student',
    this.userEmail = '',
  }) : super(key: key);

  void _markAttendance(
    BuildContext context,
    String method, {
    String? scannedUser,
  }) async {
    final actualUser = scannedUser ?? userName;
    AttendanceStore().add(actualUser, method);
    // Save to Firestore with teacherEmail as the logged-in teacher
    await FirebaseFirestore.instance.collection('attendance').add({
      'userName': actualUser, // student roll number
      'date': DateTime.now().toIso8601String(),
      'method': method,
      'teacherEmail': userEmail, // teacher's email for filtering
    });
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
                if (result is String && result.isNotEmpty) {
                  _markAttendance(context, 'barcode', scannedUser: result);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text('Face Recognition (Mobile Only)'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Not Supported'),
                    content: const Text(
                      'Face recognition is only available on Android/iOS mobile devices.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
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
  // Add controller to adjust detection settings
  final ms.MobileScannerController _controller = ms.MobileScannerController(
    detectionSpeed: ms.DetectionSpeed.noDuplicates, // More reliable
    formats: [ms.BarcodeFormat.all], // Accept all barcode types
    facing: ms.CameraFacing.back,
    torchEnabled: false,
    autoStart: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Column(
        children: [
          Expanded(
            child: ms.MobileScanner(
              controller: _controller,
              fit: BoxFit.contain,
              onDetect: (capture) async {
                final code = capture.barcodes.first.rawValue;
                if (code != null && !scanned) {
                  setState(() {
                    barcode = code;
                    scanned = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Attendance marked for: $code')),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.pop(context, code); // Return scanned code
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () => _controller.toggleTorch(),
                tooltip: 'Toggle Flash',
              ),
              IconButton(
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => _controller.switchCamera(),
                tooltip: 'Switch Camera',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Face Recognition Page (Demo) ---
class FaceRecognitionPage extends StatefulWidget {
  final String userName;
  FaceRecognitionPage({Key? key, required this.userName}) : super(key: key);

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  File? _image;
  bool detected = false;

  @override
  void initState() {
    super.initState();
    // Prompt for live photo as soon as the page opens
    Future.microtask(_pickImage);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Here you would add face recognition logic
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
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 24),
            if (_image != null) Image.file(_image!, width: 200, height: 200),
            if (_image == null) const Text('No image selected.'),
          ],
        ),
      ),
    );
  }
}

// --- User Management Screen ---
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: const Center(child: Text('User management features go here.')),
    );
  }
}

// --- Reports Screen ---
class ReportsScreen extends StatefulWidget {
  final String teacherEmail;
  const ReportsScreen({Key? key, required this.teacherEmail}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  String _filterDate = '';
  String _searchRollNo = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherAttendance();
  }

  Future<void> _fetchTeacherAttendance() async {
    setState(() => _isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('attendance')
          .where('teacherEmail', isEqualTo: widget.teacherEmail)
          .get();

      _allRecords = query.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Sort by date in memory instead of in Firestore query
      _allRecords.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date'] ?? '');
          final dateB = DateTime.parse(b['date'] ?? '');
          return dateB.compareTo(dateA); // descending order (newest first)
        } catch (_) {
          return 0;
        }
      });

      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        // Filter by date
        if (_filterDate.isNotEmpty) {
          try {
            final recordDate = DateTime.parse(record['date']);
            final filterDate = DateTime.parse(_filterDate);
            if (recordDate.year != filterDate.year ||
                recordDate.month != filterDate.month ||
                recordDate.day != filterDate.day) {
              return false;
            }
          } catch (_) {
            return false;
          }
        }

        // Filter by roll number
        if (_searchRollNo.isNotEmpty) {
          final userName = record['userName']?.toString().toLowerCase() ?? '';
          if (!userName.contains(_searchRollNo.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _deleteAttendance(String recordId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text(
          'Are you sure you want to delete the attendance record for "$studentName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(recordId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance record for "$studentName" deleted'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the data
        _fetchTeacherAttendance();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Roll Number,Date,Time,Method');
    for (final r in _filteredRecords) {
      final dateTime = _formatDateTime(r['date']);
      buffer.writeln('"${r['userName']}","$dateTime","${r['method']}"');
    }
    final csv = buffer.toString();

    if (kIsWeb) {
      downloadCsvWeb(csv, 'attendance_${widget.teacherEmail}_export.csv');
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/attendance_${widget.teacherEmail}_export.csv',
        );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports'), elevation: 2),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Roll Number',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _searchRollNo = value;
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Filter by Date (YYYY-MM-DD)',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _filterDate = value;
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _fetchTeacherAttendance,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download CSV'),
                      onPressed: _filteredRecords.isNotEmpty
                          ? _downloadCsv
                          : null,
                    ),
                    const Spacer(),
                    Text('Total: ${_filteredRecords.length} records'),
                  ],
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _allRecords.isEmpty
                              ? 'No attendance records found for your account'
                              : 'No records match your current filters',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allRecords.isEmpty
                              ? 'Start taking attendance to see reports here'
                              : 'Try adjusting your search criteria',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      final isBarcode = (record['method'] ?? '') == 'barcode';
                      final recordId = record['id'] ?? '';
                      final studentName = record['userName'] ?? 'Unknown';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isBarcode
                                ? Colors.blue
                                : Colors.green,
                            child: Icon(
                              isBarcode ? Icons.qr_code : Icons.face,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'Roll No: $studentName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time: ${_formatDateTime(record['date'])}',
                              ),
                              Text(
                                'Method: ${record['method']?.toUpperCase() ?? 'Unknown'}',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete attendance record',
                                onPressed: () =>
                                    _deleteAttendance(recordId, studentName),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings features go here.')),
    );
  }
}
