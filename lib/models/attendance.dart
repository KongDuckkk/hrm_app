class Attendance {
  int? id;
  int employeeId;
  String employeeName;
  String date;
  String? checkIn;
  String? checkOut;
  String status; // present, absent, late, half_day
  String? checkInPhoto;
  String? checkOutPhoto;

  Attendance({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.status = 'present',
    this.checkInPhoto,
    this.checkOutPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'status': status,
      'checkInPhoto': checkInPhoto,
      'checkOutPhoto': checkOutPhoto,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'] ?? '',
      date: map['date'],
      checkIn: map['checkIn'],
      checkOut: map['checkOut'],
      status: map['status'] ?? 'present',
      checkInPhoto: map['checkInPhoto'],
      checkOutPhoto: map['checkOutPhoto'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'absent':
        return 'Vắng mặt';
      case 'late':
        return 'Đi muộn';
      case 'half_day':
        return 'Nửa ngày';
      default:
        return status;
    }
  }
}