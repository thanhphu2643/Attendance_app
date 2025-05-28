<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TaiKhoanController;

Route::get('/', function () {
    return view('welcome');
});
