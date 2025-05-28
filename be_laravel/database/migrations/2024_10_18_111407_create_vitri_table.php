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
        Schema::create('vitri', function (Blueprint $table) {
            $table->id('maViTri');
            $table->string('kinhDo');
            $table->string('viDo');
            $table->string('trangThai');
            $table->unsignedBigInteger('maND'); // Khóa ngoại
            $table->unsignedBigInteger('maCongTy'); // Khóa ngoại
            $table->foreign('maND')->references('maND')->on('nguoidung')->onDelete('cascade');
            $table->foreign('maCongTy')->references('maCongTy')->on('congty')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vitri');
    }
};
