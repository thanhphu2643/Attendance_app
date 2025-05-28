<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class VaiTroSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
          // Thêm vai trò Quản trị viên
          DB::table('vaitro')->insert([
            ['tenVaiTro' => 'Quản trị viên'],
            ['tenVaiTro' => 'Quản lý'],
            ['tenVaiTro' => 'Nhân viên'],
        ]);
    }
}
