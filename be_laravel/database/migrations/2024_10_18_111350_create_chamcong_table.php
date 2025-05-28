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
        Schema::create('chamcong', function (Blueprint $table) {
            $table->id('maChamCong');
            $table->time('gioCheckin');
            $table->time('gioCheckout')->nullable();
            $table->date('ngay');
            $table->integer('tongGioLam')->nullable();
            $table->float('cong', 3, 2)->nullable();
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
        Schema::dropIfExists('chamcong');
    }
};
