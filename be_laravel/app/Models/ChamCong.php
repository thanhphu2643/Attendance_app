<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChamCong extends Model
{
    use HasFactory;

    protected $table = 'chamcong';

    protected $primaryKey = 'maChamCong';

    public $incrementing = true; 

    protected $keyType = 'int';

    protected $fillable = [
        'gioCheckin', 
        'gioCheckout', 
        'ngay', 
        'tongGioLam', 
        'cong',
        'maND'
    ];

    public function nguoidung()
    {
        return $this->belongsTo(NguoiDung::class, 'maND', 'maND');
    }

}
