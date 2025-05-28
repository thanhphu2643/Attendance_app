<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('nguoidung', function (Blueprint $table) {
            $table->id('maND');
            $table->string('hoTen');
            $table->string('diaChi');
            $table->date('ngaySinh');
            $table->string('gioiTinh');
            $table->string('email', 191)->unique();
            $table->string('SDT');
            $table->date('ngayBatDau');
            $table->boolean('trangThaiKhuonMat')->nullable(); // Sử dụng kiểu boolean
            $table->string('IMG')->nullable(); // Thêm thuộc tính IMG
            $table->unsignedBigInteger('maVaiTro'); // Cột khóa ngoại
            $table->unsignedBigInteger('maCongTy');
            $table->foreign('maVaiTro')->references('maVaiTro')->on('vaitro')->onDelete('cascade');
            $table->foreign('maCongTy')->references('maCongTy')->on('congty')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('nguoidung');
    }
};
