import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../models/salary.dart';

class StaffSalaryScreen extends StatefulWidget {
  const StaffSalaryScreen({super.key});

  @override
  State<StaffSalaryScreen> createState() => _StaffSalaryScreenState();
}

class _StaffSalaryScreenState extends State<StaffSalaryScreen> {
  List<Salary> _list = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final empId = context.read<AuthProvider>().currentUser?.employeeId;
    if (empId == null) {
      setState(() { _loading = false; _list = []; });
      return;
    }
    _list = await DatabaseHelper.instance.getSalaryByEmployee(empId);
    setState(() => _loading = false);
  }

  void _viewDetail(Salary s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bảng lương tháng ${s.month}/${s.year}',
            style: const TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _Row(Icons.calendar_today, 'Tháng', '${s.month}/${s.year}'),
          _Row(Icons.work_history, 'Ngày công', '${s.actualDays}/${s.workDays} ngày'),
          const Divider(height: 20),
          _Row(Icons.payments, 'Lương cơ bản', '${_fmt.format(s.baseSalary)} đ'),
          if (s.bonus > 0)
            _Row(Icons.add_circle_outline, 'Thưởng', '+${_fmt.format(s.bonus)} đ',
                valueColor: Colors.green),
          if (s.deduction > 0)
            _Row(Icons.remove_circle_outline, 'Khấu trừ', '-${_fmt.format(s.deduction)} đ',
                valueColor: Colors.red),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thực nhận',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${_fmt.format(s.totalSalary)} đ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1565C0))),
              ],
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = context.read<AuthProvider>().currentUser?.employeeId != null;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !hasAccount
              ? _noAccountWidget()
              : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('Chưa có bảng lương',
                              style: TextStyle(color: Colors.grey, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Liên hệ Admin để tính lương',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Tổng kết
                        Container(
                          color: const Color(0xFF1565C0),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Lương gần nhất',
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${_fmt.format(_list.first.totalSalary)} đ',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                const Text('Tháng gần nhất',
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${_list.first.month}/${_list.first.year}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _list.length,
                              itemBuilder: (_, i) {
                                final s = _list[i];
                                final pct = s.workDays > 0
                                    ? (s.actualDays / s.workDays).clamp(0.0, 1.0)
                                    : 0.0;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    onTap: () => _viewDetail(s),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(children: [
                                              Container(
                                                width: 44, height: 44,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.calendar_month,
                                                    color: Color(0xFF1565C0)),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text('Tháng ${s.month}/${s.year}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 15)),
                                                Text('${s.actualDays}/${s.workDays} ngày công',
                                                    style: const TextStyle(
                                                        fontSize: 12, color: Colors.grey)),
                                              ]),
                                            ]),
                                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                              Text('${_fmt.format(s.totalSalary)} đ',
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1565C0))),
                                              if (s.bonus > 0)
                                                Text('+${_fmt.format(s.bonus)} thưởng',
                                                    style: const TextStyle(
                                                        fontSize: 11, color: Colors.green)),
                                            ]),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                backgroundColor: Colors.grey[200],
                                                color: pct >= 0.9
                                                    ? Colors.green
                                                    : pct >= 0.7
                                                        ? Colors.orange
                                                        : Colors.red,
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${(pct * 100).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: pct >= 0.9
                                                      ? Colors.green
                                                      : pct >= 0.7
                                                          ? Colors.orange
                                                          : Colors.red)),
                                        ]),
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _noAccountWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Tài khoản chưa liên kết nhân viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Liên hệ Admin để liên kết tài khoản với hồ sơ nhân viên.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? Colors.black87)),
      ]),
    );
  }
}
