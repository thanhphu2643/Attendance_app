<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use App\Models\ChamCong;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithTitle;

class ChamCongExport implements FromCollection, WithHeadings, WithTitle
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        $reportData = $this->data->map(function ($item, $index) {
            return [
                'STT' => $index + 1,
                'hoTen' => $item->nguoidung ? $item->nguoidung->hoTen : 'Chưa có thông tin',
                'Ngay' => $item->ngay,
                'GioCheckin' => $item->gioCheckin,
                'GioCheckout' => $item->gioCheckout,
                'TongGioLam' => $item->tongGioLam,
                'Cong' => $item->cong,
            ];
        });
        return $reportData;
    }

    public function headings(): array
    {
        return [
            'STT',
            'Họ và Tên',
            'Ngày',
            'Giờ Check-in',
            'Giờ Check-out',
            'Tổng Giờ Làm',
            'Công',
        ];
    }

    public function title(): string
    {
        return 'Báo Cáo Chấm Công';
    }
}
