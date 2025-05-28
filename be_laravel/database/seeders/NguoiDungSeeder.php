<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NguoiDungSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Thêm admin
        $adminId = DB::table('nguoidung')->insertGetId([
            'hoTen' => 'Phan Thị Bảo Trân',
            'diaChi' => 'Hồ Chí Minh',
            'ngaySinh' => '1990-01-01',
            'gioiTinh' => 'Nữ',
            'email' => 'BaoTran@gmail.com',
            'SDT' => '0123456789',
            'ngayBatDau' => '2024-10-10',
            'trangThaiKhuonMat' => 0, 
            'IMG' => null, 
            'maVaiTro' => 1, 
            'maCongTy' => 1, 
        ]);

        DB::table('taikhoan')->insert([
            'tenDN' => '01001',
            'matKhau' => bcrypt('123'), 
            'maND' => $adminId
        ]);

        // Thêm quản lý
        $managerId = DB::table('nguoidung')->insertGetId([
            'hoTen' => 'Nguyễn Thanh Phú',
            'diaChi' => 'Hồ Chí Minh',
            'ngaySinh' => '2003-04-26',
            'gioiTinh' => 'Nam',
            'email' => 'thanhphu@gmail.com',
            'SDT' => '0987654321',
            'ngayBatDau' => '2024-10-10',
            'trangThaiKhuonMat' => 0, 
            'IMG' => null, 
            'maVaiTro' => 2, 
            'maCongTy' => 1, 
        ]);

        DB::table('taikhoan')->insert([
            'tenDN' => '01002',
            'matKhau' => bcrypt('123'), 
            'maND' => $managerId    
        ]);

        // Thêm nhân viên
        $employeeId = DB::table('nguoidung')->insertGetId([
            'hoTen' => 'Lâm Văn Hưng',
            'diaChi' => 'Hồ Chí Minh',
            'ngaySinh' => '2003-08-09',
            'gioiTinh' => 'Nam',
            'email' => 'vanhung@gmail.com',
            'SDT' => '0353627994',
            'ngayBatDau' => '2024-10-10',
            'trangThaiKhuonMat' => 0, 
            'IMG' => null, 
            'maVaiTro' => 3, 
            'maCongTy' => 1,
        ]);

        DB::table('taikhoan')->insert([
            'tenDN' => '01003',
            'matKhau' => bcrypt('123'), 
            'maND' => $employeeId
        ]);
    }
}
