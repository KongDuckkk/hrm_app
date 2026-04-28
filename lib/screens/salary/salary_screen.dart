import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/salary.dart';
import '../../models/employee.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  int _workDays = 26;
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalaryProvider>().loadByMonth(_month, _year);
    });
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; } else { _month--; }
    });
    context.read<SalaryProvider>().loadByMonth(_month, _year);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; } else { _month++; }
    });
    context.read<SalaryProvider>().loadByMonth(_month, _year);
  }

  // ─── TÍNH LƯƠNG TẤT CẢ ───────────────────────────────────────────────────
  Future<void> _generateAll() async {
    await context.read<EmployeeProvider>().loadEmployees();
    final employees = context.read<EmployeeProvider>().employees;
    if (!mounted) return;

    int localWorkDays = _workDays;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, inner) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.groups, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Tính lương tất cả'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow('Tháng', '$_month/$_year'),
              _InfoRow('Số nhân viên', '${employees.length} người'),
              const Divider(height: 20),
              Row(children: [
                const Text('Số ngày làm chuẩn: '),
                const SizedBox(width: 8),
                SizedBox(
                  width: 55,
                  child: TextFormField(
                    initialValue: localWorkDays.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => localWorkDays = int.tryParse(v) ?? 26,
                  ),
                ),
                const Text(' ngày'),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Nhân viên đã có bảng lương sẽ bị bỏ qua.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton.icon(
              onPressed: () {
                _workDays = localWorkDays;
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Tính lương'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;
    final msg = await context.read<SalaryProvider>()
        .generateSalary(employees, _month, _year, _workDays);
    if (mounted) _snack(msg, Colors.green);
  }

  // ─── TÍNH LƯƠNG TỪNG NGƯỜI ────────────────────────────────────────────────
  Future<void> _generateSingle() async {
    await context.read<EmployeeProvider>().loadEmployees();
    final employees = context.read<EmployeeProvider>().employees;
    if (!mounted || employees.isEmpty) return;

    // Lấy danh sách nhân viên chưa có lương tháng này
    final salaryProvider = context.read<SalaryProvider>();
    final existing = salaryProvider.salaryList.map((s) => s.employeeId).toSet();
    final available = employees.where((e) => !existing.contains(e.id)).toList();

    if (available.isEmpty) {
      _snack('Tất cả nhân viên đã có bảng lương tháng này', Colors.orange);
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _SingleSalaryDialog(
        employees: available,
        month: _month,
        year: _year,
        workDays: _workDays,
        fmt: _fmt,
        onSaved: (emp, workDays, bonus, deduction) async {
          _workDays = workDays;
          final result = await context.read<SalaryProvider>()
              .generateSingleSalary(emp, _month, _year, workDays,
              bonus: bonus, deduction: deduction);
          if (mounted) {
            if (result == 'ok') {
              _snack('Đã tính lương cho ${emp.fullName}', Colors.green);
            } else {
              _snack(result, Colors.orange);
            }
          }
        },
      ),
    );
  }

  // ─── CHỌN LOẠI TÍNH LƯƠNG ─────────────────────────────────────────────────
  void _showGenerateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn cách tính lương',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tháng $_month/$_year',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.person,
              color: Colors.indigo,
              title: 'Tính lương từng nhân viên',
              subtitle: 'Chọn nhân viên, nhập thưởng/khấu trừ riêng',
              onTap: () {
                Navigator.pop(context);
                _generateSingle();
              },
            ),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.groups,
              color: const Color(0xFF1565C0),
              title: 'Tính lương tất cả',
              subtitle: 'Tính hàng loạt cho toàn bộ nhân viên',
              onTap: () {
                Navigator.pop(context);
                _generateAll();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── EDIT SALARY ──────────────────────────────────────────────────────────
  void _editSalary(Salary salary) {
    final bonusCtrl = TextEditingController(text: salary.bonus.toStringAsFixed(0));
    final deductCtrl = TextEditingController(text: salary.deduction.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Điều chỉnh lương\n${salary.employeeName}',
            style: const TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _InfoRow('Lương cơ bản', '${_fmt.format(salary.baseSalary)} đ'),
          _InfoRow('Ngày công', '${salary.actualDays}/${salary.workDays} ngày'),
          const Divider(height: 20),
          TextFormField(
            controller: bonusCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Thưởng (VNĐ)', prefixIcon: Icon(Icons.add_circle_outline, color: Colors.green)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: deductCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Khấu trừ (VNĐ)', prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final bonus = double.tryParse(bonusCtrl.text) ?? salary.bonus;
              final deduction = double.tryParse(deductCtrl.text) ?? salary.deduction;
              final dailyRate = salary.baseSalary / salary.workDays;
              final total = (dailyRate * salary.actualDays) + bonus - deduction;
              Navigator.pop(context);
              await context.read<SalaryProvider>().updateSalary(Salary(
                id: salary.id,
                employeeId: salary.employeeId,
                employeeName: salary.employeeName,
                month: salary.month,
                year: salary.year,
                workDays: salary.workDays,
                actualDays: salary.actualDays,
                baseSalary: salary.baseSalary,
                bonus: bonus,
                deduction: deduction,
                totalSalary: total,
                createdAt: salary.createdAt,
              ));
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteSalary(Salary salary) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bảng lương'),
        content: Text('Xóa bảng lương của "${salary.employeeName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SalaryProvider>().deleteSalary(salary.id!, _month, _year);
      _snack('Đã xóa bảng lương', Colors.green);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalaryProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      body: Column(
        children: [
          // Header tháng
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: _prevMonth,
                    ),
                    Text('Tháng $_month/$_year',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                if (provider.salaryList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Tổng quỹ lương', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${_fmt.format(provider.totalPayroll)} VNĐ',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Số nhân viên', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${provider.salaryList.length} người',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.salaryList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Chưa có bảng lương tháng này',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (isAdmin)
                    Column(children: [
                      ElevatedButton.icon(
                        onPressed: _generateSingle,
                        icon: const Icon(Icons.person),
                        label: const Text('Tính từng nhân viên'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _generateAll,
                        icon: const Icon(Icons.groups),
                        label: const Text('Tính tất cả'),
                      ),
                    ]),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => provider.loadByMonth(_month, _year),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: provider.salaryList.length,
                itemBuilder: (_, i) {
                  final s = provider.salaryList[i];
                  final pct = s.workDays > 0 ? s.actualDays / s.workDays : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1565C0),
                                radius: 20,
                                child: Text(
                                  s.employeeName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.employeeName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    Text('${s.actualDays}/${s.workDays} ngày công',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${_fmt.format(s.totalSalary)} đ',
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                  if (s.bonus > 0)
                                    Text('+${_fmt.format(s.bonus)} thưởng',
                                        style: const TextStyle(fontSize: 11, color: Colors.green)),
                                  if (s.deduction > 0)
                                    Text('-${_fmt.format(s.deduction)} trừ',
                                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                                ],
                              ),
                              if (isAdmin)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit',
                                        child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Chỉnh sửa')])),
                                    const PopupMenuItem(value: 'delete',
                                        child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') _editSalary(s);
                                    if (v == 'delete') _deleteSalary(s);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey[200],
                                  color: pct >= 0.9 ? Colors.green : pct >= 0.7 ? Colors.orange : Colors.red,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(pct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: pct >= 0.9 ? Colors.green : pct >= 0.7 ? Colors.orange : Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: _showGenerateOptions,
        icon: const Icon(Icons.calculate),
        label: const Text('Tính lương'),
        backgroundColor: const Color(0xFF1565C0),
      )
          : null,
    );
  }
}

// ─── DIALOG TÍNH LƯƠNG TỪNG NHÂN VIÊN ────────────────────────────────────────

class _SingleSalaryDialog extends StatefulWidget {
  final List<Employee> employees;
  final int month;
  final int year;
  final int workDays;
  final NumberFormat fmt;
  final Future<void> Function(Employee, int, double, double) onSaved;

  const _SingleSalaryDialog({
    required this.employees,
    required this.month,
    required this.year,
    required this.workDays,
    required this.fmt,
    required this.onSaved,
  });

  @override
  State<_SingleSalaryDialog> createState() => _SingleSalaryDialogState();
}

class _SingleSalaryDialogState extends State<_SingleSalaryDialog> {
  Employee? _selected;
  final _workCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController(text: '0');
  final _deductCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _workCtrl.text = widget.workDays.toString();
  }

  @override
  void dispose() {
    _workCtrl.dispose();
    _bonusCtrl.dispose();
    _deductCtrl.dispose();
    super.dispose();
  }

  double get _bonus => double.tryParse(_bonusCtrl.text) ?? 0;
  double get _deduction => double.tryParse(_deductCtrl.text) ?? 0;
  int get _workDays => int.tryParse(_workCtrl.text) ?? 26;

  double _previewSalary(Employee emp) {
    if (_workDays <= 0) return 0;
    final daily = emp.baseSalary / _workDays;
    // preview dùng baseSalary / workDays * workDays (chưa biết ngày thực tế)
    return emp.baseSalary + _bonus - _deduction;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(children: [
              const Icon(Icons.person, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text('Tính lương tháng ${widget.month}/${widget.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),

            // Chọn nhân viên
            const Text('Chọn nhân viên *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Employee>(
                  value: _selected,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('-- Chọn nhân viên --'),
                  ),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  borderRadius: BorderRadius.circular(10),
                  items: widget.employees.map((e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF1565C0).withOpacity(0.15),
                          child: Text(e.fullName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Text('${e.department} · ${widget.fmt.format(e.baseSalary)} đ',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        ),
                      ]),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),
              ),
            ),

            // Preview lương cơ bản
            if (_selected != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lương cơ bản:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('${widget.fmt.format(_selected!.baseSalary)} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            // Ngày làm chuẩn
            TextFormField(
              controller: _workCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Số ngày làm chuẩn',
                prefixIcon: Icon(Icons.calendar_month),
                suffixText: 'ngày',
              ),
            ),
            const SizedBox(height: 12),

            // Thưởng
            TextFormField(
              controller: _bonusCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Thưởng thêm (VNĐ)',
                prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.green),
                suffixText: 'đ',
                filled: true,
                fillColor: Colors.green.withOpacity(0.04),
              ),
            ),
            const SizedBox(height: 12),

            // Khấu trừ
            TextFormField(
              controller: _deductCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Khấu trừ (VNĐ)',
                prefixIcon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                suffixText: 'đ',
                filled: true,
                fillColor: Colors.red.withOpacity(0.04),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selected == null || _saving
                      ? null
                      : () async {
                    setState(() => _saving = true);
                    await widget.onSaved(
                        _selected!, _workDays, _bonus, _deduction);
                    setState(() => _saving = false);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Lưu'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }
}