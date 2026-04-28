import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../models/attendance.dart';

class StaffAttendanceScreen extends StatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen>
    with SingleTickerProviderStateMixin {
  Attendance? _todayAttendance;
  List<Attendance> _history = [];
  bool _loading = true;
  int? _employeeId;
  String? _employeeName;

  late Timer _timer;
  late DateTime _now;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    _employeeId = auth.currentUser?.employeeId;

    if (_employeeId == null) {
      setState(() => _loading = false);
      return;
    }

    final emp = await DatabaseHelper.instance.getEmployeeById(_employeeId!);
    _employeeName = emp?.fullName;

    final allHistory =
    await DatabaseHelper.instance.getAttendanceByEmployee(_employeeId!);
    _history = allHistory.take(30).toList();

    final todayStr = _dateStr(_now);
    _todayAttendance = await DatabaseHelper.instance
        .getAttendanceByEmployeeDate(_employeeId!, todayStr);

    setState(() => _loading = false);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _timeStr(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  String _weekday(DateTime d) {
    const days = [
      '', 'Thứ hai', 'Thứ ba', 'Thứ tư',
      'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'
    ];
    return days[d.weekday];
  }

  String _formatDate(DateTime d) =>
      '${_weekday(d)}, Ngày ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _hasCheckedIn => _todayAttendance?.checkIn != null;
  bool get _hasCheckedOut => _todayAttendance?.checkOut != null;

  String get _buttonLabel {
    if (_hasCheckedOut) return 'ĐÃ\nHOÀN TẤT';
    if (_hasCheckedIn) return 'CHECK\nOUT';
    return 'CHECK\nIN';
  }

  Color get _buttonColor {
    if (_hasCheckedOut) return Colors.grey;
    if (_hasCheckedIn) return const Color(0xFF1565C0);
    return const Color(0xFF1976D2);
  }

  // ─── CHỤP ẢNH ─────────────────────────────────────────────────────────────
  Future<String?> _takePhoto(String action) async {
    final source = await showModalBottomSheet<ImageSource>(
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
          Text('Ảnh $action',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Chụp ảnh xác nhận khi $action',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.camera_alt, color: Colors.blue),
            ),
            title: const Text('Chụp ảnh ngay'),
            subtitle: const Text('Dùng camera selfie'),
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
            title: const Text('Bỏ qua'),
            subtitle: const Text('Chỉ ghi giờ, không chụp ảnh'),
            onTap: () => Navigator.pop(context, null),
          ),
        ]),
      ),
    );

    if (source == null) return null; // bỏ qua ảnh

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        preferredCameraDevice: CameraDevice.front,
      );
      return photo?.path;
    } catch (_) {
      return null;
    }
  }

  // ─── XỬ LÝ CHECK IN / CHECK OUT ──────────────────────────────────────────
  Future<void> _handleButton() async {
    if (_employeeId == null || _hasCheckedOut) return;

    final timeNow = _timeStr(_now);
    final dateNow = _dateStr(_now);

    if (!_hasCheckedIn) {
      // ── CHECK IN ──
      final photoPath = await _takePhoto('Check In');
      if (!mounted) return;

      if (_todayAttendance == null) {
        await DatabaseHelper.instance.insertAttendance(Attendance(
          employeeId: _employeeId!,
          employeeName: _employeeName ?? '',
          date: dateNow,
          checkIn: timeNow,
          status: 'present',
          checkInPhoto: photoPath,
        ));
        _todayAttendance = await DatabaseHelper.instance
            .getAttendanceByEmployeeDate(_employeeId!, dateNow);
      } else {
        _todayAttendance!.checkIn = timeNow;
        _todayAttendance!.status = 'present';
        _todayAttendance!.checkInPhoto = photoPath;
        await DatabaseHelper.instance.updateAttendance(_todayAttendance!);
      }

      _snack(
        '✅ Check in lúc $timeNow${photoPath != null ? ' 📷' : ''}',
        Colors.green,
      );
    } else {
      // ── CHECK OUT ──
      final photoPath = await _takePhoto('Check Out');
      if (!mounted) return;

      _todayAttendance!.checkOut = timeNow;
      _todayAttendance!.checkOutPhoto = photoPath;
      await DatabaseHelper.instance.updateAttendance(_todayAttendance!);

      _snack(
        '🏁 Check out lúc $timeNow${photoPath != null ? ' 📷' : ''}',
        const Color(0xFF1565C0),
      );
    }

    await _load();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'present':  return Colors.green;
      case 'absent':   return Colors.red;
      case 'late':     return Colors.orange;
      case 'half_day': return Colors.blue;
      default:         return Colors.grey;
    }
  }

  // ─── XEM ẢNH CHECK IN / OUT ───────────────────────────────────────────────
  void _showPhotos() {
    final att = _todayAttendance;
    if (att == null) return;

    final hasIn = att.checkInPhoto != null &&
        File(att.checkInPhoto!).existsSync();
    final hasOut = att.checkOutPhoto != null &&
        File(att.checkOutPhoto!).existsSync();

    if (!hasIn && !hasOut) {
      _snack('Chưa có ảnh chấm công hôm nay', Colors.grey);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          const Text('Ảnh chấm công hôm nay',
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (hasIn) ...[
            Row(children: [
              const Icon(Icons.login, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text('Check In — ${att.checkIn}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.green)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(att.checkInPhoto!),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],
          if (hasOut) ...[
            Row(children: [
              const Icon(Icons.logout, color: Color(0xFF1565C0), size: 16),
              const SizedBox(width: 6),
              Text('Check Out — ${att.checkOut}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(att.checkOutPhoto!),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_employeeId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Tài khoản chưa liên kết nhân viên',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Liên hệ Admin để liên kết tài khoản.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
        ),
      );
    }

    return Column(
      children: [
        // ── PHẦN TRÊN ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            ),
          ),
          child: Column(children: [
            const SizedBox(height: 28),

            // Nút tròn CHECK IN / OUT
            GestureDetector(
              onTap: _hasCheckedOut ? null : _handleButton,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: (_hasCheckedOut || _hasCheckedIn)
                      ? 1.0
                      : _pulseAnim.value,
                  child: child,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Container(
                      width: 136, height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasCheckedOut
                            ? Colors.grey.shade400
                            : Colors.white,
                        boxShadow: _hasCheckedOut
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasCheckedOut
                                  ? Icons.check_circle
                                  : _hasCheckedIn
                                  ? Icons.logout
                                  : Icons.login,
                              size: 32,
                              color: _hasCheckedOut
                                  ? Colors.white
                                  : _buttonColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buttonLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _hasCheckedOut
                                    ? Colors.white
                                    : _buttonColor,
                                height: 1.2,
                              ),
                            ),
                          ]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Ngày tháng
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(_formatDate(_now),
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ]),
            const SizedBox(height: 6),

            // Đồng hồ realtime
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hiện tại ${_timeStr(_now)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 20),

            // Timeline hôm nay
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                _TimelineRow(
                  icon: Icons.login,
                  color: Colors.greenAccent,
                  time: _todayAttendance?.checkIn,
                  label: _hasCheckedIn
                      ? '${_todayAttendance!.checkIn}  Đã check in'
                      : 'Chưa check in',
                  hasPhoto: _todayAttendance?.checkInPhoto != null &&
                      File(_todayAttendance!.checkInPhoto!).existsSync(),
                ),
                if (_hasCheckedIn) ...[
                  const SizedBox(height: 8),
                  _TimelineRow(
                    icon: Icons.logout,
                    color: Colors.orangeAccent,
                    time: _todayAttendance?.checkOut,
                    label: _hasCheckedOut
                        ? '${_todayAttendance!.checkOut}  Đã check out'
                        : 'Chưa check out',
                    hasPhoto: _todayAttendance?.checkOutPhoto != null &&
                        File(_todayAttendance!.checkOutPhoto!).existsSync(),
                  ),
                ],
                if (_hasCheckedIn && !_hasCheckedOut) ...[
                  const SizedBox(height: 8),
                  _TimelineRow(
                    icon: Icons.flag,
                    color: Colors.white54,
                    time: null,
                    label: 'Bắt đầu ca: Ca ngày',
                    hasPhoto: false,
                  ),
                ],
              ]),
            ),

            // Nút xem ảnh (chỉ hiện khi đã có ảnh)
            if (_hasCheckedIn &&
                (_todayAttendance?.checkInPhoto != null ||
                    _todayAttendance?.checkOutPhoto != null)) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _showPhotos,
                icon: const Icon(Icons.photo_library,
                    color: Colors.white70, size: 16),
                label: const Text('Xem ảnh chấm công',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],

            const SizedBox(height: 20),
          ]),
        ),

        // ── PHẦN DƯỚI: Lịch sử ───────────────────────────────────────────────
        Expanded(
          child: _history.isEmpty
              ? const Center(
              child: Text('Chưa có lịch sử chấm công',
                  style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            itemCount: _history.length,
            itemBuilder: (_, i) {
              final a = _history[i];
              final isToday = a.date == _dateStr(_now);
              final hasPhoto = (a.checkInPhoto != null &&
                  File(a.checkInPhoto!).existsSync()) ||
                  (a.checkOutPhoto != null &&
                      File(a.checkOutPhoto!).existsSync());

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF1565C0).withOpacity(0.06)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? Border.all(
                      color: const Color(0xFF1565C0)
                          .withOpacity(0.3))
                      : null,
                ),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                    _statusColor(a.status).withOpacity(0.15),
                    child: Icon(
                      a.status == 'present'
                          ? Icons.check
                          : a.status == 'absent'
                          ? Icons.close
                          : Icons.access_time,
                      size: 16,
                      color: _statusColor(a.status),
                    ),
                  ),
                  title: Text(
                    _fmtDate(a.date),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                  subtitle: Row(children: [
                    Text(
                      a.checkIn != null
                          ? '${a.checkIn} → ${a.checkOut ?? '--:--'}'
                          : 'Không có giờ công',
                      style: const TextStyle(fontSize: 11),
                    ),
                    // Icon camera nếu có ảnh
                    if (hasPhoto) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.camera_alt,
                          size: 11, color: Colors.blue),
                    ],
                  ]),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(a.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(a.status),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtDate(String date) {
    final p = date.split('-');
    if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    return date;
  }
}

// ── TIMELINE ROW ──────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? time;
  final String label;
  final bool hasPhoto;

  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.time,
    required this.label,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: time != null ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight:
            time != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      // Icon camera nhỏ nếu có ảnh
      if (hasPhoto)
        const Icon(Icons.camera_alt, color: Colors.white60, size: 14),
    ]);
  }
}