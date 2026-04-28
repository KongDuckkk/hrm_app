import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/attendance.dart';
import '../models/employee.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Attendance> _attendanceList = [];
  bool _isLoading = false;
  String _selectedDate = '';

  List<Attendance> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;
  String get selectedDate => _selectedDate;

  Future<void> loadByDate(String date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();
    _attendanceList = await DatabaseHelper.instance.getAttendanceByDate(date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadByMonth(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    _attendanceList =
    await DatabaseHelper.instance.getAttendanceByMonth(month, year);
    _isLoading = false;
    notifyListeners();
  }

  /// Điểm danh hàng loạt cho tất cả nhân viên active trong một ngày
  Future<void> initAttendanceForDate(
      String date, List<Employee> employees) async {
    for (final emp in employees) {
      final exists = await DatabaseHelper.instance
          .getAttendanceByEmployeeDate(emp.id!, date);
      if (exists == null) {
        await DatabaseHelper.instance.insertAttendance(Attendance(
          employeeId: emp.id!,
          employeeName: emp.fullName,
          date: date,
          status: 'present',
        ));
      }
    }
    await loadByDate(date);
  }

  Future<void> updateStatus(Attendance attendance, String newStatus) async {
    attendance.status = newStatus;
    await DatabaseHelper.instance.updateAttendance(attendance);
    await loadByDate(_selectedDate);
  }

  Future<void> updateCheckTime(
      Attendance attendance, String? checkIn, String? checkOut) async {
    attendance.checkIn = checkIn;
    attendance.checkOut = checkOut;
    await DatabaseHelper.instance.updateAttendance(attendance);
    await loadByDate(_selectedDate);
  }

  /// Check in kèm ảnh
  Future<void> checkIn(Attendance attendance, String time, String? photoPath) async {
    attendance.checkIn = time;
    attendance.checkInPhoto = photoPath;
    if (attendance.status == 'absent') {
      attendance.status = 'present';
    }
    await DatabaseHelper.instance.updateAttendance(attendance);
    await loadByDate(_selectedDate);
  }

  /// Check out kèm ảnh
  Future<void> checkOut(Attendance attendance, String time, String? photoPath) async {
    attendance.checkOut = time;
    attendance.checkOutPhoto = photoPath;
    await DatabaseHelper.instance.updateAttendance(attendance);
    await loadByDate(_selectedDate);
  }

  int get presentCount =>
      _attendanceList.where((a) => a.status == 'present').length;
  int get absentCount =>
      _attendanceList.where((a) => a.status == 'absent').length;
  int get lateCount =>
      _attendanceList.where((a) => a.status == 'late').length;
}