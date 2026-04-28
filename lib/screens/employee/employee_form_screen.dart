import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tab;

  bool get _isEditing => widget.employee != null;

  // ── Tab 1: Thông tin cá nhân ──────────────────────────────────────────────
  late final _nameCtrl      = _c(widget.employee?.fullName);
  late final _dobCtrl       = _c(widget.employee?.dateOfBirth);
  late final _nationalityCtrl = _c(widget.employee?.nationality ?? 'Việt Nam');
  late final _pobCtrl       = _c(widget.employee?.placeOfBirth);
  late final _hometownCtrl  = _c(widget.employee?.hometown);
  late final _currentAddrCtrl = _c(widget.employee?.currentAddress);
  late final _permAddrCtrl  = _c(widget.employee?.permanentAddress);
  late final _tempAddrCtrl  = _c(widget.employee?.temporaryAddress);
  late final _phoneCtrl     = _c(widget.employee?.phone);
  late final _emailCtrl     = _c(widget.employee?.email);
  String _gender = 'male';
  String _maritalStatus = 'single';

  // ── Tab 2: Giấy tờ ───────────────────────────────────────────────────────
  late final _cccdCtrl      = _c(widget.employee?.cccdNumber);
  late final _cccdDateCtrl  = _c(widget.employee?.cccdIssueDate);
  late final _cccdPlaceCtrl = _c(widget.employee?.cccdIssuePlace);
  late final _taxCtrl       = _c(widget.employee?.taxCode);
  late final _siCtrl        = _c(widget.employee?.socialInsurance);
  late final _hiCtrl        = _c(widget.employee?.healthInsurance);

  // ── Tab 3: Gia đình ───────────────────────────────────────────────────────
  late final _fatherNameCtrl  = _c(widget.employee?.fatherName);
  late final _fatherPhoneCtrl = _c(widget.employee?.fatherPhone);
  late final _motherNameCtrl  = _c(widget.employee?.motherName);
  late final _motherPhoneCtrl = _c(widget.employee?.motherPhone);
  late final _spouseNameCtrl  = _c(widget.employee?.spouseName);
  late final _spousePhoneCtrl = _c(widget.employee?.spousePhone);
  late final _childrenCtrl    = _c(widget.employee?.children);

  // ── Tab 4: Công việc & Ngân hàng ──────────────────────────────────────────
  late final _deptCtrl    = _c(widget.employee?.department);
  late final _posCtrl     = _c(widget.employee?.position);
  late final _salaryCtrl  = _c(widget.employee?.baseSalary.toStringAsFixed(0));
  late final _bankNameCtrl    = _c(widget.employee?.bankName);
  late final _bankAccCtrl     = _c(widget.employee?.bankAccount);
  late final _bankBranchCtrl  = _c(widget.employee?.bankBranch);
  String _status = 'active';

  TextEditingController _c(String? val) =>
      TextEditingController(text: val ?? '');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    if (widget.employee != null) {
      _gender = widget.employee!.gender ?? 'male';
      _maritalStatus = widget.employee!.maritalStatus ?? 'single';
      _status = widget.employee!.status;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _allControllers) c.dispose();
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
    _nameCtrl, _dobCtrl, _nationalityCtrl, _pobCtrl, _hometownCtrl,
    _currentAddrCtrl, _permAddrCtrl, _tempAddrCtrl, _phoneCtrl, _emailCtrl,
    _cccdCtrl, _cccdDateCtrl, _cccdPlaceCtrl, _taxCtrl, _siCtrl, _hiCtrl,
    _fatherNameCtrl, _fatherPhoneCtrl, _motherNameCtrl, _motherPhoneCtrl,
    _spouseNameCtrl, _spousePhoneCtrl, _childrenCtrl,
    _deptCtrl, _posCtrl, _salaryCtrl, _bankNameCtrl, _bankAccCtrl, _bankBranchCtrl,
  ];

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _tab.animateTo(0);
      _snack('Vui lòng nhập họ tên', Colors.red); return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _tab.animateTo(0);
      _snack('Vui lòng nhập số điện thoại', Colors.red); return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _tab.animateTo(0);
      _snack('Vui lòng nhập email', Colors.red); return;
    }
    if (_deptCtrl.text.trim().isEmpty || _posCtrl.text.trim().isEmpty) {
      _tab.animateTo(3);
      _snack('Vui lòng nhập phòng ban và chức vụ', Colors.red); return;
    }
    final salary = double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
    if (salary <= 0) {
      _tab.animateTo(3);
      _snack('Vui lòng nhập lương hợp lệ', Colors.red); return;
    }

    final emp = Employee(
      id: widget.employee?.id,
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
      gender: _gender,
      nationality: _nationalityCtrl.text.trim().isEmpty ? 'Việt Nam' : _nationalityCtrl.text.trim(),
      placeOfBirth: _pobCtrl.text.trim().isEmpty ? null : _pobCtrl.text.trim(),
      currentAddress: _currentAddrCtrl.text.trim().isEmpty ? null : _currentAddrCtrl.text.trim(),
      permanentAddress: _permAddrCtrl.text.trim().isEmpty ? null : _permAddrCtrl.text.trim(),
      temporaryAddress: _tempAddrCtrl.text.trim().isEmpty ? null : _tempAddrCtrl.text.trim(),
      hometown: _hometownCtrl.text.trim().isEmpty ? null : _hometownCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      cccdNumber: _cccdCtrl.text.trim().isEmpty ? null : _cccdCtrl.text.trim(),
      cccdIssueDate: _cccdDateCtrl.text.trim().isEmpty ? null : _cccdDateCtrl.text.trim(),
      cccdIssuePlace: _cccdPlaceCtrl.text.trim().isEmpty ? null : _cccdPlaceCtrl.text.trim(),
      taxCode: _taxCtrl.text.trim().isEmpty ? null : _taxCtrl.text.trim(),
      socialInsurance: _siCtrl.text.trim().isEmpty ? null : _siCtrl.text.trim(),
      healthInsurance: _hiCtrl.text.trim().isEmpty ? null : _hiCtrl.text.trim(),
      maritalStatus: _maritalStatus,
      fatherName: _fatherNameCtrl.text.trim().isEmpty ? null : _fatherNameCtrl.text.trim(),
      fatherPhone: _fatherPhoneCtrl.text.trim().isEmpty ? null : _fatherPhoneCtrl.text.trim(),
      motherName: _motherNameCtrl.text.trim().isEmpty ? null : _motherNameCtrl.text.trim(),
      motherPhone: _motherPhoneCtrl.text.trim().isEmpty ? null : _motherPhoneCtrl.text.trim(),
      spouseName: _spouseNameCtrl.text.trim().isEmpty ? null : _spouseNameCtrl.text.trim(),
      spousePhone: _spousePhoneCtrl.text.trim().isEmpty ? null : _spousePhoneCtrl.text.trim(),
      children: _childrenCtrl.text.trim().isEmpty ? null : _childrenCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
      bankAccount: _bankAccCtrl.text.trim().isEmpty ? null : _bankAccCtrl.text.trim(),
      bankBranch: _bankBranchCtrl.text.trim().isEmpty ? null : _bankBranchCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
      position: _posCtrl.text.trim(),
      baseSalary: salary,
      status: _status,
      createdAt: widget.employee?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final provider = context.read<EmployeeProvider>();
    final ok = _isEditing
        ? await provider.updateEmployee(emp)
        : await provider.addEmployee(emp);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      _snack(_isEditing ? 'Đã cập nhật nhân viên' : 'Đã thêm nhân viên', Colors.green);
    } else {
      _snack('Có lỗi xảy ra', Colors.red);
    }
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ctrl.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa nhân viên' : 'Thêm nhân viên mới'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 18), text: 'Cá nhân'),
            Tab(icon: Icon(Icons.badge, size: 18), text: 'Giấy tờ'),
            Tab(icon: Icon(Icons.family_restroom, size: 18), text: 'Gia đình'),
            Tab(icon: Icon(Icons.work, size: 18), text: 'Công việc'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tab,
          children: [
            _tab1Personal(),
            _tab2Documents(),
            _tab3Family(),
            _tab4Work(),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: CÁ NHÂN ────────────────────────────────────────────────────────
  Widget _tab1Personal() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Thông tin cơ bản', Icons.person, [
          _field(_nameCtrl, 'Họ và tên *', Icons.person, required: true),
          _dateField(_dobCtrl, 'Ngày sinh', Icons.cake),
          _dropdown('Giới tính', Icons.wc, _gender, ['male','female','other'],
              ['Nam','Nữ','Khác'], (v) => setState(() => _gender = v!)),
          _field(_nationalityCtrl, 'Quốc tịch', Icons.flag),
        ]),
        _section('Liên lạc', Icons.contact_phone, [
          _field(_phoneCtrl, 'Số điện thoại *', Icons.phone,
              required: true, keyboard: TextInputType.phone),
          _field(_emailCtrl, 'Email *', Icons.email,
              required: true, keyboard: TextInputType.emailAddress),
        ]),
        _section('Địa chỉ', Icons.location_on, [
          _field(_pobCtrl, 'Nơi sinh', Icons.place),
          _field(_hometownCtrl, 'Quê quán', Icons.home_work),
          _field(_currentAddrCtrl, 'Nơi ở hiện tại', Icons.home, maxLines: 2),
          _field(_permAddrCtrl, 'Địa chỉ thường trú', Icons.location_city, maxLines: 2),
          _field(_tempAddrCtrl, 'Địa chỉ tạm trú', Icons.map, maxLines: 2),
        ]),
      ],
    );
  }

  // ── TAB 2: GIẤY TỜ ───────────────────────────────────────────────────────
  Widget _tab2Documents() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('CCCD / CMND', Icons.credit_card, [
          _field(_cccdCtrl, 'Số CCCD / CMND', Icons.credit_card,
              keyboard: TextInputType.number),
          _dateField(_cccdDateCtrl, 'Ngày cấp', Icons.calendar_today),
          _field(_cccdPlaceCtrl, 'Nơi cấp', Icons.location_on),
        ]),
        _section('Mã số & Bảo hiểm', Icons.security, [
          _field(_taxCtrl, 'Mã số thuế (MST)', Icons.receipt_long,
              keyboard: TextInputType.number),
          _field(_siCtrl, 'Số bảo hiểm xã hội', Icons.health_and_safety),
          _field(_hiCtrl, 'Số bảo hiểm y tế', Icons.local_hospital),
        ]),
      ],
    );
  }

  // ── TAB 3: GIA ĐÌNH ──────────────────────────────────────────────────────
  Widget _tab3Family() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Tình trạng hôn nhân', Icons.favorite, [
          _dropdown('Tình trạng hôn nhân', Icons.favorite_border,
              _maritalStatus,
              ['single','married','divorced','widowed'],
              ['Độc thân','Đã kết hôn','Đã ly hôn','Góa bụa'],
                  (v) => setState(() => _maritalStatus = v!)),
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
              maxLines: 3, hint: 'VD: Con 1: Nguyễn Văn A (2015), Con 2: Nguyễn Thị B (2018)'),
        ]),
      ],
    );
  }

  // ── TAB 4: CÔNG VIỆC & NGÂN HÀNG ─────────────────────────────────────────
  Widget _tab4Work() {
    final departments = ['Kỹ thuật','Kế toán','Kinh doanh','Nhân sự','Marketing','Vận hành'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Thông tin công việc', Icons.work, [
          // Dropdown phòng ban
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              value: departments.contains(_deptCtrl.text) ? _deptCtrl.text : null,
              decoration: const InputDecoration(
                  labelText: 'Phòng ban *', prefixIcon: Icon(Icons.business)),
              hint: const Text('-- Chọn phòng ban --'),
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _deptCtrl.text = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn phòng ban' : null,
            ),
          ),
          _field(_posCtrl, 'Chức vụ *', Icons.badge, required: true),
          _field(_salaryCtrl, 'Lương cơ bản (VNĐ) *', Icons.payments,
              required: true, keyboard: TextInputType.number, suffixText: 'VNĐ'),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                    labelText: 'Trạng thái', prefixIcon: Icon(Icons.toggle_on)),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang làm việc')),
                  DropdownMenuItem(value: 'inactive', child: Text('Nghỉ việc')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
            ),
        ]),
        _section('Tài khoản ngân hàng', Icons.account_balance, [
          _field(_bankNameCtrl, 'Tên ngân hàng', Icons.account_balance,
              hint: 'VD: Vietcombank, Techcombank...'),
          _field(_bankAccCtrl, 'Số tài khoản', Icons.credit_card,
              keyboard: TextInputType.number),
          _field(_bankBranchCtrl, 'Chi nhánh', Icons.location_city),
        ]),
      ],
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────
  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          ]),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool required = false,
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
        String? hint,
        String? suffixText,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          hintText: hint,
          suffixText: suffixText,
        ),
        validator: required
            ? (v) => v!.trim().isEmpty ? 'Vui lòng nhập $label' : null
            : null,
      ),
    );
  }

  Widget _dateField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          hintText: 'dd/mm/yyyy',
        ),
        onTap: () => _pickDate(ctrl),
      ),
    );
  }

  Widget _dropdown(
      String label,
      IconData icon,
      String value,
      List<String> values,
      List<String> labels,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: List.generate(values.length,
                (i) => DropdownMenuItem(value: values[i], child: Text(labels[i]))),
        onChanged: onChanged,
      ),
    );
  }
}