import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/attendance.dart';
import '../../models/employee.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final Employee employee;
  const AttendanceHistoryScreen({super.key, required this.employee});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Attendance> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance
        .getAttendanceByEmployee(widget.employee.id!);
    setState(() {
      _list = data;
      _loading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'present': return Colors.green;
      case 'absent':  return Colors.red;
      case 'late':    return Colors.orange;
      case 'half_day': return Colors.blue;
      default:        return Colors.grey;
    }
  }

  Map<String, int> get _summary {
    final m = <String, int>{};
    for (final a in _list) {
      m[a.status] = (m[a.status] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử - ${widget.employee.fullName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: const Color(0xFF1565C0),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Chip('Có mặt', s['present'] ?? 0, Colors.green),
                      _Chip('Vắng', s['absent'] ?? 0, Colors.red),
                      _Chip('Muộn', s['late'] ?? 0, Colors.orange),
                      _Chip('Nửa ngày', s['half_day'] ?? 0, Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: _list.isEmpty
                      ? const Center(
                          child: Text('Chưa có dữ liệu',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _list.length,
                          itemBuilder: (_, i) {
                            final a = _list[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _statusColor(a.status).withOpacity(0.15),
                                  child: Icon(Icons.calendar_today,
                                      color: _statusColor(a.status), size: 18),
                                ),
                                title: Text(a.date,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  a.checkIn != null
                                      ? '${a.checkIn} → ${a.checkOut ?? '--:--'}'
                                      : 'Không có giờ',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(a.status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    a.statusLabel,
                                    style: TextStyle(
                                        color: _statusColor(a.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
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

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Chip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
