import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            color: Theme.of(context).cardColor,
            child: _buildSidebar(),
          ),
          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Collapsed Sidebar
          Container(
            width: 80,
            color: Theme.of(context).cardColor,
            child: _buildCollapsedSidebar(),
          ),
          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Admin LMS Dashboard'),
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
          onPressed: () => setState(() {}),
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Export All Data',
          onPressed: _exportAllData,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Colors.teal,
          child: Icon(
            Icons.admin_panel_settings,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Administrator',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        _buildSidebarItem(0, Icons.dashboard, 'Overview'),
        _buildSidebarItem(1, Icons.people, 'Faculty Management'),
        _buildSidebarItem(2, Icons.school, 'Student Analytics'),
        _buildSidebarItem(3, Icons.analytics, 'Reports & Data'),
      ],
    );
  }

  Widget _buildCollapsedSidebar() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.teal,
          child: Icon(
            Icons.admin_panel_settings,
            size: 25,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        _buildCollapsedSidebarItem(0, Icons.dashboard),
        _buildCollapsedSidebarItem(1, Icons.people),
        _buildCollapsedSidebarItem(2, Icons.school),
        _buildCollapsedSidebarItem(3, Icons.analytics),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.teal : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.teal : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.teal.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildCollapsedSidebarItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: IconButton(
        icon: Icon(icon, color: isSelected ? Colors.teal : Colors.grey[600]),
        onPressed: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Faculty'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminOverviewTab();
      case 1:
        return const FacultyManagementTab();
      case 2:
        return const StudentAnalyticsTab();
      case 3:
        return const ReportsDataTab();
      default:
        return const AdminOverviewTab();
    }
  }

  Future<void> _exportAllData() async {
    // Implementation for exporting all data
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting all data...')));
  }
}

// Overview Tab with Summary Cards and Key Metrics
class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, attendanceSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting ||
                usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final attendanceRecords = attendanceSnapshot.data?.docs ?? [];
            final users = usersSnapshot.data?.docs ?? [];
            final teachers = users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['role'] == 'teacher';
            }).toList();

            // Calculate metrics
            final totalAttendance = attendanceRecords.length;
            final totalTeachers = teachers.length;
            final uniqueStudents = attendanceRecords
                .map((doc) => (doc.data() as Map<String, dynamic>)['userName'])
                .where((name) => name != null)
                .toSet()
                .length;

            // Today's attendance
            final today = DateTime.now();
            final todayAttendance = attendanceRecords.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              try {
                final date = DateTime.parse(data['date'] ?? '');
                return date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
              } catch (_) {
                return false;
              }
            }).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 800
                          ? 3
                          : constraints.maxWidth > 600
                          ? 2
                          : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildSummaryCard(
                            'Total Attendance',
                            totalAttendance.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildSummaryCard(
                            'Active Teachers',
                            totalTeachers.toString(),
                            Icons.person,
                            Colors.blue,
                          ),
                          _buildSummaryCard(
                            'Students',
                            uniqueStudents.toString(),
                            Icons.school,
                            Colors.orange,
                          ),
                          _buildSummaryCard(
                            "Today's Attendance",
                            todayAttendance.toString(),
                            Icons.today,
                            Colors.purple,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildQuickAction(
                                'Add Faculty',
                                Icons.person_add,
                                Colors.blue,
                                () => _showAddFacultyDialog(context),
                              ),
                              _buildQuickAction(
                                'Export Data',
                                Icons.download,
                                Colors.green,
                                () => _exportData(context),
                              ),
                              _buildQuickAction(
                                'View Reports',
                                Icons.analytics,
                                Colors.purple,
                                () => {}, // Navigate to reports
                              ),
                              _buildQuickAction(
                                'System Settings',
                                Icons.settings,
                                Colors.orange,
                                () => {}, // Navigate to settings
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity Chart
                  _buildRecentActivityChart(attendanceRecords),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildRecentActivityChart(List<QueryDocumentSnapshot> records) {
    // Group by date for the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );
    final attendanceByDay = <DateTime, int>{};

    for (final day in last7Days) {
      attendanceByDay[day] = 0;
    }

    for (final record in records) {
      final data = record.data() as Map<String, dynamic>;
      try {
        final date = DateTime.parse(data['date'] ?? '');
        final dayKey = DateTime(date.year, date.month, date.day);
        if (attendanceByDay.containsKey(dayKey)) {
          attendanceByDay[dayKey] = attendanceByDay[dayKey]! + 1;
        }
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Trend (Last 7 Days)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: attendanceByDay.entries.map((entry) {
                        final index = last7Days.indexOf(entry.key);
                        return FlSpot(index.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < last7Days.length) {
                            final date = last7Days[index];
                            return Text('${date.day}/${date.month}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFacultyDialog(BuildContext context) {
    // Implementation for adding faculty
    showDialog(
      context: context,
      builder: (context) => const AddFacultyDialog(),
    );
  }

  void _exportData(BuildContext context) {
    // Implementation for data export
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting data...')));
  }
}

// Faculty Management Tab with CRUD Operations
class FacultyManagementTab extends StatefulWidget {
  const FacultyManagementTab({Key? key}) : super(key: key);

  @override
  State<FacultyManagementTab> createState() => _FacultyManagementTabState();
}

class _FacultyManagementTabState extends State<FacultyManagementTab> {
  String _searchQuery = '';
  String _departmentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final teachers = snapshot.data?.docs ?? [];
        final filteredTeachers = teachers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          final department = data['department'] ?? '';

          final matchesSearch =
              name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());
          final matchesDepartment =
              _departmentFilter == 'All' || department == _departmentFilter;

          return matchesSearch && matchesDepartment;
        }).toList();

        // Get unique departments for filter
        final departments =
            ['All'] +
            teachers
                .map(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['department'] ??
                      'Unknown',
                )
                .toSet()
                .where((dept) => dept != 'Unknown')
                .cast<String>()
                .toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Faculty Management',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Faculty'),
                    onPressed: () => _showAddFacultyDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search and Filter Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search faculty...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _departmentFilter,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      items: departments
                          .map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _departmentFilter = value ?? 'All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Faculty Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Total Faculty',
                      teachers.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Active This Week',
                      _getActiveThisWeek(teachers).toString(),
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Departments',
                      (departments.length - 1).toString(), // Exclude 'All'
                      Icons.business,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Faculty List
              Expanded(
                child: filteredTeachers.isEmpty
                    ? const Center(
                        child: Text(
                          'No faculty members found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          return isWide
                              ? _buildFacultyDataTable(filteredTeachers)
                              : _buildFacultyList(filteredTeachers);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyDataTable(List<QueryDocumentSnapshot> teachers) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: teachers.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final email = data['email'] ?? 'Unknown';
            final department = data['department'] ?? 'Unknown';
            final isActive = _isTeacherActive(doc.id);

            return DataRow(
              cells: [
                DataCell(Text(name)),
                DataCell(Text(email)),
                DataCell(Text(department)),
                DataCell(
                  Chip(
                    label: Text(isActive ? 'Active' : 'Inactive'),
                    backgroundColor: isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isActive
                          ? Colors.green.shade800
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editFaculty(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFaculty(doc),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFacultyList(List<QueryDocumentSnapshot> teachers) {
    return ListView.builder(
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final doc = teachers[index];
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final email = data['email'] ?? 'Unknown';
        final department = data['department'] ?? 'Unknown';
        final isActive = _isTeacherActive(doc.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(email), Text('Department: $department')],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(isActive ? 'Active' : 'Inactive'),
                  backgroundColor: isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editFaculty(doc);
                    } else if (value == 'delete') {
                      _deleteFaculty(doc);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getActiveThisWeek(List<QueryDocumentSnapshot> teachers) {
    // Implementation to check active teachers this week
    return (teachers.length * 0.8).round(); // Placeholder
  }

  bool _isTeacherActive(String teacherId) {
    // Implementation to check if teacher is active
    return true; // Placeholder
  }

  void _showAddFacultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFacultyDialog(),
    );
  }

  void _editFaculty(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => EditFacultyDialog(facultyDoc: doc),
    );
  }

  void _deleteFaculty(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Are you sure you want to delete $name?'),
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
        await doc.reference.delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting faculty: $e')));
      }
    }
  }
}

// Student Analytics Tab
class StudentAnalyticsTab extends StatelessWidget {
  const StudentAnalyticsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data?.docs ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Analytics',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Analytics widgets
              _buildStudentStatsRow(records),
              const SizedBox(height: 24),
              _buildAttendanceTrendChart(records),
              const SizedBox(height: 24),
              _buildTopPerformersCard(records),
              const SizedBox(height: 24),
              _buildAttendanceHeatmap(records),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentStatsRow(List<QueryDocumentSnapshot> records) {
    final uniqueStudents = records
        .map((doc) => (doc.data() as Map<String, dynamic>)['userName'])
        .where((name) => name != null)
        .toSet()
        .length;

    final avgAttendance = records.isEmpty
        ? 0.0
        : records.length / uniqueStudents;
    final todayAttendance = _getTodayAttendance(records);

    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            'Total Students',
            uniqueStudents.toString(),
            Icons.school,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticsCard(
            'Avg Attendance',
            avgAttendance.toStringAsFixed(1),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnalyticsCard(
            'Today Present',
            todayAttendance.toString(),
            Icons.today,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendChart(List<QueryDocumentSnapshot> records) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Trend (Last 30 Days)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateTrendData(records),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersCard(List<QueryDocumentSnapshot> records) {
    final studentAttendance = <String, int>{};
    for (final record in records) {
      final data = record.data() as Map<String, dynamic>;
      final student = data['userName'] ?? 'Unknown';
      studentAttendance[student] = (studentAttendance[student] ?? 0) + 1;
    }

    final topPerformers = studentAttendance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers (by Attendance)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topPerformers
                .take(10)
                .map(
                  (entry) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(entry.key.isNotEmpty ? entry.key[0] : '?'),
                    ),
                    title: Text(entry.key),
                    trailing: Chip(
                      label: Text('${entry.value} days'),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHeatmap(List<QueryDocumentSnapshot> records) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Heatmap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Coming soon - Weekly attendance patterns'),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  int _getTodayAttendance(List<QueryDocumentSnapshot> records) {
    final today = DateTime.now();
    return records.where((record) {
      final data = record.data() as Map<String, dynamic>;
      try {
        final date = DateTime.parse(data['date'] ?? '');
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  List<FlSpot> _generateTrendData(List<QueryDocumentSnapshot> records) {
    // Generate sample trend data - replace with actual implementation
    return List.generate(
      30,
      (index) => FlSpot(index.toDouble(), (index * 2 + 10).toDouble()),
    );
  }
}

// Reports and Data Tab
class ReportsDataTab extends StatelessWidget {
  const ReportsDataTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Data Export',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Text('Advanced reporting features coming soon...'),
        ],
      ),
    );
  }
}

// Add Faculty Dialog
class AddFacultyDialog extends StatefulWidget {
  const AddFacultyDialog({Key? key}) : super(key: key);

  @override
  State<AddFacultyDialog> createState() => _AddFacultyDialogState();
}

class _AddFacultyDialogState extends State<AddFacultyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedDepartment = 'Computer Science';

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Mathematics',
    'Physics',
    'Chemistry',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Faculty'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departments
                    .map(
                      (dept) =>
                          DropdownMenuItem(value: dept, child: Text(dept)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addFaculty,
          child: const Text('Add Faculty'),
        ),
      ],
    );
  }

  void _addFaculty() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('users').add({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text, // In production, hash this!
          'role': 'teacher',
          'department': _selectedDepartment,
          'createdAt': DateTime.now().toIso8601String(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding faculty: $e')));
      }
    }
  }
}

// Edit Faculty Dialog
class EditFacultyDialog extends StatefulWidget {
  final QueryDocumentSnapshot facultyDoc;

  const EditFacultyDialog({Key? key, required this.facultyDoc})
    : super(key: key);

  @override
  State<EditFacultyDialog> createState() => _EditFacultyDialogState();
}

class _EditFacultyDialogState extends State<EditFacultyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedDepartment;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Mathematics',
    'Physics',
    'Chemistry',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.facultyDoc.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _selectedDepartment = data['department'] ?? _departments.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Faculty'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departments
                    .map(
                      (dept) =>
                          DropdownMenuItem(value: dept, child: Text(dept)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _updateFaculty, child: const Text('Update')),
      ],
    );
  }

  void _updateFaculty() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.facultyDoc.reference.update({
          'name': _nameController.text,
          'email': _emailController.text,
          'department': _selectedDepartment,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating faculty: $e')));
      }
    }
  }
}
