import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin LMS Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('attendance').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data?.docs ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Text('No attendance records found.'),
                  );
                }
                // Build frequency map and student names
                final freq = <String, int>{};
                final studentNames = <String, String>{};
                int activeToday = 0;
                final today = DateTime.now();
                final classMap = <String, List<Map<String, dynamic>>>{};
                for (final doc in records) {
                  final data = doc.data() as Map<String, dynamic>;
                  final studentId =
                      data['userId'] ?? data['studentId'] ?? data['id'];
                  final name =
                      data['userName'] ??
                      data['studentName'] ??
                      data['name'] ??
                      studentId;
                  final dateStr = data['date'] ?? '';
                  final className = data['class'] ?? 'Unknown';
                  DateTime? date;
                  try {
                    date = DateTime.parse(dateStr);
                  } catch (_) {}
                  if (studentId != null) {
                    freq[studentId] = (freq[studentId] ?? 0) + 1;
                    studentNames[studentId] = name;
                    if (date != null &&
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day) {
                      activeToday++;
                    }
                    classMap.putIfAbsent(className, () => []).add(data);
                  }
                }
                final chartData = freq.entries.toList();

                // --- Attendance Trends (Line Chart Data) ---
                final Map<String, int> dateCounts = {};
                for (final doc in records) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateStr = data['date'] ?? '';
                  if (dateStr.isNotEmpty) {
                    final d = dateStr.split('T').first;
                    dateCounts[d] = (dateCounts[d] ?? 0) + 1;
                  }
                }
                final sortedDates = dateCounts.keys.toList()..sort();
                final lineSpots = List.generate(
                  sortedDates.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    dateCounts[sortedDates[i]]!.toDouble(),
                  ),
                );

                // --- Low Attendance Alerts ---
                final lowAttendance = chartData
                    .where((e) => e.value < 5)
                    .toList();

                // --- Top Attendees ---
                final topAttendees = List<MapEntry<String, int>>.from(
                  chartData,
                );
                topAttendees.sort((a, b) => b.value.compareTo(a.value));
                final top5 = topAttendees.take(5).toList();

                // --- Filter/Search Bar ---
                final filterController = TextEditingController();
                // ); // End of FutureBuilder
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter/Search Bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: filterController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search by student, class, or date...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  // For real filter, use setState in StatefulWidget
                                },
                              ),
                            ),
                            if (isWide) ...[
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download),
                                label: const Text('Export CSV'),
                                onPressed: () {}, // TODO: Implement export
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Attendance Trends Line Chart
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.show_chart,
                                    color: Colors.deepPurple,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Attendance Trends',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 180,
                                child: LineChart(
                                  LineChartData(
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: lineSpots,
                                        isCurved: true,
                                        color: Colors.deepPurple,
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 ||
                                                idx >= sortedDates.length)
                                              return const SizedBox.shrink();
                                            return Text(
                                              sortedDates[idx].substring(5),
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Low Attendance Alerts
                      if (lowAttendance.isNotEmpty) ...[
                        Card(
                          elevation: 2,
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.warning, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Low Attendance Alerts',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...lowAttendance.map(
                                  (e) => Text(
                                    '${studentNames[e.key] ?? e.key}: ${e.value} days',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Top Attendees Leaderboard
                      Card(
                        elevation: 2,
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Top Attendees',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...top5.map(
                                (e) => Text(
                                  '${studentNames[e.key] ?? e.key}: ${e.value} days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LMSCard(
                            label: 'Total Students',
                            icon: Icons.people,
                            color: Colors.teal,
                            value: studentNames.length.toString(),
                          ),
                          _LMSCard(
                            label: 'Active Today',
                            icon: Icons.today,
                            color: Colors.orange,
                            value: activeToday.toString(),
                          ),
                          _LMSCard(
                            label: 'Avg. Attendance',
                            icon: Icons.bar_chart,
                            color: Colors.blue,
                            value:
                                (records.length /
                                        (studentNames.length == 0
                                            ? 1
                                            : studentNames.length))
                                    .toStringAsFixed(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.bar_chart, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text(
                                    'Attendance by Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barTouchData: BarTouchData(enabled: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                final idx = value.toInt();
                                                if (idx < 0 ||
                                                    idx >= chartData.length)
                                                  return const SizedBox.shrink();
                                                final studentId =
                                                    chartData[idx].key;
                                                final name =
                                                    studentNames[studentId] ??
                                                    studentId;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    name.length > 8
                                                        ? name.substring(0, 8) +
                                                              '…'
                                                        : name,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(chartData.length, (
                                      i,
                                    ) {
                                      final entry = chartData[i];
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value.toDouble(),
                                            color: Colors.teal,
                                            width: 18,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ],
                                        showingTooltipIndicators: [0],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Raw Attendance Records',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: records.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, i) {
                                  final r =
                                      records[i].data() as Map<String, dynamic>;
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
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LMSCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? value;
  const _LMSCard({
    required this.label,
    required this.icon,
    required this.color,
    this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 110,
        height: 110,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            if (value != null) ...[
              const SizedBox(height: 8),
              Text(
                value!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
            ] else ...[
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
