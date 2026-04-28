import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/salary_provider.dart';
import 'employee/employee_list_screen.dart';
import 'employee/employee_form_screen.dart';
import 'attendance/attendance_screen.dart';
import 'salary/salary_screen.dart';
import 'account_management_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    const _AdminHomeTab(),
    const EmployeeListScreen(),
    const AttendanceScreen(),
    const SalaryScreen(),
    const AccountManagementScreen(),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhấn back lần nữa để thoát'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HRM System'),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(children: [
                const Icon(Icons.account_circle, size: 20),
                const SizedBox(width: 4),
                Text(auth.currentUser?.username ?? '',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Nhân viên',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Chấm công',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Lương',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              activeIcon: Icon(Icons.manage_accounts),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ADMIN HOME TAB ───────────────────────────────────────────────────────────
class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  Map<String, int> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final stats = await context.read<EmployeeProvider>().getStats();
    if (mounted) setState(() { _stats = stats; _loadingStats = false; });
  }

  void _goTab(int i) {
    // Tìm AdminDashboardScreen ở trên và chuyển tab
    final state = context.findAncestorStateOfType<_AdminDashboardScreenState>();
    state?.setState(() => state._currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banner chào ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, ${auth.currentUser?.username ?? ''}!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${now.day}/${now.month}/${now.year}  •  Admin',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 32),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Thống kê ────────────────────────────────────────────────────
          const Text('Tổng quan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _loadingStats
              ? const Center(child: CircularProgressIndicator())
              : Row(children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                label: 'Tổng nhân viên',
                value: '${_stats['total'] ?? 0}',
                color: const Color(0xFF1565C0),
                onTap: () => _goTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'Đang làm việc',
                value: '${_stats['active'] ?? 0}',
                color: Colors.green,
                onTap: () => _goTab(1),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Chức năng Admin ─────────────────────────────────────────────
          const Text('Quản lý hệ thống',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _AdminMenuCard(
            icon: Icons.person_add,
            title: 'Thêm nhân viên mới',
            subtitle: 'Tạo hồ sơ nhân viên vào hệ thống',
            color: Colors.indigo,
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
              );
              if (result == true) _loadStats();
            },
          ),
          _AdminMenuCard(
            icon: Icons.people,
            title: 'Danh sách nhân viên',
            subtitle: 'Xem, sửa, xóa hồ sơ nhân viên',
            color: Colors.blue,
            onTap: () => _goTab(1),
          ),
          _AdminMenuCard(
            icon: Icons.how_to_reg,
            title: 'Quản lý chấm công',
            subtitle: 'Điểm danh, chỉnh sửa trạng thái',
            color: Colors.teal,
            onTap: () => _goTab(2),
          ),
          _AdminMenuCard(
            icon: Icons.payments,
            title: 'Quản lý lương',
            subtitle: 'Tính lương, xem bảng lương tháng',
            color: Colors.orange,
            onTap: () => _goTab(3),
          ),
          _AdminMenuCard(
            icon: Icons.manage_accounts,
            title: 'Quản lý tài khoản',
            subtitle: 'Thêm, phân quyền, xóa tài khoản',
            color: Colors.purple,
            onTap: () => _goTab(4),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_ios, size: 14, color: color),
        ),
        onTap: onTap,
      ),
    );
  }
}