class Employee {
  int? id;

  // ── Thông tin cá nhân ──────────────────────────────────────────────────────
  String fullName;
  String? dateOfBirth;
  String? gender;         // male / female / other
  String? nationality;
  String? placeOfBirth;
  String? currentAddress;
  String? permanentAddress;
  String? temporaryAddress;
  String? hometown;
  String phone;
  String email;
  String? avatarPath;     // đường dẫn ảnh local

  // ── Giấy tờ tùy thân ──────────────────────────────────────────────────────
  String? cccdNumber;
  String? cccdIssueDate;
  String? cccdIssuePlace;
  String? taxCode;
  String? socialInsurance;
  String? healthInsurance;

  // ── Thông tin gia đình ────────────────────────────────────────────────────
  String? maritalStatus;  // single / married / divorced / widowed
  String? fatherName;
  String? fatherPhone;
  String? motherName;
  String? motherPhone;
  String? spouseName;
  String? spousePhone;
  String? children;       // JSON string hoặc mô tả tự do

  // ── Tài khoản ngân hàng ───────────────────────────────────────────────────
  String? bankName;
  String? bankAccount;
  String? bankBranch;

  // ── Thông tin công việc ───────────────────────────────────────────────────
  String department;
  String position;
  double baseSalary;
  String status;
  String createdAt;

  Employee({
    this.id,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality = 'Việt Nam',
    this.placeOfBirth,
    this.currentAddress,
    this.permanentAddress,
    this.temporaryAddress,
    this.hometown,
    required this.phone,
    required this.email,
    this.avatarPath,
    this.cccdNumber,
    this.cccdIssueDate,
    this.cccdIssuePlace,
    this.taxCode,
    this.socialInsurance,
    this.healthInsurance,
    this.maritalStatus = 'single',
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
    this.spouseName,
    this.spousePhone,
    this.children,
    this.bankName,
    this.bankAccount,
    this.bankBranch,
    required this.department,
    required this.position,
    required this.baseSalary,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'nationality': nationality,
    'placeOfBirth': placeOfBirth,
    'currentAddress': currentAddress,
    'permanentAddress': permanentAddress,
    'temporaryAddress': temporaryAddress,
    'hometown': hometown,
    'phone': phone,
    'email': email,
    'avatarPath': avatarPath,
    'cccdNumber': cccdNumber,
    'cccdIssueDate': cccdIssueDate,
    'cccdIssuePlace': cccdIssuePlace,
    'taxCode': taxCode,
    'socialInsurance': socialInsurance,
    'healthInsurance': healthInsurance,
    'maritalStatus': maritalStatus,
    'fatherName': fatherName,
    'fatherPhone': fatherPhone,
    'motherName': motherName,
    'motherPhone': motherPhone,
    'spouseName': spouseName,
    'spousePhone': spousePhone,
    'children': children,
    'bankName': bankName,
    'bankAccount': bankAccount,
    'bankBranch': bankBranch,
    'department': department,
    'position': position,
    'baseSalary': baseSalary,
    'status': status,
    'createdAt': createdAt,
  };

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
    id: m['id'],
    fullName: m['fullName'] ?? '',
    dateOfBirth: m['dateOfBirth'],
    gender: m['gender'],
    nationality: m['nationality'] ?? 'Việt Nam',
    placeOfBirth: m['placeOfBirth'],
    currentAddress: m['currentAddress'],
    permanentAddress: m['permanentAddress'],
    temporaryAddress: m['temporaryAddress'],
    hometown: m['hometown'],
    phone: m['phone'] ?? '',
    email: m['email'] ?? '',
    avatarPath: m['avatarPath'],
    cccdNumber: m['cccdNumber'],
    cccdIssueDate: m['cccdIssueDate'],
    cccdIssuePlace: m['cccdIssuePlace'],
    taxCode: m['taxCode'],
    socialInsurance: m['socialInsurance'],
    healthInsurance: m['healthInsurance'],
    maritalStatus: m['maritalStatus'] ?? 'single',
    fatherName: m['fatherName'],
    fatherPhone: m['fatherPhone'],
    motherName: m['motherName'],
    motherPhone: m['motherPhone'],
    spouseName: m['spouseName'],
    spousePhone: m['spousePhone'],
    children: m['children'],
    bankName: m['bankName'],
    bankAccount: m['bankAccount'],
    bankBranch: m['bankBranch'],
    department: m['department'] ?? '',
    position: m['position'] ?? '',
    baseSalary: (m['baseSalary'] ?? 0).toDouble(),
    status: m['status'] ?? 'active',
    createdAt: m['createdAt'] ?? '',
  );
}