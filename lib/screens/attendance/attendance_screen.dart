import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _selectedDate;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String get _dateString =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _loadData() async {
    await context.read<AttendanceProvider>().loadByDate(_dateString);
  }

  Future<void> _initAttendance() async {
    final employees =
    await context.read<EmployeeProvider>().getStats().then((_) async {
      return await context
          .read<EmployeeProvider>()
          .loadEmployees()
          .then((_) => context.read<EmployeeProvider>().employees);
    });
    if (!mounted) return;
    await context
        .read<AttendanceProvider>()
        .initAttendanceForDate(_dateString, employees);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã khởi tạo điểm danh'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await context.read<AttendanceProvider>().loadByDate(_dateString);
    }
  }

  // ─── CHỤP ẢNH CHECK IN ───────────────────────────────────────────────────
  Future<void> _doCheckIn(Attendance att) async {
    // Chọn nguồn ảnh
    final source = await _showPhotoSourceDialog('Check In');
    if (source == null) return;

    String? photoPath;
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        preferredCameraDevice: CameraDevice.front, // ưu tiên camera trước
      );
      if (photo != null) photoPath = photo.path;
    } catch (_) {
      // Nếu không chụp được ảnh vẫn cho check in
    }

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!mounted) return;
    await context.read<AttendanceProvider>().checkIn(att, timeStr, photoPath);

    _snack('✅ Check in lúc $timeStr${photoPath != null ? ' (có ảnh)' : ''}',
        Colors.green);
  }

  // ─── CHỤP ẢNH CHECK OUT ──────────────────────────────────────────────────
  Future<void> _doCheckOut(Attendance att) async {
    if (att.checkIn == null) {
      _snack('Chưa check in!', Colors.orange);
      return;
    }

    final source = await _showPhotoSourceDialog('Check Out');
    if (source == null) return;

    String? photoPath;
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo != null) photoPath = photo.path;
    } catch (_) {}

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!mounted) return;
    await context.read<AttendanceProvider>().checkOut(att, timeStr, photoPath);

    _snack('✅ Check out lúc $timeStr${photoPath != null ? ' (có ảnh)' : ''}',
        Colors.blue);
  }

  // ─── DIALOG CHỌN NGUỒN ẢNH ───────────────────────────────────────────────
  Future<ImageSource?> _showPhotoSourceDialog(String action) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text('Chụp ảnh $action',
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 4),
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
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.skip_next, color: Colors.grey),
            ),
            title: const Text('Bỏ qua ảnh'),
            subtitle: const Text('Chỉ ghi giờ, không chụp ảnh'),
            onTap: () => Navigator.pop(context, null),
          ),
        ]),
      ),
    );
  }

  // ─── XEM CHI TIẾT ĐIỂM DANH ──────────────────────────────────────────────
  void _showDetail(Attendance att, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            // Tên + trạng thái
            Row(children: [
              CircleAvatar(
                backgroundColor: _statusColor(att.status).withOpacity(0.15),
                child: Icon(_statusIcon(att.status),
                    color: _statusColor(att.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(att.employeeName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(att.statusLabel,
                          style: TextStyle(color: _statusColor(att.status))),
                    ]),
              ),
            ]),
            const Divider(height: 24),

            // Giờ check in / out
            Row(children: [
              Expanded(
                child: _timeCard(
                  'Check In',
                  att.checkIn,
                  Colors.green,
                  Icons.login,
                  // Nút check in: chỉ hiện hôm nay + chưa check in
                  (_isToday && att.checkIn == null)
                      ? () { Navigator.pop(context); _doCheckIn(att); }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeCard(
                  'Check Out',
                  att.checkOut,
                  Colors.blue,
                  Icons.logout,
                  // Nút check out: chỉ hiện hôm nay + đã check in + chưa check out
                  (_isToday && att.checkIn != null && att.checkOut == null)
                      ? () { Navigator.pop(context); _doCheckOut(att); }
                      : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Ảnh check in
            if (att.checkInPhoto != null &&
                File(att.checkInPhoto!).existsSync()) ...[
              const Text('Ảnh Check In',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(att.checkInPhoto!),
                    height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            // Ảnh check out
            if (att.checkOutPhoto != null &&
                File(att.checkOutPhoto!).existsSync()) ...[
              const Text('Ảnh Check Out',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(att.checkOutPhoto!),
                    height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            // Nút đổi trạng thái (admin only)
            if (isAdmin) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text('Đổi trạng thái (Admin)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in ['present', 'absent', 'late', 'half_day'])
                  ChoiceChip(
                    label: Text(Attendance(
                      employeeId: 0,
                      employeeName: '',
                      date: '',
                      status: s,
                    ).statusLabel),
                    selected: att.status == s,
                    selectedColor: _statusColor(s).withOpacity(0.2),
                    onSelected: (_) async {
                      Navigator.pop(context);
                      await context
                          .read<AttendanceProvider>()
                          .updateStatus(att, s);
                    },
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeCard(String label, String? time, Color color, IconData icon,
      VoidCallback? onCheckTap) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(time ?? '--:--',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: time != null ? color : Colors.grey)),
        if (onCheckTap != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCheckTap,
              icon: Icon(icon, size: 14),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':   return Colors.green;
      case 'absent':    return Colors.red;
      case 'late':      return Colors.orange;
      case 'half_day':  return Colors.blue;
      default:          return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':   return Icons.check_circle;
      case 'absent':    return Icons.cancel;
      case 'late':      return Icons.access_time;
      case 'half_day':  return Icons.timelapse;
      default:          return Icons.help;
    }
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      body: Column(
        children: [
          // ── Header date picker ────────────────────────────────────────────
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      setState(() => _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1)));
                      _loadData();
                    },
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _selectedDate.isBefore(DateTime.now()
                        .subtract(const Duration(days: 1)))
                        ? () {
                      setState(() => _selectedDate =
                          _selectedDate.add(const Duration(days: 1)));
                      _loadData();
                    }
                        : null,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip('Có mặt', provider.presentCount, Colors.green),
                  _SummaryChip('Vắng', provider.absentCount, Colors.red),
                  _SummaryChip('Muộn', provider.lateCount, Colors.orange),
                ],
              ),
            ]),
          ),

          // ── Danh sách ─────────────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.attendanceList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Chưa có dữ liệu điểm danh',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: _initAttendance,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Khởi tạo điểm danh'),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.attendanceList.length,
                itemBuilder: (_, i) {
                  final att = provider.attendanceList[i];
                  final hasCheckInPhoto = att.checkInPhoto != null &&
                      File(att.checkInPhoto!).existsSync();
                  final hasCheckOutPhoto =
                      att.checkOutPhoto != null &&
                          File(att.checkOutPhoto!).existsSync();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _showDetail(att, isAdmin),
                      leading: CircleAvatar(
                        backgroundColor:
                        _statusColor(att.status).withOpacity(0.15),
                        child: Icon(_statusIcon(att.status),
                            color: _statusColor(att.status)),
                      ),
                      title: Text(att.employeeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [
                        // Check in
                        Icon(Icons.login,
                            size: 12, color: Colors.green[700]),
                        const SizedBox(width: 2),
                        Text(att.checkIn ?? '--:--',
                            style: const TextStyle(fontSize: 12)),
                        if (hasCheckInPhoto) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.camera_alt,
                              size: 10, color: Colors.green[400]),
                        ],
                        const Text('  →  ',
                            style: TextStyle(fontSize: 12)),
                        // Check out
                        Icon(Icons.logout,
                            size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 2),
                        Text(att.checkOut ?? '--:--',
                            style: const TextStyle(fontSize: 12)),
                        if (hasCheckOutPhoto) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.camera_alt,
                              size: 10, color: Colors.blue[400]),
                        ],
                      ]),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(att.status)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          att.statusLabel,
                          style: TextStyle(
                              color: _statusColor(att.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin && provider.attendanceList.isNotEmpty
          ? FloatingActionButton(
        onPressed: _initAttendance,
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.refresh),
      )
          : null,
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
            width: 8, height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count',
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}