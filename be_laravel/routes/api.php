<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TaiKhoanController;
use App\Http\Controllers\NguoiDungController;
use App\Http\Controllers\ChamCongController;
use App\Http\Controllers\ViTriController;
use App\Http\Controllers\CongTyController;

// Route::get('/taikhoan', [TaiKhoanController::class, 'getAllTaiKhoan']);
Route::post('/login', [TaiKhoanController::class, 'login']);
Route::post('/getNDCongTY', [NguoiDungController::class, 'getNDCongTY']);
Route::post('/nguoidung', [NguoiDungController::class, 'getNguoiDung']);
Route::post('/updateFaceStatus', [NguoiDungController::class, 'updateFaceStatus']);
Route::post('/getNguoiDungWithCompany', [NguoiDungController::class, 'getNguoiDungWithCompany']);
Route::post('/doimatkhau', [TaiKhoanController::class, 'changePassword']);
Route::post('/chamcong', [ChamCongController::class, 'chamCong']);
Route::post('/thongKeCong', [ChamCongController::class, 'thongKeCong']);
Route::post('/chitietChamCong', [ChamCongController::class, 'chitietChamCong']);
Route::post('/baoCaoTheoThoiGian', [ChamCongController::class, 'baoCaoTheoThoiGian']);
Route::post('/updateUser', [NguoiDungController::class, 'updateUser']);
Route::post('/savelocation', [ViTriController::class, 'saveLocation']);
Route::post('/locations/active', [ViTriController::class, 'getActiveLocation']);
Route::get('/employees', [NguoiDungController::class, 'getEmployees']);
Route::post('/baocaochamcong', [ChamCongController::class, 'getChamCongByPeriod']);
Route::post('/exportexcel', [ChamCongController::class, 'export']);
Route::post('/updateWorkHours', [CongTyController::class, 'updateWorkHours']);
Route::post('/resetPassword', [NguoiDungController::class, 'resetPassword']);
Route::post('/congty/{companyId}/upload-logo', [CongTyController::class, 'uploadLogo']);
// Phú 
Route::get('/congty', [CongTyController::class, 'getCompany']);
Route::post('/congty', [CongTyController::class, 'storeCompany']);
Route::get('/congty/{maCongTy}', [CongTyController::class, 'getCompanyById']);
Route::put('/congty/{maCongTy}', [CongTyController::class, 'update']);
Route::delete('/congty/{maCongTy}', [CongTyController::class, 'deleteCompany']);
Route::get('/nhanvien', [NguoiDungController::class, 'getNhanVien']);
Route::get('/nhanvien/{maND}', [NguoiDungController::class, 'getNhanVienById']);
Route::post('/addEmployee', [NguoiDungController::class, 'addEmployee']);
Route::put('/nhanvien/{maND}', [NguoiDungController::class, 'updateEmployee']);
Route::delete('/nhanvien/{maND}', [NguoiDungController::class, 'deleteEmployee']);
Route::post('/quanly', [NguoiDungController::class, 'addManager']);
Route::get('/quanly/{maCongTy}', [NguoiDungController::class, 'getManagerByCompanyId']);
Route::get('/nhanviencongty/{maCongTy}', [NguoiDungController::class, 'getEmployeeByCompanyID']);
Route::get('/taikhoanquanly/{maCongTy}', [NguoiDungController::class, 'showAccount']);




