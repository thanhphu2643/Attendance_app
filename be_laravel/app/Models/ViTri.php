<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ViTri extends Model
{
    use HasFactory;

    protected $table = 'vitri';
    protected $primaryKey = 'maViTri';
    protected $fillable = [
        'kinhDo',
        'viDo',
        'trangThai',
        'maCongTy',
        'maND',
    ];
}
