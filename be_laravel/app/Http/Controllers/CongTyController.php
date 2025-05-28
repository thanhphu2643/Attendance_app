<?php

namespace App\Http\Controllers;

use App\Models\CongTy;
use Illuminate\Http\Request;

class CongTyController extends Controller
{
    public function getCompany(Request $request)
    {
        $searchQuery = $request->query('query', '');
    
        $congTy = CongTy::where('tenCongTy', 'like', '%' . $searchQuery . '%')->get();
    
        return response()->json($congTy);
    }

    public function storeCompany(Request $request)
    {
        // Xác thực dữ liệu
        $request->validate([
            'tenCongTy' => 'required|string|max:255',
            'diaDiem' => 'required|string|max:255',
            'soDienThoai' => 'required|string|max:255',
            'email' => 'required|string|email|max:255',
            'nguoiDaiDien' => 'required|string|max:255',
            'linhVucKinhDoanh' => 'required|string|max:255',
            'gioBatDau' => 'nullable|date_format:H:i',
            'gioKetThuc' => 'nullable|date_format:H:i',
        ]);
        

        // Tạo công ty mới
        $congTy = CongTy::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $congTy,
        ]);
    }

    public function getCompanyById($maCongTy)
    {
        // Tìm công ty theo mã
        $company = CongTy::where('maCongTy', $maCongTy)->first();

        // Kiểm tra xem công ty có tồn tại không
        if (!$company) {
            return response()->json(['message' => 'Công ty không tồn tại'], 404);
        }

        // Trả về thông tin công ty
        return response()->json($company, 200);
    }

    public function update(Request $request, $maCongTy)
{
    // Tìm công ty theo mã
    $company = CongTy::where('maCongTy', $maCongTy)->first();

    // Kiểm tra xem công ty có tồn tại không
    if (!$company) {
        return response()->json(['message' => 'Công ty không tồn tại'], 404);
    }

    // Xác thực dữ liệu đầu vào với các trường có thể được gửi
    $validatedData = $request->validate([
        'tenCongTy' => 'nullable|string|max:255',
        'diaChi' => 'nullable|string|max:255',
        'soDienThoai' => 'nullable|string|max:15',
        'gioBatDau' => 'nullable|date_format:H:i',  
        'gioKetThuc' => 'nullable|date_format:H:i', 
        'gioNghi' => 'nullable|numeric', 
    ]);

    // Cập nhật thông tin giờ bắt đầu và giờ kết thúc nếu có
    if ($request->has('gioBatDau')) {
        $company->gioBatDau = $request->input('gioBatDau');
    }
    if ($request->has('gioKetThuc')) {
        $company->gioKetThuc = $request->input('gioKetThuc');
    }
    if ($request->has('gioNghi')) {
        $company->gioNghi = (float)$request->input('gioNghi'); // Chuyển đổi gioNghi thành float
    }

    // Cập nhật các trường còn lại
    $company->update(array_filter($validatedData));

    return response()->json([
        'message' => 'Cập nhật công ty thành công',
        'company' => $company
    ], 200);
}


    public function deleteCompany($maCongTy)
    {
        try {
            // Tìm công ty theo mã
            $company = CongTy::where('maCongTy', $maCongTy)->first();
    
            // Kiểm tra nếu công ty tồn tại
            if (!$company) {
                return response()->json([
                    'message' => 'Công ty không tồn tại',
                ], 404);
            }
    
            // Xóa công ty
            $company->delete();
    
            // Trả về phản hồi thành công
            return response()->json([
                'message' => 'Công ty đã được xóa thành công',
            ], 200);
    
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Có lỗi xảy ra trong quá trình xóa công ty.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    public function updateWorkHours(Request $request)
    {
        // Validating the input data
        $validatedData = $request->validate([
            'maCongTy' => 'required|exists:congty,maCongTy',
            'gioBatDau' => 'nullable|date_format:H:i',
            'gioKetThuc' => 'nullable|date_format:H:i',
            'gioNghi' => 'nullable|string',
        ]);

        // Tìm công ty theo mã công ty
        $congTy = CongTy::find($validatedData['maCongTy']);

        // Cập nhật các trường giờ nếu có dữ liệu mới
        if (isset($validatedData['gioBatDau'])) {
            $congTy->gioBatDau = $validatedData['gioBatDau'];
        }
        if (isset($validatedData['gioKetThuc'])) {
            $congTy->gioKetThuc = $validatedData['gioKetThuc'];
        }
        if (isset($validatedData['gioNghi'])) {
            $congTy->gioNghi = $validatedData['gioNghi'];
        }

        // Lưu lại thông tin đã cập nhật
        $congTy->save();

        // Trả về phản hồi thành công
        return response()->json([
            'message' => 'Cập nhật giờ làm việc thành công',
            'data' => $congTy
        ]);
    }
    public function uploadLogo(Request $request, $companyId)
    {
        // Kiểm tra công ty có tồn tại
        $company = CongTy::find($companyId);
        if (!$company) {
            return response()->json(['message' => 'Công ty không tồn tại'], 404);
        }
    
        // Kiểm tra xem request có tệp logo không
        if ($request->hasFile('logo')) {
            $file = $request->file('logo');
    
            // Lưu tệp vào thư mục public/uploads
            $filePath = $file->store('uploads', 'public');
    
            // Cập nhật URL logo trong cơ sở dữ liệu
            $company->IMG = $filePath; // Lưu đường dẫn tệp vào trường IMG
            $company->save();
    
            return response()->json([
                'message' => 'Upload logo thành công',
                'logoUrl' => asset('storage/' . $filePath), // Trả về URL đầy đủ của logo
            ]);
        }
    
        return response()->json(['message' => 'Không tìm thấy tệp logo'], 400);
    }
    
    
}

