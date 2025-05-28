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
        Schema::create('taikhoan', function (Blueprint $table) {
            // Xóa cột id và biến tenDN thành khóa chính
            $table->string('tenDN', 191)->primary(); // Đặt tenDN là khóa chính
            $table->string('matKhau');
            $table->unsignedBigInteger('maND'); // Khóa ngoại
            $table->foreign('maND')->references('maND')->on('nguoidung')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('taikhoan');
    }
};
