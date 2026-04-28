import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../attendance/attendance_history_screen.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Employee _emp;
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _emp = widget.employee;
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _genderLabel(String? g) {
    switch (g) {
      case 'male': return 'Nam';
      case 'female': return 'Nữ';
      case 'other': return 'Khác';
      default: return '--';
    }
  }

  String _maritalLabel(String? m) {
    switch (m) {
      case 'married': return 'Đã kết hôn';
      case 'divorced': return 'Đã ly hôn';
      case 'widowed': return 'Góa bụa';
      default: return 'Độc thân';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_emp.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => EmployeeFormScreen(employee: _emp)),
              );
              if (ok == true && mounted) Navigator.pop(context, true);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 16), text: 'Cá nhân'),
            Tab(icon: Icon(Icons.badge, size: 16), text: 'Giấy tờ'),
            Tab(icon: Icon(Icons.family_restroom, size: 16), text: 'Gia đình'),
            Tab(icon: Icon(Icons.work, size: 16), text: 'Công việc'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header avatar + tên
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    _emp.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 26, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_emp.fullName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_emp.position} · ${_emp.department}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: _emp.status == 'active'
                            ? Colors.green.withOpacity(0.25)
                            : Colors.grey.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _emp.status == 'active' ? '● Đang làm việc' : '● Nghỉ việc',
                        style: TextStyle(
                          color: _emp.status == 'active' ? Colors.greenAccent : Colors.white60,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _tab1(),
                _tab2(),
                _tab3(),
                _tab4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1 ─────────────────────────────────────────────────────────────────
  Widget _tab1() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card('Thông tin cơ bản', Icons.person, [
        _row(Icons.person, 'Họ và tên', _emp.fullName),
        _row(Icons.cake, 'Ngày sinh', _emp.dateOfBirth),
        _row(Icons.wc, 'Giới tính', _genderLabel(_emp.gender)),
        _row(Icons.flag, 'Quốc tịch', _emp.nationality),
      ]),
      _card('Liên lạc', Icons.contact_phone, [
        _row(Icons.phone, 'Số điện thoại', _emp.phone),
        _row(Icons.email, 'Email', _emp.email),
      ]),
      _card('Địa chỉ', Icons.location_on, [
        _row(Icons.place, 'Nơi sinh', _emp.placeOfBirth),
        _row(Icons.home_work, 'Quê quán', _emp.hometown),
        _row(Icons.home, 'Nơi ở hiện tại', _emp.currentAddress),
        _row(Icons.location_city, 'Thường trú', _emp.permanentAddress),
        _row(Icons.map, 'Tạm trú', _emp.temporaryAddress),
      ]),
    ],
  );

  // ── TAB 2 ─────────────────────────────────────────────────────────────────
  Widget _tab2() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card('CCCD / CMND', Icons.credit_card, [
        _row(Icons.credit_card, 'Số CCCD/CMND', _emp.cccdNumber),
        _row(Icons.calendar_today, 'Ngày cấp', _emp.cccdIssueDate),
        _row(Icons.location_on, 'Nơi cấp', _emp.cccdIssuePlace),
      ]),
      _card('Mã số & Bảo hiểm', Icons.security, [
        _row(Icons.receipt_long, 'Mã số thuế', _emp.taxCode),
        _row(Icons.health_and_safety, 'Bảo hiểm XH', _emp.socialInsurance),
        _row(Icons.local_hospital, 'Bảo hiểm YT', _emp.healthInsurance),
      ]),
    ],
  );

  // ── TAB 3 ─────────────────────────────────────────────────────────────────
  Widget _tab3() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card('Hôn nhân', Icons.favorite, [
        _row(Icons.favorite_border, 'Tình trạng', _maritalLabel(_emp.maritalStatus)),
        if (_emp.maritalStatus == 'married') ...[
          _row(Icons.person, 'Vợ/Chồng', _emp.spouseName),
          _row(Icons.phone, 'SĐT vợ/chồng', _emp.spousePhone),
        ],
      ]),
      _card('Cha mẹ', Icons.family_restroom, [
        _row(Icons.person, 'Họ tên cha', _emp.fatherName),
        _row(Icons.phone, 'SĐT cha', _emp.fatherPhone),
        _row(Icons.person, 'Họ tên mẹ', _emp.motherName),
        _row(Icons.phone, 'SĐT mẹ', _emp.motherPhone),
      ]),
      if (_emp.children != null)
        _card('Con cái', Icons.child_care, [
          _row(Icons.child_care, 'Thông tin', _emp.children),
        ]),
    ],
  );

  // ── TAB 4 ─────────────────────────────────────────────────────────────────
  Widget _tab4() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card('Công việc', Icons.work, [
        _row(Icons.business, 'Phòng ban', _emp.department),
        _row(Icons.badge, 'Chức vụ', _emp.position),
        _row(Icons.payments, 'Lương cơ bản', '${_fmt.format(_emp.baseSalary)} VNĐ'),
        _row(Icons.calendar_today, 'Ngày vào làm', _emp.createdAt.substring(0, 10)),
      ]),
      _card('Tài khoản ngân hàng', Icons.account_balance, [
        _row(Icons.account_balance, 'Ngân hàng', _emp.bankName),
        _row(Icons.credit_card, 'Số tài khoản', _emp.bankAccount),
        _row(Icons.location_city, 'Chi nhánh', _emp.bankBranch),
      ]),
      const SizedBox(height: 4),
      ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AttendanceHistoryScreen(employee: _emp)),
        ),
        icon: const Icon(Icons.history),
        label: const Text('Xem lịch sử chấm công'),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ],
  );

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _card(String title, IconData icon, List<Widget> children) {
    // Lọc bỏ các dòng null/rỗng
    final visible = children.whereType<Widget>().toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF1565C0)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          ]),
          const Divider(height: 16),
          ...visible,
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}