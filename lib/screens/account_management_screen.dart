import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = await DatabaseHelper.instance.getAllUsers();
    setState(() => _loading = false);
  }

  List<UserModel> get _filtered => _search.isEmpty
      ? _users
      : _users
      .where((u) =>
      u.username.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  // ─── ADMIN ACTIONS ────────────────────────────────────────────────────────

  Future<void> _toggleRole(UserModel user) async {
    final me = context.read<AuthProvider>().currentUser;
    if (user.id == me?.id) {
      _snack('Không thể thay đổi quyền của chính mình', Colors.orange);
      return;
    }
    final newRole = user.role == 'admin' ? 'staff' : 'admin';
    final ok = await _confirm(
      'Thay đổi quyền',
      'Đổi "${user.username}" thành ${newRole == "admin" ? "Admin" : "Staff"}?',
    );
    if (!ok) return;
    final db = await DatabaseHelper.instance.database;
    await db.update('users', {'role': newRole},
        where: 'id = ?', whereArgs: [user.id]);
    await _load();
    _snack(
        'Đã đổi quyền "${user.username}" thành $newRole', Colors.green);
  }

  Future<void> _deleteUser(UserModel user) async {
    final me = context.read<AuthProvider>().currentUser;
    if (user.id == me?.id) {
      _snack('Không thể xóa tài khoản đang đăng nhập', Colors.orange);
      return;
    }
    final ok = await _confirm('Xóa tài khoản',
        'Xóa tài khoản "${user.username}"? Hành động này không thể hoàn tác.');
    if (!ok) return;
    await DatabaseHelper.instance.deleteUser(user.id!);
    await _load();
    _snack('Đã xóa tài khoản "${user.username}"', Colors.green);
  }

  void _addAccount() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';
    bool obscure = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, inner) => AlertDialog(
          title: const Text('Thêm tài khoản'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: userCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập *',
                    prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => inner(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                    labelText: 'Quyền',
                    prefixIcon: Icon(Icons.admin_panel_settings)),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => inner(() => role = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (userCtrl.text.trim().length < 4) {
                  _snack('Tên đăng nhập tối thiểu 4 ký tự', Colors.red);
                  return;
                }
                if (passCtrl.text.length < 6) {
                  _snack('Mật khẩu tối thiểu 6 ký tự', Colors.red);
                  return;
                }
                final all = await DatabaseHelper.instance.getAllUsers();
                if (all.any((u) => u.username == userCtrl.text.trim())) {
                  _snack('Tên đăng nhập đã tồn tại', Colors.red);
                  return;
                }
                await DatabaseHelper.instance.insertUser(UserModel(
                  username: userCtrl.text.trim(),
                  password: passCtrl.text,
                  role: role,
                ));
                Navigator.pop(ctx);
                await _load();
                _snack('Đã thêm tài khoản', Colors.green);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED ACTIONS (admin + staff đổi pass của chính mình) ──────────────

  void _changePassword(UserModel user) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cfCtrl = TextEditingController();
    bool o1 = true, o2 = true, o3 = true;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final isMe =
        user.id == context.read<AuthProvider>().currentUser?.id;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, inner) => AlertDialog(
          title: Text('Đổi mật khẩu\n${user.username}',
              style: const TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Chỉ yêu cầu mật khẩu cũ khi đổi của chính mình (không phải admin đổi người khác)
              if (isMe)
                TextFormField(
                  controller: oldCtrl,
                  obscureText: o1,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(o1
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => inner(() => o1 = !o1),
                    ),
                  ),
                ),
              if (isMe) const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: o2,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon:
                    Icon(o2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => inner(() => o2 = !o2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cfCtrl,
                obscureText: o3,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon:
                    Icon(o3 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => inner(() => o3 = !o3),
                  ),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                // Kiểm tra mật khẩu cũ nếu tự đổi
                if (isMe && oldCtrl.text != user.password) {
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
                    where: 'id = ?', whereArgs: [user.id]);
                Navigator.pop(ctx);
                await _load();
                _snack('Đã đổi mật khẩu thành công', Colors.green);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfile(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin tài khoản'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: user.role == 'admin'
                ? Colors.amber.withOpacity(0.2)
                : const Color(0xFF1565C0).withOpacity(0.1),
            child: Icon(
              user.role == 'admin'
                  ? Icons.admin_panel_settings
                  : Icons.person,
              size: 36,
              color: user.role == 'admin'
                  ? Colors.amber[800]
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(Icons.person, 'Tên đăng nhập', user.username),
          _InfoRow(
            user.role == 'admin'
                ? Icons.admin_panel_settings
                : Icons.badge,
            'Quyền',
            user.role == 'admin' ? 'Quản trị viên (Admin)' : 'Nhân viên (Staff)',
          ),
          _InfoRow(Icons.tag, 'ID tài khoản', '#${user.id}'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận')),
        ],
      ),
    ) ??
        false;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final myId = auth.currentUser?.id;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
      ),
      body: Column(
        children: [
          // Stats bar (admin only)
          if (isAdmin)
            Container(
              color: const Color(0xFF1565C0),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip('Tổng cộng', '${_users.length}', Colors.white),
                  _StatChip(
                      'Admin',
                      '${_users.where((u) => u.role == "admin").length}',
                      Colors.amber),
                  _StatChip(
                      'Staff',
                      '${_users.where((u) => u.role == "staff").length}',
                      Colors.greenAccent),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài khoản...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _search = ''),
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
                child: Text('Không tìm thấy tài khoản',
                    style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final user = filtered[i];
                  final isMe = user.id == myId;
                  return _AccountCard(
                    user: user,
                    isMe: isMe,
                    isAdmin: isAdmin,
                    onView: () => _viewProfile(user),
                    onChangePassword: () => _changePassword(user),
                    onToggleRole: isAdmin && !isMe
                        ? () => _toggleRole(user)
                        : null,
                    onDelete: isAdmin && !isMe
                        ? () => _deleteUser(user)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm tài khoản'),
        backgroundColor: const Color(0xFF1565C0),
      )
          : null,
    );
  }
}

// ─── WIDGETS ──────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final bool isAdmin;
  final VoidCallback onView;
  final VoidCallback onChangePassword;
  final VoidCallback? onToggleRole;
  final VoidCallback? onDelete;

  const _AccountCard({
    required this.user,
    required this.isMe,
    required this.isAdmin,
    required this.onView,
    required this.onChangePassword,
    this.onToggleRole,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdminUser = user.role == 'admin';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isAdminUser
                      ? Colors.amber.withOpacity(0.15)
                      : const Color(0xFF1565C0).withOpacity(0.1),
                  child: Icon(
                    isAdminUser
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: isAdminUser
                        ? Colors.amber[800]
                        : const Color(0xFF1565C0),
                    size: 26,
                  ),
                ),
                if (isMe)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Bạn',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.green)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdminUser
                              ? Colors.amber.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAdminUser ? 'Admin' : 'Staff',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAdminUser
                                ? Colors.amber[800]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('ID: ${user.id}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (_) => [
                // Xem thông tin — tất cả đều thấy
                const PopupMenuItem(
                  value: 'view',
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Xem thông tin'),
                  ]),
                ),

                // Đổi mật khẩu — tất cả đều thấy (staff chỉ đổi của mình)
                const PopupMenuItem(
                  value: 'password',
                  child: Row(children: [
                    Icon(Icons.lock_reset, size: 18, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Đổi mật khẩu'),
                  ]),
                ),

                // Nâng/hạ quyền — chỉ admin, không đổi của mình
                if (isAdmin && !isMe)
                  PopupMenuItem(
                    value: 'role',
                    child: Row(children: [
                      Icon(
                        isAdminUser
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 18,
                        color: isAdminUser ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(isAdminUser
                          ? 'Hạ xuống Staff'
                          : 'Nâng lên Admin'),
                    ]),
                  ),

                // Xóa — chỉ admin, không xóa của mình
                if (isAdmin && !isMe)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Xóa tài khoản',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
              ],
              onSelected: (v) {
                if (v == 'view') onView();
                if (v == 'password') onChangePassword();
                if (v == 'role') onToggleRole?.call();
                if (v == 'delete') onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
              const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}