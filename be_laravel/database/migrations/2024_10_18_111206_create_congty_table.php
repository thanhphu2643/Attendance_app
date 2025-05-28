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
        Schema::create('congty', function (Blueprint $table) {
            $table->id('maCongTy');
            $table->string('tenCongTy');
            $table->string('diaDiem');
            $table->string('soDienThoai');
            $table->string('email');
            $table->string('nguoiDaiDien');
            $table->string('linhVucKinhDoanh');
            $table->string('IMG')->nullable();;
            $table->time('gioBatDau')->nullable();
            $table->time('gioKetThuc')->nullable();
            $table->float('gioNghi')->nullable();
            $table->timestamps();
        });
        
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('congty');
    }
};
