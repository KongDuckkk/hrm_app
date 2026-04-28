import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/salary.dart';
import '../models/employee.dart';

class SalaryProvider extends ChangeNotifier {
  List<Salary> _salaryList = [];
  bool _isLoading = false;

  List<Salary> get salaryList => _salaryList;
  bool get isLoading => _isLoading;

  Future<void> loadByMonth(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    _salaryList = await DatabaseHelper.instance.getSalaryByMonth(month, year);
    _isLoading = false;
    notifyListeners();
  }

  /// Tự động tính lương dựa trên số ngày công trong tháng
  Future<String> generateSalary(
      List<Employee> employees, int month, int year, int workDays) async {
    int created = 0;
    int skipped = 0;

    for (final emp in employees) {
      final exists =
      await DatabaseHelper.instance.salaryExists(emp.id!, month, year);
      if (exists) {
        skipped++;
        continue;
      }
      final actualDays = await DatabaseHelper.instance
          .countPresentByEmployeeMonth(emp.id!, month, year);
      final dailyRate = emp.baseSalary / workDays;
      final total = dailyRate * actualDays;

      await DatabaseHelper.instance.insertSalary(Salary(
        employeeId: emp.id!,
        employeeName: emp.fullName,
        month: month,
        year: year,
        workDays: workDays,
        actualDays: actualDays,
        baseSalary: emp.baseSalary,
        totalSalary: total,
        createdAt: DateTime.now().toIso8601String(),
      ));
      created++;
    }
    await loadByMonth(month, year);
    return 'Đã tạo $created bảng lương${skipped > 0 ? ', bỏ qua $skipped (đã tồn tại)' : ''}';
  }

  /// Tính lương cho 1 nhân viên cụ thể
  Future<String> generateSingleSalary(
      Employee employee, int month, int year, int workDays,
      {double bonus = 0, double deduction = 0}) async {
    final exists = await DatabaseHelper.instance
        .salaryExists(employee.id!, month, year);
    if (exists) {
      return 'Nhân viên ${employee.fullName} đã có bảng lương tháng $month/$year';
    }
    final actualDays = await DatabaseHelper.instance
        .countPresentByEmployeeMonth(employee.id!, month, year);
    final dailyRate = employee.baseSalary / workDays;
    final total = (dailyRate * actualDays) + bonus - deduction;
    await DatabaseHelper.instance.insertSalary(Salary(
      employeeId: employee.id!,
      employeeName: employee.fullName,
      month: month,
      year: year,
      workDays: workDays,
      actualDays: actualDays,
      baseSalary: employee.baseSalary,
      bonus: bonus,
      deduction: deduction,
      totalSalary: total,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await loadByMonth(month, year);
    return 'ok';
  }

  Future<void> updateSalary(Salary salary) async {
    await DatabaseHelper.instance.updateSalary(salary);
    await loadByMonth(salary.month, salary.year);
  }

  Future<void> deleteSalary(int id, int month, int year) async {
    await DatabaseHelper.instance.deleteSalary(id);
    await loadByMonth(month, year);
  }

  double get totalPayroll =>
      _salaryList.fold(0, (sum, s) => sum + s.totalSalary);
}