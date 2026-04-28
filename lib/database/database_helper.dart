import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hrm_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,            // ← tăng từ 2 lên 3
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'staff',
        employeeId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        dateOfBirth TEXT,
        gender TEXT,
        nationality TEXT DEFAULT 'Việt Nam',
        placeOfBirth TEXT,
        currentAddress TEXT,
        permanentAddress TEXT,
        temporaryAddress TEXT,
        hometown TEXT,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        avatarPath TEXT,
        cccdNumber TEXT,
        cccdIssueDate TEXT,
        cccdIssuePlace TEXT,
        taxCode TEXT,
        socialInsurance TEXT,
        healthInsurance TEXT,
        maritalStatus TEXT DEFAULT 'single',
        fatherName TEXT,
        fatherPhone TEXT,
        motherName TEXT,
        motherPhone TEXT,
        spouseName TEXT,
        spousePhone TEXT,
        children TEXT,
        bankName TEXT,
        bankAccount TEXT,
        bankBranch TEXT,
        department TEXT NOT NULL,
        position TEXT NOT NULL,
        baseSalary REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        date TEXT NOT NULL,
        checkIn TEXT,
        checkOut TEXT,
        status TEXT NOT NULL DEFAULT 'present',
        checkInPhoto TEXT,
        checkOutPhoto TEXT,
        FOREIGN KEY (employeeId) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE salary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        workDays INTEGER NOT NULL,
        actualDays INTEGER NOT NULL,
        baseSalary REAL NOT NULL,
        bonus REAL DEFAULT 0,
        deduction REAL DEFAULT 0,
        totalSalary REAL NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees(id)
      )
    ''');

    // Tài khoản mặc định: admin/admin123
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    // Dữ liệu mẫu nhân viên
    final now = DateTime.now().toIso8601String();
    await db.insert('employees', {
      'fullName': 'Nguyễn Văn An',
      'email': 'an.nguyen@company.com',
      'phone': '0901234567',
      'department': 'Kỹ thuật',
      'position': 'Lập trình viên',
      'baseSalary': 15000000,
      'status': 'active',
      'createdAt': now,
    });
    await db.insert('employees', {
      'fullName': 'Trần Thị Bình',
      'email': 'binh.tran@company.com',
      'phone': '0912345678',
      'department': 'Kế toán',
      'position': 'Kế toán viên',
      'baseSalary': 12000000,
      'status': 'active',
      'createdAt': now,
    });
    await db.insert('employees', {
      'fullName': 'Lê Minh Cường',
      'email': 'cuong.le@company.com',
      'phone': '0923456789',
      'department': 'Kinh doanh',
      'position': 'Nhân viên kinh doanh',
      'baseSalary': 10000000,
      'status': 'active',
      'createdAt': now,
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // version 1 → 2: thêm các cột mới vào employees
    if (oldVersion < 2) {
      final employeeColumns = {
        'dateOfBirth': 'TEXT',
        'gender': 'TEXT',
        'nationality': "TEXT DEFAULT 'Việt Nam'",
        'placeOfBirth': 'TEXT',
        'currentAddress': 'TEXT',
        'permanentAddress': 'TEXT',
        'temporaryAddress': 'TEXT',
        'hometown': 'TEXT',
        'avatarPath': 'TEXT',
        'cccdNumber': 'TEXT',
        'cccdIssueDate': 'TEXT',
        'cccdIssuePlace': 'TEXT',
        'taxCode': 'TEXT',
        'socialInsurance': 'TEXT',
        'healthInsurance': 'TEXT',
        'maritalStatus': "TEXT DEFAULT 'single'",
        'fatherName': 'TEXT',
        'fatherPhone': 'TEXT',
        'motherName': 'TEXT',
        'motherPhone': 'TEXT',
        'spouseName': 'TEXT',
        'spousePhone': 'TEXT',
        'children': 'TEXT',
        'bankName': 'TEXT',
        'bankAccount': 'TEXT',
        'bankBranch': 'TEXT',
      };
      for (final entry in employeeColumns.entries) {
        try {
          await db.execute(
              'ALTER TABLE employees ADD COLUMN ${entry.key} ${entry.value}');
        } catch (_) {}
      }
    }

    // version 2 → 3: thêm cột ảnh vào attendance
    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE attendance ADD COLUMN checkInPhoto TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE attendance ADD COLUMN checkOutPhoto TEXT');
      } catch (_) {}
    }
  }

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<UserModel?> login(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ─── EMPLOYEES ────────────────────────────────────────────────────────────

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    final map = employee.toMap()..remove('id');
    return await db.insert('employees', map);
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final result = await db.query('employees', orderBy: 'fullName ASC');
    return result.map((e) => Employee.fromMap(e)).toList();
  }

  Future<List<Employee>> getActiveEmployees() async {
    final db = await database;
    final result = await db.query(
      'employees',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'fullName ASC',
    );
    return result.map((e) => Employee.fromMap(e)).toList();
  }

  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final result = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Employee.fromMap(result.first);
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Employee>> searchEmployees(String query) async {
    final db = await database;
    final result = await db.query(
      'employees',
      where: 'fullName LIKE ? OR department LIKE ? OR position LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((e) => Employee.fromMap(e)).toList();
  }

  Future<Map<String, int>> getEmployeeStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM employees'),
    ) ??
        0;
    final active = Sqflite.firstIntValue(
      await db.rawQuery(
          "SELECT COUNT(*) FROM employees WHERE status='active'"),
    ) ??
        0;
    return {'total': total, 'active': active};
  }

  // ─── ATTENDANCE ───────────────────────────────────────────────────────────

  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    final map = attendance.toMap()..remove('id');
    return await db.insert('attendance', map);
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'employeeName ASC',
    );
    return result.map((e) => Attendance.fromMap(e)).toList();
  }

  Future<List<Attendance>> getAttendanceByEmployee(int employeeId) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'date DESC',
    );
    return result.map((e) => Attendance.fromMap(e)).toList();
  }

  Future<List<Attendance>> getAttendanceByMonth(int month, int year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT * FROM attendance WHERE strftime('%m', date) = ? AND strftime('%Y', date) = ? ORDER BY date DESC",
      [month.toString().padLeft(2, '0'), year.toString()],
    );
    return result.map((e) => Attendance.fromMap(e)).toList();
  }

  Future<Attendance?> getAttendanceByEmployeeDate(
      int employeeId, String date) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, date],
    );
    if (result.isEmpty) return null;
    return Attendance.fromMap(result.first);
  }

  Future<int> updateAttendance(Attendance attendance) async {
    final db = await database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> countPresentByEmployeeMonth(
      int employeeId, int month, int year) async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM attendance WHERE employeeId=? AND strftime('%m',date)=? AND strftime('%Y',date)=? AND status='present'",
        [
          employeeId,
          month.toString().padLeft(2, '0'),
          year.toString(),
        ],
      ),
    ) ??
        0;
  }

  // ─── SALARY ───────────────────────────────────────────────────────────────

  Future<int> insertSalary(Salary salary) async {
    final db = await database;
    final map = salary.toMap()..remove('id');
    return await db.insert('salary', map);
  }

  Future<List<Salary>> getSalaryByMonth(int month, int year) async {
    final db = await database;
    final result = await db.query(
      'salary',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      orderBy: 'employeeName ASC',
    );
    return result.map((e) => Salary.fromMap(e)).toList();
  }

  Future<List<Salary>> getSalaryByEmployee(int employeeId) async {
    final db = await database;
    final result = await db.query(
      'salary',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'year DESC, month DESC',
    );
    return result.map((e) => Salary.fromMap(e)).toList();
  }

  Future<bool> salaryExists(int employeeId, int month, int year) async {
    final db = await database;
    final result = await db.query(
      'salary',
      where: 'employeeId = ? AND month = ? AND year = ?',
      whereArgs: [employeeId, month, year],
    );
    return result.isNotEmpty;
  }

  Future<int> updateSalary(Salary salary) async {
    final db = await database;
    return await db.update(
      'salary',
      salary.toMap(),
      where: 'id = ?',
      whereArgs: [salary.id],
    );
  }

  Future<int> deleteSalary(int id) async {
    final db = await database;
    return await db.delete('salary', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}