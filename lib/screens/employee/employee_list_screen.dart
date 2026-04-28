import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/employee.dart';
import '../../models/user_model.dart';
import '../../database/database_helper.dart';
import 'employee_form_screen.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToForm([Employee? employee]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true && mounted) {
      context.read<EmployeeProvider>().loadEmployees();
    }
  }

  void _delete(Employee employee) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa nhân viên'),
        content: Text('Xóa "${employee.fullName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<EmployeeProvider>().deleteEmployee(employee.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa nhân viên')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ─── TẠO TÀI KHOẢN ───────────────────────────────────────────────────────
  Future<void> _createAccount(Employee emp) async {
    final allUsers = await DatabaseHelper.instance.getAllUsers();
    final existing = allUsers.where((u) => u.employeeId == emp.id).toList();

    if (existing.isNotEmpty) {
      _showExistingAccount(existing.first, emp.fullName);
      return;
    }

    final userCtrl = TextEditingController(text: _toUsername(emp.fullName));
    final passCtrl = TextEditingController(text: '123456');
    bool obscure = true;
    String role = 'staff';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, inner) => AlertDialog(
          title: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.12),
              child: Text(
                emp.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tạo tài khoản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(emp.fullName, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
              ]),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'Tự động tạo từ tên nhân viên',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mặc định',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => inner(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Quyền',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff — Nhân viên')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin — Quản trị')),
                ],
                onChanged: (v) => inner(() => role = v!),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.25)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Expanded(child: Text(
                    'Nhân viên dùng tài khoản này để đăng nhập vào app.',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  )),
                ]),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Tạo tài khoản'),
              onPressed: () async {
                final username = userCtrl.text.trim();
                final password = passCtrl.text.trim();
                if (username.length < 3) {
                  _snack('Tên đăng nhập tối thiểu 3 ký tự', Colors.red);
                  return;
                }
                if (password.length < 6) {
                  _snack('Mật khẩu tối thiểu 6 ký tự', Colors.red);
                  return;
                }
                final all = await DatabaseHelper.instance.getAllUsers();
                if (all.any((u) => u.username == username)) {
                  _snack('Tên đăng nhập đã tồn tại', Colors.red);
                  return;
                }
                await DatabaseHelper.instance.insertUser(UserModel(
                  username: username,
                  password: password,
                  role: role,
                  employeeId: emp.id,
                ));
                Navigator.pop(ctx);
                _snack('Đã tạo tài khoản "$username" cho ${emp.fullName}', Colors.green);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExistingAccount(UserModel user, String empName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Đã có tài khoản', style: TextStyle(fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _InfoTileStatic(Icons.person, 'Tên đăng nhập', user.username),
          _InfoTileStatic(
            user.role == 'admin' ? Icons.admin_panel_settings : Icons.badge,
            'Quyền',
            user.role == 'admin' ? 'Admin' : 'Staff',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Expanded(child: Text(
                'Vào Quản lý tài khoản để chỉnh sửa hoặc đổi mật khẩu.',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              )),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _toUsername(String fullName) {
    const map = {
      'à':'a','á':'a','ả':'a','ã':'a','ạ':'a',
      'ă':'a','ắ':'a','ặ':'a','ằ':'a','ẳ':'a','ẵ':'a',
      'â':'a','ấ':'a','ầ':'a','ẩ':'a','ẫ':'a','ậ':'a',
      'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e',
      'ê':'e','ế':'e','ề':'e','ể':'e','ễ':'e','ệ':'e',
      'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
      'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o',
      'ô':'o','ố':'o','ồ':'o','ổ':'o','ỗ':'o','ộ':'o',
      'ơ':'o','ớ':'o','ờ':'o','ở':'o','ỡ':'o','ợ':'o',
      'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u',
      'ư':'u','ứ':'u','ừ':'u','ử':'u','ữ':'u','ự':'u',
      'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y','đ':'d',
    };
    final parts = fullName.toLowerCase().split(' ');
    final last = parts.isNotEmpty ? parts.last : '';
    String result = '';
    for (final ch in last.split('')) {
      result += map[ch] ?? ch;
    }
    String prefix = '';
    for (int i = 0; i < parts.length - 1; i++) {
      final p = parts[i];
      if (p.isNotEmpty) prefix += map[p[0]] ?? p[0];
    }
    return (result + prefix).replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm nhân viên...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.search('');
                      },
                    )
                        : null,
                  ),
                  onChanged: provider.search,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.departments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final dept = provider.departments[i];
                      final selected = provider.filterDept == dept;
                      return ChoiceChip(
                        label: Text(dept,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? Colors.white : Colors.black87)),
                        selected: selected,
                        selectedColor: const Color(0xFF1565C0),
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        showCheckmark: true,
                        side: BorderSide(
                            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade400,
                            width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onSelected: (_) => provider.filterByDepartment(dept),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.employees.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Không có nhân viên nào',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: provider.loadEmployees,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.employees.length,
                itemBuilder: (_, i) {
                  final emp = provider.employees[i];
                  return _EmployeeCard(
                    employee: emp,
                    isAdmin: isAdmin,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeDetailScreen(employee: emp),
                      ),
                    ),
                    onEdit: isAdmin ? () => _goToForm(emp) : null,
                    onDelete: isAdmin ? () => _delete(emp) : null,
                    onCreateAccount: isAdmin ? () => _createAccount(emp) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () => _goToForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên'),
        backgroundColor: const Color(0xFF1565C0),
      )
          : null,
    );
  }
}

// ─── EMPLOYEE CARD ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCreateAccount;

  const _EmployeeCard({
    required this.employee,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1565C0),
                radius: 24,
                child: Text(
                  employee.fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(employee.position,
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(employee.department,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: employee.status == 'active' ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.status == 'active' ? 'Đang làm' : 'Nghỉ việc',
                        style: TextStyle(
                            fontSize: 11,
                            color: employee.status == 'active' ? Colors.green : Colors.grey),
                      ),
                    ]),
                  ],
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 10),
                        Text('Chỉnh sửa'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'account',
                      child: Row(children: [
                        Icon(Icons.manage_accounts, size: 18, color: Color(0xFF1565C0)),
                        SizedBox(width: 10),
                        Text('Tạo tài khoản', style: TextStyle(color: Color(0xFF1565C0))),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'account') onCreateAccount?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _InfoTileStatic extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTileStatic(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}