class ApiConstants {
  static const String baseUrl = 'http://192.168.100.239:8000/api/';
  static const String storageUrl = 'http://192.168.100.239:8000/storage/';
  static const String loginUrl = '${baseUrl}login';
  static const String nguoidungUrl = '${baseUrl}nguoidung';
  static const String updateFaceStatusUrl = '${baseUrl}updateFaceStatus';
  static const String doimatkhauUrl = '${baseUrl}doimatkhau';
  static const String getNguoiDungWithCompanyUrl = '${baseUrl}getNguoiDungWithCompany';
  static const String updateUserUrl = '${baseUrl}updateUser';
  static const String chamCongUrl = '${baseUrl}chamcong';
  static const String thongKeCongUrl = '${baseUrl}thongKeCong';
  static const String chiTietChamCongUrl = '${baseUrl}chitietChamCong';
  static const String baoCaoTheoThoiGianUrl = '${baseUrl}baoCaoTheoThoiGian';
  static const String savelocationUrl = '${baseUrl}savelocation';
  static const String getlocationUrl = '${baseUrl}locations/active';
  // Phú
  static const String nhanvienUrl = '${baseUrl}nhanvien';
  static const String congtyUrl = '${baseUrl}congty';
  static String getNhanVienUrl(int employeeId) => '${nhanvienUrl}/$employeeId';
  static String uploadProfilePictureUrl(int employeeId) => '${nhanvienUrl}/$employeeId/upload-profile-picture';

  static const String pythonUrl = 'http://192.168.1.170:5000/';
  static const String uploadUrl = '${pythonUrl}upload';
  static const String recognizeUrl = '${pythonUrl}predict';
}
