<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NguoiDung extends Model
{
    use HasFactory;

    // Tên bảng
    protected $table = 'nguoidung';

    // Khóa chính
    protected $primaryKey = 'maND';

    // Các thuộc tính có thể được gán
    protected $fillable = [
        'hoTen',
        'diaChi',
        'ngaySinh',
        'gioiTinh',
        'email',
        'SDT',
        'ngayBatDau',
        'ngayKetThuc',
        'trangThaiKhuonMat',
        'IMG',
        'maVaiTro',
        'maCongTy'
    ];

    // Các trường timestamps sẽ tự động được lưu
    public $timestamps = true;

    // Cấu hình quan hệ với các bảng liên quan
    public function vaiTro()
    {
        return $this->belongsTo(VaiTro::class, 'maVaiTro');
    }

    public function congTy()
    {
        return $this->belongsTo(CongTy::class, 'maCongTy');
    }
    public function taiKhoan()
    {
        return $this->hasOne(TaiKhoan::class, 'maND'); 
    }
    public function chamcong()
    {
        return $this->hasMany(ChamCong::class, 'maND', 'maND');
    }

}
