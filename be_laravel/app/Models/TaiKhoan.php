<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TaiKhoan extends Model
{
    use HasFactory;
    protected $table = 'taikhoan';
    protected $primaryKey = 'maND';
    // Các thuộc tính mà bạn có thể gán giá trị
    protected $fillable = [
        'tenDN',      // Tên đăng nhập
        'matKhau',    // Mật khẩu
        'maND',       // Mã người dùng (khóa ngoại từ bảng nguoidung)
    ];

   
    public $timestamps = true;

    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'maND', 'maND');
    }
}
