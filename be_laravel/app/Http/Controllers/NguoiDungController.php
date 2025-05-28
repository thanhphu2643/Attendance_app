<?php

namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\NguoiDung;
use App\Models\TaiKhoan;  
use App\Models\CongTy;  
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use App\Mail\AccountCreatedMail; 
use Illuminate\Support\Facades\Mail; 
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class NguoiDungController extends Controller
{
    public function getNguoiDung(Request $request)
    {
        // Kiểm tra phương thức HTTP
        if ($request->isMethod('post')) {
            // Kiểm tra xem maND có trong request không
            if ($request->has('maND')) {
                $maND = $request->input('maND');
    
                // Tìm người dùng theo maND
                try {
                    $nguoiDung = NguoiDung::where('maND', $maND)->first();
    
                    if ($nguoiDung) {
                        return response()->json([
                            'status' => 'success',
                            'data' => $nguoiDung
                        ]);
                    } else {
                        return response()->json([
                            'status' => 'error',
                            'message' => 'Không tìm thấy thông tin người dùng'
                        ], 404);
                    }
                } catch (\Exception $e) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Đã xảy ra lỗi: ' . $e->getMessage()
                    ], 500);
                }
            } else {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Thiếu thông tin maND'
                ], 400);
            }
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Yêu cầu không hợp lệ, vui lòng sử dụng phương thức POST'
            ], 405);
        }
    }
    public function getNDCongTY(Request $request)
    {
        // Kiểm tra phương thức HTTP
        if ($request->isMethod('post')) {
            // Kiểm tra xem maND có trong request không
            if ($request->has('maND')) {
                $maND = $request->input('maND');
        
                // Tìm người dùng theo maND
                try {
                    $user = NguoiDung::where('maND', $maND)->first();
        
                    if ($user) {
                        // Lấy maCongTy từ người dùng
                        $maCongTy = $user->maCongTy;
                        
                        // Lấy tên công ty từ bảng CongTy
                        $company = CongTy::where('maCongTy', $maCongTy)->first();
                        
                        if ($company) {
                            return response()->json([
                                'status' => 'success',
                                'data' => [
                                    'nguoiDung' => $user,  // Trả về thông tin người dùng
                                    'tenCongTy' => $company->tenCongTy  // Trả về tên công ty
                                ]
                            ]);
                        } else {
                            return response()->json([
                                'status' => 'error',
                                'message' => 'Không tìm thấy công ty'
                            ], 404);
                        }
                    } else {
                        return response()->json([
                            'status' => 'error',
                            'message' => 'Không tìm thấy người dùng'
                        ], 404);
                    }
                } catch (\Exception $e) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Đã xảy ra lỗi: ' . $e->getMessage()
                    ], 500);
                }
            } else {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Thiếu thông tin maND'
                ], 400);
            }
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Yêu cầu không hợp lệ, vui lòng sử dụng phương thức POST'
            ], 405);
        }
    }
    

    public function updateFaceStatus(Request $request)
    {
        $request->validate([
            'maND' => 'required|integer', // Chỉnh sửa tên tham số để phù hợp với bảng
            'trangThaiKhuonMat' => 'required|boolean',
        ]);

        // Tìm người dùng theo maND
        $nguoiDung = NguoiDung::where('maND', $request->maND)->first(); // Sử dụng maND

        if ($nguoiDung) {
            $nguoiDung->trangThaiKhuonMat = $request->trangThaiKhuonMat; // Cập nhật trạng thái
            $nguoiDung->save();

            return response()->json(['message' => 'Cập nhật trạng thái thành công'], 200);
        }

        return response()->json(['message' => 'Người dùng không tìm thấy'], 404);
    }
    public function getNguoiDungWithCompany(Request $request)
    {
        if ($request->isMethod('post')) {
            if ($request->has('maND')) {
                $maND = $request->input('maND');

                try {
                    $nguoiDung = NguoiDung::with('congTy')->where('maND', $maND)->first();

                    if ($nguoiDung) {
                        return response()->json([
                            'status' => 'success',
                            'data' => [
                                'nguoiDung' => $nguoiDung,
                                'congTy' => $nguoiDung->congTy, // Lấy thông tin công ty liên quan
                            ]
                        ]);
                    } else {
                        return response()->json([
                            'status' => 'error',
                            'message' => 'Không tìm thấy thông tin người dùng'
                        ], 404);
                    }
                } catch (\Exception $e) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Đã xảy ra lỗi: ' . $e->getMessage()
                    ], 500);
                }
            } else {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Thiếu thông tin maND'
                ], 400);
            }
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Yêu cầu không hợp lệ, vui lòng sử dụng phương thức POST'
            ], 405);
        }
    }
    public function updateUser(Request $request)
    {
        // Kiểm tra phương thức HTTP
        if ($request->isMethod('post')) {
            // Xác thực dữ liệu đầu vào
            $request->validate([
                'maND' => 'required|integer',
                'hoTen' => 'required|string|max:255',
                'email' => 'required|email|max:255',
                'diaChi' => 'nullable|string|max:255',
                'SDT' => 'nullable|string|max:20',
                'gioiTinh' => 'nullable|string|max:10',
                'IMG' => 'nullable|image|mimes:jpg,jpeg,png|max:2048', // Giới hạn kích thước hình ảnh nếu có
            ]);

            // Tìm người dùng theo maND
            $nguoiDung = NguoiDung::where('maND', $request->maND)->first();

            if ($nguoiDung) {
                // Cập nhật thông tin người dùng
                $nguoiDung->hoTen = $request->hoTen;
                $nguoiDung->email = $request->email;
                $nguoiDung->diaChi = $request->diaChi;
                $nguoiDung->SDT = $request->SDT;
                $nguoiDung->gioiTinh = $request->gioiTinh;
                // Kiểm tra xem có hình ảnh mới không
                if ($request->hasFile('IMG')) {
                    // Xử lý hình ảnh, bạn có thể thay đổi đường dẫn lưu hình ảnh tùy ý
                    $imagePath = $request->file('IMG')->store('uploads', 'public');
                    $nguoiDung->IMG = $imagePath; // Giả sử bạn có cột image_path trong bảng người dùng
                }

                // Lưu thay đổi
                $nguoiDung->save();

                return response()->json([
                    'status' => 'success',
                    'message' => 'Cập nhật thông tin thành công',
                    'data' => $nguoiDung
                ], 200);
            }

            return response()->json(['status' => 'error', 'message' => 'Người dùng không tìm thấy'], 404);
        }

        return response()->json(['status' => 'error', 'message' => 'Yêu cầu không hợp lệ, vui lòng sử dụng phương thức POST'], 405);
    }
    public function createAccount(Request $request)
    {
        // Validate the request
        $validator = Validator::make($request->all(), [
            'hoTen' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:nguoidung',
            'diaChi' => 'required|string|max:255',
            'soDienThoai' => 'required|string|max:15',
            'gioiTinh' => 'required|string|in:Nam,Nữ',
            'ngaySinh' => 'nullable|date',
            'maCongTy' => 'required|exists:congty,maCongTy',
            'maVaiTro' => 'required|exists:vaitro,maVaiTro',
            'username' => 'required|string|max:255|unique:taikhoan',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Tạo người dùng
        $nguoiDung = NguoiDung::create([
            'hoTen' => $request->hoTen,
            'email' => $request->email,
            'diaChi' => $request->diaChi,
            'soDienThoai' => $request->soDienThoai,
            'gioiTinh' => $request->gioiTinh,
            'ngaySinh' => $request->ngaySinh,
            'maCongTy' => $request->maCongTy,
            'maVaiTro' => $request->maVaiTro,
        ]);

        // Tạo tài khoản
        TaiKhoan::create([
            'maND' => $nguoiDung->maND,
            'username' => $request->username,
            'password' => bcrypt($request->password), // Mã hóa mật khẩu
        ]);
       
        return response()->json([
            'message' => 'Tài khoản đã được tạo thành công!',
            'nguoiDung' => $nguoiDung,
        ], 201);
    }

    public function getNhanVien()
    {
        // Lấy tất cả nhân viên có maVaiTro = 3
        $nhanVien = NguoiDung::where('maVaiTro', 3)->get();

        // Trả về dữ liệu nhân viên
        return response()->json($nhanVien);
    }

    public function getNhanVienById($maND)
    {
        // Tìm nhân viên có maND bằng $maND và maVaiTro là 3
        $nhanVien = NguoiDung::where('maVaiTro', 3)->where('maND', $maND)->first();

        // Kiểm tra nếu nhân viên không tồn tại
        if (!$nhanVien) {
            return response()->json([
                'message' => 'Nhân viên không tồn tại.'
            ], 404);
        }

        // Trả về dữ liệu nhân viên
        return response()->json($nhanVien);
    }
    public function getEmployeeByCompanyID($companyID, $searchQuery = null)
    {
        // Start building the query to get employees for the specified company ID and role
        $query = NguoiDung::where('maCongTy', $companyID)
                          ->where('maVaiTro', 3);
    
        // Apply search condition for 'hoTen' if searchQuery is provided
        if (!is_null($searchQuery) && !empty($searchQuery)) {
            $query->where('hoTen', 'like', '%' . $searchQuery . '%');
        }
    
        // Execute the query to get the employees
        $employees = $query->get();
    
        // Check if no employees were found
        if ($employees->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Không có nhân viên nào được tìm thấy cho công ty này.',
            ], 404);
        }
    
        // Return the list of employees
        return response()->json([
            'success' => true,
            'data' => $employees,
        ], 200);
    }
    
    public function addEmployee(Request $request)
    {
        try {
            // Xác thực dữ liệu đầu vào
            $request->validate([
                'hoTen' => 'required|string|max:255',
                'diaChi' => 'nullable|string|max:255',
                'ngaySinh' => 'nullable|date',
                'gioiTinh' => 'nullable|string|max:10',
                'email' => 'required|email|unique:nguoidung,email', // Kiểm tra bảng nguoidung
                'SDT' => 'required|string|max:15',
                'maCongTy' => 'required|integer|exists:congty,maCongTy', // Kiểm tra mã công ty
            ]);
    
            // Lấy mã công ty và thêm 0 vào đầu nếu cần
            $maCongTy = str_pad($request->maCongTy, 2, '0', STR_PAD_LEFT);
    
            // Xác định mã người dùng mới
            $lastNguoiDung = NguoiDung::where('maCongTy', $request->maCongTy)->orderBy('maND', 'desc')->first();
            $maNguoiDung = $lastNguoiDung ? $lastNguoiDung->maND + 1 : 1;
    
            // Tạo tên tài khoản
            $tenTaiKhoan = $maCongTy . str_pad($maNguoiDung, 3, '0', STR_PAD_LEFT);
    
            // Tạo nhân viên mới
            $nhanVien = NguoiDung::create([
                'hoTen' => $request->hoTen,
                'diaChi' => $request->diaChi,
                'ngaySinh' => $request->ngaySinh,
                'gioiTinh' => $request->gioiTinh,
                'email' => $request->email,
                'SDT' => $request->SDT,
                'ngayBatDau' => Carbon::now()->toDateString(), // Ngày bắt đầu
                'trangThaiKhuonMat' => '0', // Trạng thái khuôn mặt
                'maVaiTro' => 3, // Mã vai trò
                'maCongTy' => $request->maCongTy,
            ]);
            $matKhau = Str::random(8);
            // Tạo tài khoản cho người dùng mới
            TaiKhoan::create([
                'tenDN' => $tenTaiKhoan,
                'matKhau' => bcrypt($matKhau), // Mật khẩu mặc định đã được mã hóa
                'maND' => $nhanVien->maND, // Liên kết tài khoản với người dùng
            ]);
            try {
                Mail::to($request->email)->queue(new AccountCreatedMail($tenTaiKhoan, $matKhau));
                Log::info('Email sent successfully to ' . $request->email);
            } catch (\Exception $e) {
                Log::error('Error sending email: ' . $e->getMessage());
                return response()->json(['message' => 'Có lỗi xảy ra: ' . $e->getMessage()], 500);
            }
            return response()->json(['message' => 'Nhân viên được tạo thành công', 'nhanVien' => $nhanVien, 'tenTaiKhoan' => $tenTaiKhoan], 201);
        } catch (\Exception $e) {
            // Xử lý lỗi, trả về status code 500 và thông báo lỗi
            return response()->json(['message' => 'Có lỗi xảy ra: ' . $e->getMessage()], 500);
        }
    }

    public function addManager(Request $request)
    {
        try {
            // Xác thực dữ liệu đầu vào
            $request->validate([
                'hoTen' => 'required|string|max:255',
                'diaChi' => 'nullable|string|max:255',
                'ngaySinh' => 'nullable|date',
                'gioiTinh' => 'nullable|string|max:10',
                'email' => 'required|email|unique:nguoidung,email', // Kiểm tra bảng nguoidung
                'SDT' => 'required|string|max:15',
                'maCongTy' => 'required|integer|exists:congty,maCongTy', // Kiểm tra mã công ty
            ]);
    
            // Lấy mã công ty và thêm 0 vào đầu nếu cần
            $maCongTy = str_pad($request->maCongTy, 2, '0', STR_PAD_LEFT);
    
            // Xác định mã người dùng mới
            $lastNguoiDung = NguoiDung::where('maCongTy', $request->maCongTy)->orderBy('maND', 'desc')->first();
            $maNguoiDung = $lastNguoiDung ? $lastNguoiDung->maND + 1 : 1;
    
            // Tạo tên tài khoản
            $tenTaiKhoan = $maCongTy . str_pad($maNguoiDung, 3, '0', STR_PAD_LEFT);
    
            // Tạo nhân viên mới
            $nhanVien = NguoiDung::create([
                'hoTen' => $request->hoTen,
                'diaChi' => $request->diaChi,
                'ngaySinh' => $request->ngaySinh,
                'gioiTinh' => $request->gioiTinh,
                'email' => $request->email,
                'SDT' => $request->SDT,
                'ngayBatDau' => Carbon::now()->toDateString(), // Ngày bắt đầu
                'trangThaiKhuonMat' => '0', // Trạng thái khuôn mặt
                'maVaiTro' => 2, // Mã vai trò
                'maCongTy' => $request->maCongTy,
            ]);
            $matKhau = Str::random(8);
            // Tạo tài khoản cho người dùng mới
            TaiKhoan::create([
                'tenDN' => $tenTaiKhoan,
                'matKhau' => bcrypt($matKhau), // Mật khẩu mặc định đã được mã hóa
                'maND' => $nhanVien->maND, // Liên kết tài khoản với người dùng
            ]);
            try {
                Mail::to($request->email)->queue(new AccountCreatedMail($tenTaiKhoan, $matKhau));
                Log::info('Email sent successfully to ' . $request->email);
            } catch (\Exception $e) {
                Log::error('Error sending email: ' . $e->getMessage());
                return response()->json(['message' => 'Có lỗi xảy ra: ' . $e->getMessage()], 500);
            }
            return response()->json(['message' => 'Nhân viên được tạo thành công', 'nhanVien' => $nhanVien, 'tenTaiKhoan' => $tenTaiKhoan], 201);
        } catch (\Exception $e) {
            // Xử lý lỗi, trả về status code 500 và thông báo lỗi
            return response()->json(['message' => 'Có lỗi xảy ra: ' . $e->getMessage()], 500);
        }
    }
    public function deleteEmployee($maND)
    {
        try {
            // Tìm nhân viên theo mã người dùng (maND)
            $nhanVien = NguoiDung::where('maND', $maND)->first();

            // Kiểm tra xem nhân viên có tồn tại không
            if (!$nhanVien) {
                return response()->json(['message' => 'Nhân viên không tồn tại.'], 404);
            }

            // Tìm tài khoản liên quan đến nhân viên
            $taiKhoan = TaiKhoan::where('maND', $maND)->first();

            // Xóa tài khoản nếu có
            if ($taiKhoan) {
                $taiKhoan->delete();
            }

            // Xóa nhân viên
            $nhanVien->delete();

            // Trả về phản hồi thành công
            return response()->json(['message' => 'Nhân viên và tài khoản đã được xóa thành công.'], 200);
        } catch (\Exception $e) {
            // Xử lý ngoại lệ
            return response()->json(['message' => 'Có lỗi xảy ra: ' . $e->getMessage()], 500);
        }
    }
    // Hung
    public function getEmployees(Request $request)
    {
        try {
            $companyId = $request->input('maCongTy');
            $search = $request->input('search', '');
            
            // Thêm điều kiện lọc theo mã vai trò là 3
            $employees = NguoiDung::where('maCongTy', $companyId)
                                  ->where('maVaiTro', 3)  
                                  ->where('hoTen', 'like', '%' . $search . '%')  
                                  ->get(['hoTen', 'maND']);
            
            return response()->json($employees);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
    public function updateEmployee(Request $request, $maND)
    {
        // Tìm nhân viên theo mã
        $employee = NguoiDung::where('maND', $maND)->first();

        // Kiểm tra xem nhân viên có tồn tại không
        if (!$employee) {
            return response()->json(['message' => 'Nhân viên không tồn tại'], 404);
        }

        // Xác thực dữ liệu đầu vào với các trường có thể được gửi
        $validatedData = $request->validate([
            'hoTen' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
            'SDT' => 'nullable|string|max:15',
        ]);

        // Cập nhật thông tin nhân viên
        $employee->update(array_filter($validatedData));

        return response()->json([
            'message' => 'Cập nhật thông tin nhân viên thành công',
            'employee' => $employee
        ], 200);
    }
    public function getManagerByCompanyId($maCongTy)
    {
        // Truy vấn người quản lý và lấy tên đăng nhập từ bảng TaiKhoan
        $managers = NguoiDung::where('maCongTy', $maCongTy)
                            ->where('maVaiTro', 2) // Giả sử vai trò "2" là người quản lý
                            ->with('taiKhoan') // Eager load quan hệ với bảng TaiKhoan
                            ->get();
    
        if ($managers->isEmpty()) {
            return response()->json([
                'error' => 'No managers found for this company'
            ], 404);
        }
    
        // Trả về danh sách người quản lý cùng tên đăng nhập
        return response()->json([
            'data' => $managers->map(function ($manager) {
                return [
                    'hoTen' => $manager->hoTen,
                    'tenDN' => $manager->taiKhoan->tenDN, // Lấy tên đăng nhập từ bảng TaiKhoan
                ];
            })
        ], 200);
    }
    
    public function showAccount($maCongTy)
    {
        // Truy vấn với JOIN giữa NguoiDung và TaiKhoan
        $result = DB::table('nguoidung')
            ->join('taikhoan', 'nguoidung.maND', '=', 'taikhoan.maND')
            ->where('nguoidung.maVaiTro', 2)
            ->where('nguoidung.maCongTy', $maCongTy)
            ->select('taikhoan.tenTK', 'taikhoan.matKhau')
            ->get();

        // Kiểm tra nếu không tìm thấy kết quả
        if ($result->isEmpty()) {
            return response()->json([
                'message' => 'Không tìm thấy người dùng nào với maCongTy: ' . $maCongTy
            ], 404);
        }

        return response()->json($result);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);
    
        $email = $request->input('email');
    
        // Kiểm tra email có tồn tại trong bảng nguoidung không
        $nguoiDung = NguoiDung::where('email', $email)->first();
    
        if (!$nguoiDung) {
            return response()->json([
                'success' => false,
                'message' => 'Email không tồn tại trong hệ thống.',
            ], 404);
        }
    
        // Lấy mã người dùng (maND)
        $maND = $nguoiDung->maND;
    
        // Tìm tài khoản tương ứng trong bảng taikhoan
        $taiKhoan = TaiKhoan::where('maND', $maND)->first();
    
        if (!$taiKhoan) {
            return response()->json([
                'success' => false,
                'message' => 'Không tìm thấy tài khoản liên kết với email này.',
            ], 404);
        }
    
        $tenTaiKhoan = $taiKhoan->tenDN;
    
        // Tạo mật khẩu mới ngẫu nhiên
        $matKhau = Str::random(8);
    
        // Cập nhật mật khẩu trong cơ sở dữ liệu
        $taiKhoan->matKhau = Hash::make($matKhau);
        $updateSuccess = $taiKhoan->save();
    
        if (!$updateSuccess) {
            return response()->json([
                'success' => false,
                'message' => 'Không thể cập nhật mật khẩu. Vui lòng thử lại sau.',
            ], 500);
        }
    
        // Gửi email với mật khẩu mới
        try {
            Mail::to($request->email)->queue(new AccountCreatedMail($tenTaiKhoan, $matKhau));
            Log::info('Email sent successfully to ' . $request->email);
    
            return response()->json([
                'success' => true,
                'message' => 'Mật khẩu mới đã được gửi đến email của bạn.',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gửi email thất bại: ' . $e->getMessage(),
            ], 500);
        }
    }
    

}
