import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/employee.dart';

class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<Employee> _filtered = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterDept = 'Tất cả';

  List<Employee> get employees => _filtered;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get filterDept => _filterDept;

  List<String> get departments {
    final depts = _employees.map((e) => e.department).toSet().toList();
    depts.sort();
    return ['Tất cả', ...depts];
  }

  Future<void> loadEmployees() async {
    _isLoading = true;
    notifyListeners();
    _employees = await DatabaseHelper.instance.getAllEmployees();
    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void filterByDepartment(String dept) {
    _filterDept = dept;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _employees.where((e) {
      final matchSearch = _searchQuery.isEmpty ||
          e.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.position.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchDept =
          _filterDept == 'Tất cả' || e.department == _filterDept;
      return matchSearch && matchDept;
    }).toList();
  }

  Future<bool> addEmployee(Employee employee) async {
    try {
      await DatabaseHelper.instance.insertEmployee(employee);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      await DatabaseHelper.instance.updateEmployee(employee);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      await DatabaseHelper.instance.deleteEmployee(id);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, int>> getStats() async {
    return await DatabaseHelper.instance.getEmployeeStats();
  }
}
