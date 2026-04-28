import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../models/employee.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  Employee? _employee;
  bool _loading = true;
  final _fmt = NumberFormat('#,###', 'vi_VN');
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final empId = context.read<AuthProvider>().currentUser?.employeeId;
    if (empId != null) {
      _employee = await DatabaseHelper.instance.getEmployeeById(empId);
    }
    setState(() => _loading = false);
  }

  // ─── ĐỔI ẢNH ĐẠI DIỆN ────────────────────────────────────────────────────
  Future<void> _changeAvatar() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Chọn ảnh đại diện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Chụp ảnh bằng camera
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.camera_alt, color: Colors.blue),
            ),
            title: const Text('Chụp ảnh'),
            subtitle: const Text('Dùng camera để chụp'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          const SizedBox(height: 4),
          // Chọn từ thư viện
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.photo_library, color: Colors.purple),
            ),
            title: const Text('Chọn từ thư viện'),
            subtitle: const Text('Ảnh có sẵn trong máy'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          // Xóa ảnh (chỉ hiện khi đang có ảnh)
          if (_employee?.avatarPath != null) ...[
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: const Text('Xóa ảnh hiện tại',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ]),
      ),
    );

    if (action == null) return;

    if (action == 'delete') {
      await _saveAvatar(null);
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;
      await _saveAvatar(picked.path);
    } catch (e) {
      _snack('Không thể mở ${action == 'camera' ? 'camera' : 'thư viện'}: $e',
          Colors.red);
    }
  }

  Future<void> _saveAvatar(String? path) async {
    if (_employee == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.update('employees', {'avatarPath': path},
        where: 'id = ?', whereArgs: [_employee!.id]);
    await _load();
    _snack(
        path != null ? 'Đã cập nhật ảnh đại diện' : 'Đã xóa ảnh', Colors.green);
  }

  // ─── ĐỔI MẬT KHẨU ────────────────────────────────────────────────────────
  void _changePassword() {
    final auth = context.read<AuthProvider>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cfCtrl = TextEditingController();
    bool o1 = true, o2 = true, o3 = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, inner) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.lock_reset, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Đổi mật khẩu', style: TextStyle(fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _passField(
                oldCtrl, 'Mật khẩu hiện tại', o1, () => inner(() => o1 = !o1)),
            const SizedBox(height: 12),
            _passField(
                newCtrl, 'Mật khẩu mới', o2, () => inner(() => o2 = !o2)),
            const SizedBox(height: 12),
            _passField(cfCtrl, 'Xác nhận mật khẩu mới', o3,
                    () => inner(() => o3 = !o3)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (oldCtrl.text != auth.currentUser?.password) {
                  _snack('Mật khẩu hiện tại không đúng', Colors.red);
                  return;
                }
                if (newCtrl.text.length < 6) {
                  _snack('Mật khẩu mới tối thiểu 6 ký tự', Colors.red);
                  return;
                }
                if (newCtrl.text != cfCtrl.text) {
                  _snack('Mật khẩu xác nhận không khớp', Colors.red);
                  return;
                }
                final db = await DatabaseHelper.instance.database;
                await db.update('users', {'password': newCtrl.text},
                    where: 'id = ?', whereArgs: [auth.currentUser?.id]);
                Navigator.pop(ctx);
                _snack('Đổi mật khẩu thành công', Colors.green);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHỈNH SỬA THÔNG TIN ─────────────────────────────────────────────────
  void _editProfile() {
    if (_employee == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              _StaffEditProfileScreen(employee: _employee!)),
    ).then((updated) {
      if (updated == true) _load();
    });
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final emp = _employee;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar + tên ────────────────────────────────────
            Center(
              child: Column(children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1565C0), width: 3),
                        ),
                        child: ClipOval(
                          child: emp?.avatarPath != null &&
                              File(emp!.avatarPath!).existsSync()
                              ? Image.file(
                            File(emp.avatarPath!),
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          )
                              : Container(
                            color: const Color(0xFF1565C0),
                            child: Center(
                              child: Text(
                                (emp?.fullName ??
                                    user?.username ??
                                    '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 34,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Nút camera nhỏ
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _changeAvatar,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  emp?.fullName ?? user?.username ?? 'Nhân viên',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (emp != null)
                  Text('${emp.position} · ${emp.department}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge,
                            size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('Staff · @${user?.username}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _changeAvatar,
                  icon: const Icon(Icons.camera_alt, size: 14),
                  label: const Text('Đổi ảnh đại diện',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Tài khoản ────────────────────────────────────────
            _card('Tài khoản', Icons.account_circle, [
              _row(Icons.person, 'Tên đăng nhập', user?.username),
              _row(Icons.admin_panel_settings, 'Quyền', 'Staff'),
            ]),

            // ── Thông tin cá nhân ─────────────────────────────────
            if (emp != null) ...[
              _card('Thông tin cá nhân', Icons.person, [
                _row(Icons.person, 'Họ và tên', emp.fullName),
                _row(Icons.cake, 'Ngày sinh', emp.dateOfBirth),
                _row(Icons.wc, 'Giới tính', _genderLabel(emp.gender)),
                _row(Icons.flag, 'Quốc tịch', emp.nationality),
                _row(Icons.phone, 'Số điện thoại', emp.phone),
                _row(Icons.email, 'Email', emp.email),
                _row(Icons.home, 'Nơi ở hiện tại', emp.currentAddress),
                _row(Icons.home_work, 'Quê quán', emp.hometown),
              ]),
              _card('Thông tin công việc', Icons.work, [
                _row(Icons.business, 'Phòng ban', emp.department),
                _row(Icons.badge, 'Chức vụ', emp.position),
                _row(Icons.payments, 'Lương cơ bản',
                    '${_fmt.format(emp.baseSalary)} VNĐ'),
                _row(Icons.calendar_today, 'Ngày vào làm',
                    emp.createdAt.substring(0, 10)),
              ]),
              if (emp.bankAccount != null &&
                  emp.bankAccount!.isNotEmpty)
                _card('Tài khoản ngân hàng', Icons.account_balance, [
                  _row(Icons.account_balance, 'Ngân hàng', emp.bankName),
                  _row(Icons.credit_card, 'Số tài khoản',
                      emp.bankAccount),
                  _row(Icons.location_city, 'Chi nhánh', emp.bankBranch),
                ]),
            ],

            if (emp == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                        'Tài khoản chưa được liên kết với hồ sơ nhân viên. Liên hệ Admin.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      )),
                ]),
              ),

            const SizedBox(height: 16),

            if (emp != null)
              ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa thông tin cá nhân'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Đổi mật khẩu'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Color(0xFF1565C0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: const Color(0xFF1565C0)),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0))),
              ]),
              const Divider(height: 16),
              ...children,
            ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        SizedBox(
            width: 110,
            child: Text(label,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  String _genderLabel(String? g) {
    switch (g) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return '--';
    }
  }

  TextFormField _passField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }
}

// ─── CHỈNH SỬA THÔNG TIN ─────────────────────────────────────────────────────
class _StaffEditProfileScreen extends StatefulWidget {
  final Employee employee;
  const _StaffEditProfileScreen({required this.employee});

  @override
  State<_StaffEditProfileScreen> createState() =>
      _StaffEditProfileScreenState();
}

class _StaffEditProfileScreenState extends State<_StaffEditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  late final _phoneCtrl =
  TextEditingController(text: widget.employee.phone);
  late final _emailCtrl =
  TextEditingController(text: widget.employee.email);
  late final _currentAddrCtrl =
  TextEditingController(text: widget.employee.currentAddress ?? '');
  late final _tempAddrCtrl =
  TextEditingController(text: widget.employee.temporaryAddress ?? '');
  late final _hometownCtrl =
  TextEditingController(text: widget.employee.hometown ?? '');
  late String _maritalStatus =
      widget.employee.maritalStatus ?? 'single';
  late final _spouseNameCtrl =
  TextEditingController(text: widget.employee.spouseName ?? '');
  late final _spousePhoneCtrl =
  TextEditingController(text: widget.employee.spousePhone ?? '');
  late final _fatherNameCtrl =
  TextEditingController(text: widget.employee.fatherName ?? '');
  late final _fatherPhoneCtrl =
  TextEditingController(text: widget.employee.fatherPhone ?? '');
  late final _motherNameCtrl =
  TextEditingController(text: widget.employee.motherName ?? '');
  late final _motherPhoneCtrl =
  TextEditingController(text: widget.employee.motherPhone ?? '');
  late final _childrenCtrl =
  TextEditingController(text: widget.employee.children ?? '');
  late final _bankNameCtrl =
  TextEditingController(text: widget.employee.bankName ?? '');
  late final _bankAccCtrl =
  TextEditingController(text: widget.employee.bankAccount ?? '');
  late final _bankBranchCtrl =
  TextEditingController(text: widget.employee.bankBranch ?? '');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _phoneCtrl, _emailCtrl, _currentAddrCtrl, _tempAddrCtrl,
      _hometownCtrl, _spouseNameCtrl, _spousePhoneCtrl,
      _fatherNameCtrl, _fatherPhoneCtrl, _motherNameCtrl,
      _motherPhoneCtrl, _childrenCtrl, _bankNameCtrl,
      _bankAccCtrl, _bankBranchCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _tab.animateTo(0);
      _snack('Vui lòng nhập số điện thoại', Colors.red);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _tab.animateTo(0);
      _snack('Vui lòng nhập email', Colors.red);
      return;
    }

    final updated = Employee(
      id: widget.employee.id,
      fullName: widget.employee.fullName,
      dateOfBirth: widget.employee.dateOfBirth,
      gender: widget.employee.gender,
      nationality: widget.employee.nationality,
      placeOfBirth: widget.employee.placeOfBirth,
      permanentAddress: widget.employee.permanentAddress,
      cccdNumber: widget.employee.cccdNumber,
      cccdIssueDate: widget.employee.cccdIssueDate,
      cccdIssuePlace: widget.employee.cccdIssuePlace,
      taxCode: widget.employee.taxCode,
      socialInsurance: widget.employee.socialInsurance,
      healthInsurance: widget.employee.healthInsurance,
      department: widget.employee.department,
      position: widget.employee.position,
      baseSalary: widget.employee.baseSalary,
      status: widget.employee.status,
      createdAt: widget.employee.createdAt,
      avatarPath: widget.employee.avatarPath,
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      currentAddress: _currentAddrCtrl.text.trim().isEmpty
          ? null
          : _currentAddrCtrl.text.trim(),
      temporaryAddress: _tempAddrCtrl.text.trim().isEmpty
          ? null
          : _tempAddrCtrl.text.trim(),
      hometown: _hometownCtrl.text.trim().isEmpty
          ? null
          : _hometownCtrl.text.trim(),
      maritalStatus: _maritalStatus,
      spouseName: _spouseNameCtrl.text.trim().isEmpty
          ? null
          : _spouseNameCtrl.text.trim(),
      spousePhone: _spousePhoneCtrl.text.trim().isEmpty
          ? null
          : _spousePhoneCtrl.text.trim(),
      fatherName: _fatherNameCtrl.text.trim().isEmpty
          ? null
          : _fatherNameCtrl.text.trim(),
      fatherPhone: _fatherPhoneCtrl.text.trim().isEmpty
          ? null
          : _fatherPhoneCtrl.text.trim(),
      motherName: _motherNameCtrl.text.trim().isEmpty
          ? null
          : _motherNameCtrl.text.trim(),
      motherPhone: _motherPhoneCtrl.text.trim().isEmpty
          ? null
          : _motherPhoneCtrl.text.trim(),
      children: _childrenCtrl.text.trim().isEmpty
          ? null
          : _childrenCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim().isEmpty
          ? null
          : _bankNameCtrl.text.trim(),
      bankAccount: _bankAccCtrl.text.trim().isEmpty
          ? null
          : _bankAccCtrl.text.trim(),
      bankBranch: _bankBranchCtrl.text.trim().isEmpty
          ? null
          : _bankBranchCtrl.text.trim(),
    );

    try {
      await DatabaseHelper.instance.updateEmployee(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã cập nhật thông tin'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Lỗi: $e', Colors.red);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.contact_phone, size: 18), text: 'Liên lạc'),
            Tab(icon: Icon(Icons.family_restroom, size: 18), text: 'Gia đình'),
            Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Ngân hàng'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Lưu',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: TabBarView(controller: _tab, children: [
        _tabContact(),
        _tabFamily(),
        _tabBank(),
      ]),
    );
  }

  Widget _tabContact() =>
      ListView(padding: const EdgeInsets.all(16), children: [
        _note(
            'Bạn có thể chỉnh sửa thông tin liên lạc và địa chỉ. Các thông tin khác do Admin quản lý.',
            Colors.blue),
        const SizedBox(height: 12),
        _section('Liên lạc', Icons.contact_phone, [
          _field(_phoneCtrl, 'Số điện thoại *', Icons.phone,
              keyboard: TextInputType.phone),
          _field(_emailCtrl, 'Email *', Icons.email,
              keyboard: TextInputType.emailAddress),
        ]),
        _section('Địa chỉ', Icons.location_on, [
          _field(_currentAddrCtrl, 'Nơi ở hiện tại', Icons.home,
              maxLines: 2),
          _field(_tempAddrCtrl, 'Địa chỉ tạm trú', Icons.map, maxLines: 2),
          _field(_hometownCtrl, 'Quê quán', Icons.home_work),
        ]),
      ]);

  Widget _tabFamily() =>
      ListView(padding: const EdgeInsets.all(16), children: [
        _section('Hôn nhân', Icons.favorite, [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              value: _maritalStatus,
              decoration: const InputDecoration(
                  labelText: 'Tình trạng hôn nhân',
                  prefixIcon: Icon(Icons.favorite_border)),
              items: const [
                DropdownMenuItem(
                    value: 'single', child: Text('Độc thân')),
                DropdownMenuItem(
                    value: 'married', child: Text('Đã kết hôn')),
                DropdownMenuItem(
                    value: 'divorced', child: Text('Đã ly hôn')),
                DropdownMenuItem(
                    value: 'widowed', child: Text('Góa bụa')),
              ],
              onChanged: (v) => setState(() => _maritalStatus = v!),
            ),
          ),
          if (_maritalStatus == 'married') ...[
            _field(_spouseNameCtrl, 'Tên vợ / chồng', Icons.person),
            _field(_spousePhoneCtrl, 'SĐT vợ / chồng', Icons.phone,
                keyboard: TextInputType.phone),
          ],
        ]),
        _section('Cha mẹ', Icons.family_restroom, [
          _field(_fatherNameCtrl, 'Họ tên cha', Icons.person),
          _field(_fatherPhoneCtrl, 'SĐT cha', Icons.phone,
              keyboard: TextInputType.phone),
          _field(_motherNameCtrl, 'Họ tên mẹ', Icons.person),
          _field(_motherPhoneCtrl, 'SĐT mẹ', Icons.phone,
              keyboard: TextInputType.phone),
        ]),
        _section('Con cái', Icons.child_care, [
          _field(_childrenCtrl, 'Thông tin con cái', Icons.child_care,
              maxLines: 3, hint: 'VD: Con 1: Nguyễn Văn A (2015)'),
        ]),
      ]);

  Widget _tabBank() =>
      ListView(padding: const EdgeInsets.all(16), children: [
        _section('Tài khoản ngân hàng', Icons.account_balance, [
          _field(_bankNameCtrl, 'Tên ngân hàng', Icons.account_balance,
              hint: 'VD: Vietcombank, Techcombank...'),
          _field(_bankAccCtrl, 'Số tài khoản', Icons.credit_card,
              keyboard: TextInputType.number),
          _field(_bankBranchCtrl, 'Chi nhánh', Icons.location_city),
        ]),
        _note(
            'Thông tin ngân hàng dùng để nhận lương. Vui lòng nhập chính xác.',
            Colors.orange),
      ]);

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, size: 18, color: const Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                  ]),
                  const Divider(height: 20),
                  ...children,
                ])),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
        String? hint}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                hintText: hint),
          ));

  Widget _note(String msg, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.info_outline, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: TextStyle(
                  fontSize: 12, color: color, height: 1.4))),
    ]),
  );
}