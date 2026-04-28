class Salary {
  int? id;
  int employeeId;
  String employeeName;
  int month;
  int year;
  int workDays;
  int actualDays;
  double baseSalary;
  double bonus;
  double deduction;
  double totalSalary;
  String createdAt;

  Salary({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.workDays,
    required this.actualDays,
    required this.baseSalary,
    this.bonus = 0,
    this.deduction = 0,
    required this.totalSalary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'workDays': workDays,
      'actualDays': actualDays,
      'baseSalary': baseSalary,
      'bonus': bonus,
      'deduction': deduction,
      'totalSalary': totalSalary,
      'createdAt': createdAt,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'] ?? '',
      month: map['month'],
      year: map['year'],
      workDays: map['workDays'],
      actualDays: map['actualDays'],
      baseSalary: map['baseSalary'].toDouble(),
      bonus: map['bonus']?.toDouble() ?? 0.0,
      deduction: map['deduction']?.toDouble() ?? 0.0,
      totalSalary: map['totalSalary'].toDouble(),
      createdAt: map['createdAt'],
    );
  }
}
