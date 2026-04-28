import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_provider.dart';
import 'employee/employee_list_screen.dart';
import 'employee/employee_form_screen.dart';
import 'attendance/attendance_screen.dart';
import 'salary/salary_screen.dart';
import 'login_screen.dart';
import 'account_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Map<String, int> _stats = {};
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await context.read<EmployeeProvider>().getStats();
    if (mounted) setState(() => _stats = stats);
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  // Xử lý nút back:
  // - Nếu đang ở tab khác → về tab Home (index 0)
  // - Nếu đang ở tab Home → nhấn 2 lần mới thoát app
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false; // không thoát
    }
    // Ở tab Home: nhấn back lần 2 trong 2 giây mới thoát
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
    return true; // thoát app
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
    final pages = [
      _HomeTab(
        stats: _stats,
        onRefresh: _loadStats,
        onTabChange: _switchTab,
        isAdmin: auth.isAdmin,
      ),
      const EmployeeListScreen(),
      const AttendanceScreen(),
      const SalaryScreen(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HRM System'),
          automaticallyImplyLeading: false, // ẩn nút back mặc định trên AppBar
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 20),
                  const SizedBox(width: 4),
                  Text(auth.currentUser?.username ?? '',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: auth.isAdmin ? Colors.amber : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      auth.isAdmin ? 'ADMIN' : 'STAFF',
                      style: TextStyle(
                        fontSize: 10,
                        color: auth.isAdmin ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isAdmin)
              IconButton(
                icon: const Icon(Icons.manage_accounts),
                tooltip: 'Quản lý tài khoản',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountManagementScreen()),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Tổng quan'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Nhân viên'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Chấm công'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'Lương'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, int> stats;
  final VoidCallback onRefresh;
  final ValueChanged<int> onTabChange;
  final bool isAdmin;

  const _HomeTab({
    required this.stats,
    required this.onRefresh,
    required this.onTabChange,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
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
                  '${now.day}/${now.month}/${now.year}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tổng quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'Tổng nhân viên',
                  value: '${stats['total'] ?? 0}',
                  color: const Color(0xFF1565C0),
                  onTap: () => onTabChange(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Đang làm việc',
                  value: '${stats['active'] ?? 0}',
                  color: Colors.green,
                  onTap: () => onTabChange(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Truy cập nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (isAdmin)
            _QuickAction(
              icon: Icons.person_add,
              title: 'Thêm nhân viên mới',
              subtitle: 'Thêm hồ sơ nhân viên vào hệ thống',
              color: Colors.indigo,
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmployeeFormScreen()),
                );
                if (result == true) onRefresh();
              },
            ),
          if (isAdmin) const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.how_to_reg,
            title: 'Điểm danh hôm nay',
            subtitle: 'Chấm công cho ${now.day}/${now.month}/${now.year}',
            color: Colors.teal,
            onTap: () => onTabChange(2),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.calculate,
            title: 'Tính lương tháng ${now.month}',
            subtitle: 'Tự động tính dựa trên số ngày công',
            color: Colors.orange,
            onTap: () => onTabChange(3),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.people_outline,
            title: 'Danh sách nhân viên',
            subtitle: 'Xem và quản lý toàn bộ nhân viên',
            color: Colors.blue,
            onTap: () => onTabChange(1),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.manage_accounts,
            title: 'Quản lý tài khoản',
            subtitle: isAdmin ? 'Thêm, phân quyền, xóa tài khoản' : 'Đổi mật khẩu, xem thông tin',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

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
          child: Column(
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}