<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CongTySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Thêm các công ty vào cơ sở dữ liệu
        DB::table('congty')->insert([
            [
                'tenCongTy' => 'Highland Coffee',
                'diaDiem' => '123 Nguyễn Cơ Thạch, P.An Lợi Đông, Q.2, Thành phố Hồ Chí Minh, Việt Nam',
                'soDienThoai' => '028.12345678',
                'email' => 'customerservice@highlandscoffee.com.vn',
                'nguoiDaiDien' => 'David Thái',
                'linhVucKinhDoanh' => 'F&B',
            ],
           
        ]);
    }
}
