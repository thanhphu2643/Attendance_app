<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ChamCong;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\ChamCongExport;
use App\Models\CongTy;
use App\Models\NguoiDung;
class ChamCongController extends Controller
{
    public function chamCong(Request $request)
    {
        $userId = $request->input('maND');
        $currentDate = Carbon::now()->format('Y-m-d');
        $currentTime = Carbon::now()->format('H:i:s');

        try {
            $user = NguoiDung::where('maND', $userId)->first();

            if (!$user) {
                return response()->json(['message' => 'Không tìm thấy người dùng.'], 404);
            }

            $maCongTy = $user->maCongTy;  // Lấy maCongTy từ người dùng

            // Lấy giờ nghỉ (gioNghi) từ bảng congty theo maCongTy
            $company = CongTy::where('maCongTy', $maCongTy)->first();

            if (!$company) {
                return response()->json(['message' => 'Không tìm thấy thông tin công ty.'], 404);
            }

            $gioNghi = $company->gioNghi;  // Lấy giờ nghỉ của công ty

            // Truy vấn bảng ChamCong để xem người dùng đã chấm công chưa
            $chamCong = ChamCong::where('maND', $userId)
                                ->where('ngay', $currentDate)
                                ->first();

            if (!$chamCong) {
                // Nếu chưa có chấm công, tạo bản ghi mới
                $chamCong = ChamCong::create([
                    'maND' => $userId,
                    'ngay' => $currentDate,
                    'gioCheckin' => $currentTime,
                ]);

                return response()->json(['message' => 'Check-in thành công!', 'data' => $chamCong], 200);
            } elseif (!$chamCong->gioCheckout) {
                // Nếu đã check-in nhưng chưa check-out, tiến hành check-out
                $chamCong->update(['gioCheckout' => $currentTime]);

                $gioCheckin = Carbon::parse($chamCong->gioCheckin);
                $gioCheckout = Carbon::parse($currentTime);

                // Tính tổng phút làm
                $tongPhutLam = $gioCheckout->diffInMinutes($gioCheckin);

                // Tính tổng giờ làm (chuyển sang dạng float)
                $tongGioLam = $tongPhutLam / 60;

                // Trừ giờ nghỉ
                $gioNghi = $chamCong->gioNghi; // Giả sử trường gioNghi trong bảng ChamCong chứa dữ liệu nghỉ
                $gioNghiFloat = (float)$gioNghi;

                // Trừ giờ nghỉ vào tổng giờ làm
                $tongGioLam -= $gioNghiFloat;

                // Tính số công
                $cong = 0; // Mặc định là 0
                if ($tongGioLam >= 8) {
                    $cong = 1.0;
                } elseif ($tongGioLam >= 4) {
                    $cong = 0.5;
                }

                // Cập nhật tổng giờ làm và số công vào database
                $chamCong->update(['tongGioLam' => $tongGioLam, 'cong' => $cong]);

                return response()->json(['message' => 'Check-out thành công!', 'data' => $chamCong], 200);
            } else {
                return response()->json(['message' => 'Bạn đã check-in và check-out cho ngày hôm nay rồi.'], 400);
            }
        } catch (\Exception $e) {
            return response()->json(['message' => 'Đã xảy ra lỗi khi chấm công.', 'error' => $e->getMessage()], 500);
        }
    }


    public function thongKeCong(Request $request)
    {
        $userId = $request->input('maND');
        $currentMonth = Carbon::now()->format('Y-m');

        try {
            // Lấy maCongTy từ bảng nguoidung theo maND
            $user = NguoiDung::where('maND', $userId)->first();

            if (!$user) {
                return response()->json(['message' => 'Không tìm thấy người dùng.'], 404);
            }

            $maCongTy = $user->maCongTy;  // Lấy maCongTy từ người dùng

            // Lấy giờ làm việc (gioBatDau và gioKetThuc) từ bảng congty
            $companyWorkHours = CongTy::where('maCongTy', $maCongTy)->first();

            if (!$companyWorkHours) {
                return response()->json(['message' => 'Không tìm thấy thông tin giờ làm việc của công ty.'], 404);
            }

            $gioBatDau = $companyWorkHours->gioBatDau;
            $gioKetThuc = $companyWorkHours->gioKetThuc;

            // Lấy các bản ghi chấm công trong tháng hiện tại
            $chamCongRecords = ChamCong::where('maND', $userId)
                                        ->where('ngay', 'like', "$currentMonth%")
                                        ->get();

            $tongCong = 0.0;
            $ngayDiTre = [];
            $ngayVeSom = [];

            foreach ($chamCongRecords as $record) {
                if ($record->cong) {
                    $tongCong += (float) $record->cong;
                }

                // Kiểm tra nếu giờ checkin trễ hơn giờ bắt đầu (gioBatDau)
                if ($record->gioCheckin && Carbon::parse($record->gioCheckin)->greaterThan(Carbon::parse($gioBatDau))) {
                    $ngayDiTre[] = [
                        'ngay' => $record->ngay,
                        'gioCheckin' => $record->gioCheckin,
                    ];
                }

                // Kiểm tra nếu giờ checkout sớm hơn giờ kết thúc (gioKetThuc)
                if ($record->gioCheckout && Carbon::parse($record->gioCheckout)->lessThan(Carbon::parse($gioKetThuc))) {
                    $ngayVeSom[] = [
                        'ngay' => $record->ngay,
                        'gioCheckout' => $record->gioCheckout,
                    ];
                }
            }

            return response()->json([
                'tongCong' => $tongCong,
                'soNgayDiTre' => count($ngayDiTre),
                'chiTietDiTre' => $ngayDiTre,
                'soNgayVeSom' => count($ngayVeSom),
                'chiTietVeSom' => $ngayVeSom,
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Đã xảy ra lỗi khi lấy thông tin chấm công.', 'error' => $e->getMessage()], 500);
        }
    }

    public function chitietChamCong(Request $request)
    {
        $userId = $request->input('maND');
        $currentDate = Carbon::now()->format('Y-m-d');

        try {
            $chamCong = ChamCong::where('maND', $userId)
                                ->where('ngay', $currentDate)
                                ->first();

            if ($chamCong) {
                return response()->json(['message' => 'Lấy chi tiết chấm công thành công!', 'data' => $chamCong], 200);
            } else {
                return response()->json(['message' => 'Không tìm thấy bản ghi chấm công cho ngày hôm nay.'], 404);
            }
        } catch (\Exception $e) {
            return response()->json(['message' => 'Đã xảy ra lỗi khi lấy thông tin chấm công.', 'error' => $e->getMessage()], 500);
        }
    }

    public function baoCaoTheoThoiGian(Request $request)
    {
        $userId = $request->input('maND');
        $startDate = $request->input('startDate');
        $endDate = $request->input('endDate');
    
        try {
            // Lấy maCongTy từ bảng nguoidung theo maND
            $user = NguoiDung::where('maND', $userId)->first();
    
            if (!$user) {
                return response()->json(['message' => 'Không tìm thấy người dùng.'], 404);
            }
    
            $maCongTy = $user->maCongTy;  // Lấy maCongTy từ người dùng
    
            // Lấy giờ làm việc (gioBatDau và gioKetThuc) từ bảng congty
            $companyWorkHours = CongTy::where('maCongTy', $maCongTy)->first();
    
            if (!$companyWorkHours) {
                return response()->json(['message' => 'Không tìm thấy thông tin giờ làm việc của công ty.'], 404);
            }
    
            $gioBatDau = $companyWorkHours->gioBatDau;
            $gioKetThuc = $companyWorkHours->gioKetThuc;
    
            // Lấy các bản ghi chấm công trong khoảng thời gian
            $chamCongRecords = ChamCong::where('maND', $userId)
                                        ->whereBetween('ngay', [$startDate, $endDate])
                                        ->get();
    
            if ($chamCongRecords->isEmpty()) {
                return response()->json(['message' => 'Không tìm thấy bản ghi chấm công trong khoảng thời gian đã cho.'], 404);
            }
    
            $tongCong = 0.0;
            $ngayDiTre = [];
            $ngayVeSom = [];
    
            foreach ($chamCongRecords as $record) {
                // Cập nhật tổng công
                if ($record->cong) {
                    $tongCong += (float) $record->cong;
                }
    
                // Kiểm tra nếu giờ checkin trễ hơn giờ bắt đầu (gioBatDau)
                if ($record->gioCheckin && Carbon::parse($record->gioCheckin)->greaterThan(Carbon::parse($gioBatDau))) {
                    $ngayDiTre[] = [
                        'ngay' => $record->ngay,
                        'gioCheckin' => $record->gioCheckin,
                    ];
                }
    
                // Kiểm tra nếu giờ checkout sớm hơn giờ kết thúc (gioKetThuc)
                if ($record->gioCheckout && Carbon::parse($record->gioCheckout)->lessThan(Carbon::parse($gioKetThuc))) {
                    $ngayVeSom[] = [
                        'ngay' => $record->ngay,
                        'gioCheckout' => $record->gioCheckout,
                    ];
                }
            }
    
            return response()->json([
                'tongCong' => $tongCong,
                'soNgayDiTre' => count($ngayDiTre),
                'chiTietDiTre' => $ngayDiTre,
                'soNgayVeSom' => count($ngayVeSom),
                'chiTietVeSom' => $ngayVeSom,
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Đã xảy ra lỗi khi lấy báo cáo chấm công.', 'error' => $e->getMessage()], 500);
        }
    }
    public function getChamCongByPeriod(Request $request)
    {
        $validated = $request->validate([
            'maND' => 'required|integer',
            'period' => 'required|string', // 1 Tuần, 2 Tuần, 1 Tháng, Tùy Chọn
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);
    
        $maND = $validated['maND'];
        $period = $validated['period'];
    
        $startDate = Carbon::today(); // Ngày hiện tại
        $endDate = $startDate; // Ngày kết thúc mặc định là ngày hôm nay
    
        // Xác định thời gian bắt đầu và kết thúc dựa trên period
        if ($period == "1 Tuần") {
            $startDate = $startDate->copy()->subDays(7); // Ngày bắt đầu là 7 ngày trước
        } elseif ($period == "2 Tuần") {
            $startDate = $startDate->copy()->subDays(14); // Ngày bắt đầu là 14 ngày trước
        } elseif ($period == "1 Tháng") {
            $startDate = $startDate->copy()->subDays(30); // Ngày bắt đầu là đầu tháng
        } elseif ($period == "Tùy Chọn") {
            if (!$request->start_date || !$request->end_date) {
                return response()->json(['error' => 'Start date and end date are required for custom period'], 400);
            }
            // Xử lý ngày bắt đầu và kết thúc cho tùy chọn
            $startDate = Carbon::parse($request->start_date)->startOfDay();
            $endDate = Carbon::parse($request->end_date)->endOfDay();
        }
    
        // Lấy thông tin giờ làm việc từ bảng CongTy theo maCongTy của người dùng
        $user = NguoiDung::where('maND', $maND)->first();
        if (!$user) {
            return response()->json(['message' => 'Không tìm thấy người dùng.'], 404);
        }
    
        $maCongTy = $user->maCongTy; // Lấy maCongTy từ người dùng
    
        $companyWorkHours = CongTy::where('maCongTy', $maCongTy)->first();
        if (!$companyWorkHours) {
            return response()->json(['message' => 'Không tìm thấy thông tin giờ làm việc của công ty.'], 404);
        }
    
        $gioBatDau = $companyWorkHours->gioBatDau;
        $gioKetThuc = $companyWorkHours->gioKetThuc;
    
        // Lấy thông tin chấm công trong khoảng thời gian
        $attendance = ChamCong::where('maND', $maND)
            ->whereBetween(\DB::raw('DATE(ngay)'), [$startDate->toDateString(), $endDate->toDateString()])
            ->get();
    
        // Xử lý thông tin chấm công và tính toán status cho từng ngày
        $attendanceData = $attendance->map(function ($entry) use ($gioBatDau, $gioKetThuc) {
            $entry->status = 'Vắng mặt'; // Mặc định là vắng mặt
    
            if ($entry->gioCheckin && $entry->gioCheckout) {
                // Nếu có checkin và checkout, tính số công
                $entry->status = 'Có mặt';
            }
    
            // Kiểm tra nếu giờ checkin trễ hơn giờ bắt đầu (gioBatDau)
            if ($entry->gioCheckin && Carbon::parse($entry->gioCheckin)->greaterThan(Carbon::parse($gioBatDau))) {
                $entry->status = 'Đi trễ';
            }
    
            // Kiểm tra nếu giờ checkout sớm hơn giờ kết thúc (gioKetThuc)
            if ($entry->gioCheckout && Carbon::parse($entry->gioCheckout)->lessThan(Carbon::parse($gioKetThuc))) {
                $entry->status = 'Về sớm';
            }
    
            return $entry;
        });
    
        return response()->json($attendanceData);
    }
    
    public function export(Request $request)
    {
        // Kiểm tra tham số đầu vào
        $startDate = $request->input('startDate');
        $endDate = $request->input('endDate');
        $maND = $request->input('maND');
        $isSelectAll = $request->input('isSelectAll') === '1';
        $maCongTy = $request->input('maCongTy'); // Nhận thông tin mã công ty từ request
    
        // Kiểm tra nếu thiếu tham số quan trọng
        if (!$startDate || !$endDate) {
            return response()->json(['error' => 'Thiếu thông tin ngày bắt đầu hoặc ngày kết thúc'], 400);
        }
    
        // Lấy dữ liệu từ bảng chấm công
        $query = ChamCong::whereBetween('ngay', [$startDate, $endDate]);
    
        // Nếu chọn nhân viên cụ thể
        if ($maND && !$isSelectAll) {
            $query->where('maND', $maND);
        }
    
        // Nếu chọn công ty cụ thể, lọc theo mã công ty
        if ($maCongTy) {
            $query->whereHas('nguoidung', function($query) use ($maCongTy) {
                $query->where('maCongTy', $maCongTy);
            });
        }
    
        // Lấy dữ liệu
        $data = $query->with('nguoidung')->get();
    
        // Kiểm tra nếu không có dữ liệu
        if ($data->isEmpty()) {
            return response()->json(['error' => 'Không có dữ liệu'], 404);
        }
    
        $date = \Carbon\Carbon::now()->format('Hisdmy'); 
    
        // Tạo tên file với ngày tháng năm
        $fileName = 'chamcong_report_' . $date . '.xlsx';
    
        // Tạo đối tượng xuất Excel
        $export = new ChamCongExport($data);
    
        // Lưu file vào đường dẫn tạm thời
        $pathToFile = storage_path('app/public/' . $fileName);
    
        // Xuất tệp Excel và lưu vào thư mục tạm
        Excel::store($export, 'public/' . $fileName);
    
        // Trả về tệp Excel để người dùng tải về
        return response()->download($pathToFile, $fileName, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ]);
    }
    


}
