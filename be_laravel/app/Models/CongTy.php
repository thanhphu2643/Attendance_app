<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CongTy extends Model
{
    use HasFactory;

    protected $table = 'congty'; 

    protected $primaryKey = 'maCongTy'; 

    protected $fillable = [
        'tenCongTy',
        'diaDiem',
        'soDienThoai',
        'email',
        'nguoiDaiDien',
        'linhVucKinhDoanh',
        'trangThai',
        'IMG',
        'gioBatDau',
        'gioKetThuc',
        'gioNghi',
    ]; 

    public function nguoiDungs()
    {
        return $this->hasMany(NguoiDung::class, 'maCongTy', 'maCongTy');
    }
}
