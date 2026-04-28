# 📱 HRM System — Ứng dụng Quản Lý Nhân Sự

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Local%20DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Android](https://img.shields.io/badge/Android-Platform-3DDC84?style=for-the-badge&logo=android&logoColor=white)

**Đồ án giữa kỳ — Lập trình di động**  
Ứng dụng quản lý nhân sự dành cho doanh nghiệp vừa và nhỏ  
chạy hoàn toàn offline trên nền tảng Android

</div>

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Cấu trúc project](#-cấu-trúc-project)
- [Cài đặt & Chạy](#-cài-đặt--chạy)
- [Tài khoản mặc định](#-tài-khoản-mặc-định)
- [Giao diện](#-giao-diện)
- [Cơ sở dữ liệu](#-cơ-sở-dữ-liệu)
- [Nhóm phát triển](#-nhóm-phát-triển)

---

## 🎯 Giới thiệu

**HRM System** là ứng dụng quản lý nhân sự được xây dựng bằng **Flutter/Dart**, hướng đến giải quyết bài toán quản lý nhân viên, chấm công và tính lương cho các doanh nghiệp vừa và nhỏ tại Việt Nam.

Ứng dụng hoạt động hoàn toàn **offline** — không cần Internet, dữ liệu được lưu trữ cục bộ trên thiết bị bằng **SQLite**.

---

## ✨ Tính năng

### 👑 Quản trị viên (Admin)

| Chức năng | Mô tả |
|-----------|-------|
| 👥 Quản lý nhân viên | Thêm, sửa, xóa hồ sơ nhân viên đầy đủ |
| 📅 Chấm công | Điểm danh theo ngày, chỉnh trạng thái từng người |
| 💰 Tính lương | Tự động tính theo ngày công, thêm thưởng/khấu trừ |
| 🔐 Quản lý tài khoản | Thêm tài khoản, phân quyền Admin/Staff, đổi mật khẩu |
| 📊 Dashboard | Thống kê tổng quan nhân viên, truy cập nhanh |

### 👤 Nhân viên (Staff)

| Chức năng | Mô tả |
|-----------|-------|
| ⏰ Check In / Check Out | Chấm công theo thời gian thực với nút tròn trực quan |
| 📆 Lịch sử chấm công | Xem theo tháng, thống kê ngày có mặt/vắng/muộn |
| 💵 Bảng lương cá nhân | Xem lương từng tháng, chi tiết thưởng và khấu trừ |
| 📝 Cập nhật hồ sơ | Chỉnh thông tin liên lạc, gia đình, ngân hàng |
| 🖼️ Đổi ảnh đại diện | Chọn ảnh từ thư viện điện thoại |
| 🔑 Đổi mật khẩu | Bảo mật tài khoản cá nhân |

### 📁 Hồ sơ nhân viên đầy đủ

Ứng dụng lưu trữ đầy đủ thông tin nhân viên theo 4 nhóm:

- **Cá nhân:** Họ tên, ngày sinh, giới tính, quốc tịch, nơi sinh, quê quán, địa chỉ thường trú/tạm trú/hiện tại
- **Giấy tờ:** CCCD/CMND, mã số thuế, bảo hiểm xã hội, bảo hiểm y tế
- **Gia đình:** Tình trạng hôn nhân, thông tin cha mẹ, vợ/chồng, con cái
- **Công việc & Ngân hàng:** Phòng ban, chức vụ, lương cơ bản, tài khoản ngân hàng

---

## 🛠 Công nghệ sử dụng

```
Flutter 3.x        — Framework UI đa nền tảng
Dart 3.x           — Ngôn ngữ lập trình chính
SQLite (sqflite)   — Cơ sở dữ liệu cục bộ
Provider           — Quản lý trạng thái (State Management)
Material Design 3  — Hệ thống thiết kế giao diện
file_picker        — Chọn ảnh từ thư viện
intl               — Định dạng số tiền, ngày tháng
```

---

## 📁 Cấu trúc project

```
lib/
├── main.dart                          # Entry point, cấu hình theme
│
├── models/                            # Data models
│   ├── employee.dart                  # Model nhân viên (30+ trường)
│   ├── attendance.dart                # Model chấm công
│   ├── salary.dart                    # Model bảng lương
│   └── user_model.dart                # Model tài khoản
│
├── database/
│   └── database_helper.dart           # SQLite singleton, CRUD operations
│
├── providers/                         # State Management
│   ├── auth_provider.dart             # Xác thực & phân quyền
│   ├── employee_provider.dart         # State nhân viên
│   ├── attendance_provider.dart       # State chấm công
│   └── salary_provider.dart          # State lương
│
└── screens/
    ├── login_screen.dart              # Màn hình đăng nhập
    ├── register_screen.dart           # Màn hình đăng ký
    ├── account_management_screen.dart # Quản lý tài khoản (Admin)
    │
    ├── employee/                      # Màn hình nhân viên (Admin)
    │   ├── employee_list_screen.dart
    │   ├── employee_form_screen.dart
    │   └── employee_detail_screen.dart
    │
    ├── attendance/                    # Màn hình chấm công (Admin)
    │   ├── attendance_screen.dart
    │   └── attendance_history_screen.dart
    │
    ├── salary/                        # Màn hình lương (Admin)
    │   └── salary_screen.dart
    │
    └── staff/                         # Giao diện riêng cho Staff
        ├── staff_dashboard_screen.dart
        ├── staff_attendance_screen.dart
        ├── staff_salary_screen.dart
        └── staff_profile_screen.dart
```

---

## 🚀 Cài đặt & Chạy

### Yêu cầu

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code
- Thiết bị Android hoặc Emulator (API 21+)

### Các bước cài đặt

**1. Clone project**
```bash
git clone https://github.com/your-username/hrm_app.git
cd hrm_app
```

**2. Cài dependencies**
```bash
flutter pub get
```

**3. Chạy ứng dụng**
```bash
flutter run
```

### Build APK

```bash
# APK debug (test)
flutter build apk --debug

# APK release (phát hành)
flutter build apk --release

# APK release tách theo kiến trúc (khuyên dùng)
flutter build apk --split-per-abi --release
```

File APK sau khi build nằm tại:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 Tài khoản mặc định

| Username | Password | Quyền |
|----------|----------|-------|
| `admin` | `admin123` | Admin — Toàn quyền |

> Sau khi đăng nhập, Admin có thể tạo thêm tài khoản Staff trong mục **Quản lý tài khoản**.

---

## 🎨 Giao diện

### Phân quyền giao diện

```
Đăng nhập
    ├── Admin  →  AdminDashboardScreen
    │              ├── Tab: Tổng quan
    │              ├── Tab: Nhân viên  
    │              ├── Tab: Chấm công
    │              ├── Tab: Lương
    │              └── Tab: Tài khoản
    │
    └── Staff  →  StaffDashboardScreen
                   ├── Tab: Trang chủ
                   ├── Tab: Chấm công (Check In/Out)
                   ├── Tab: Lương cá nhân
                   └── Tab: Hồ sơ cá nhân
```

### Màu sắc chủ đạo

| Màu | Mã hex | Dùng cho |
|-----|--------|----------|
| Xanh đậm | `#1565C0` | Primary, AppBar, nút chính |
| Xanh nhạt | `#42A5F5` | Gradient, accent |
| Xanh lá | `#4CAF50` | Trạng thái có mặt, thành công |
| Cam | `#FF9800` | Cảnh báo, đi muộn |
| Đỏ | `#F44336` | Vắng mặt, xóa, lỗi |

---

## 🗄 Cơ sở dữ liệu

Ứng dụng sử dụng **SQLite** với 4 bảng chính:

```sql
users        — Tài khoản đăng nhập (id, username, password, role, employeeId)
employees    — Hồ sơ nhân viên (30+ cột thông tin chi tiết)
attendance   — Chấm công (id, employeeId, date, checkIn, checkOut, status, ảnh)
salary       — Bảng lương (id, employeeId, month, year, workDays, totalSalary...)
```

**Database version:** `3`  
**Migration:** Hỗ trợ tự động nâng cấp từ version cũ qua `onUpgrade`

---

## 👨‍💻 Nhóm phát triển

| Họ tên | MSSV | Vai trò |
|--------|------|---------|
| LÊ CÔNG ĐỨC | DH52200518 | Trưởng nhóm, Backend |
| LÊ CÔNG ĐỨC | DH52200518 | Frontend, UI/UX |
| LÊ CÔNG ĐỨC | DH52200518 | Database, Testing |

> 📌 **Trường:** STU  
> 📌 **Lớp:** D22_TH12  
> 📌 **Môn học:** Lập trình di động  


---

## 📄 Giấy phép

Dự án được phát triển phục vụ mục đích học tập. Mọi quyền được bảo lưu.

---

<div align="center">
  Made with ❤️ using Flutter & Dart
</div>
