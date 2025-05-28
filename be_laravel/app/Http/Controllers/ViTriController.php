<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ViTri;

class ViTriController extends Controller
{
    public function saveLocation(Request $request)
    {
        $validatedData = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',
            'maND' => 'required|integer',
            'maCongTy' => 'required|integer',
        ]);

        $latitude = $validatedData['latitude'];
        $longitude = $validatedData['longitude'];
        $maND = $validatedData['maND'];
        $maCongTy = $validatedData['maCongTy'];

        // Kiểm tra xem đã tồn tại bản ghi nào với maCongTy hay chưa
        $existingLocation = ViTri::where('maCongTy', $maCongTy)->first();

        if ($existingLocation) {
            // Nếu tồn tại, cập nhật trangThai = 0 cho tất cả các bản ghi hiện tại của maCongTy
            ViTri::where('maCongTy', $maCongTy)->update(['trangThai' => 0]);

            // Thêm bản ghi mới với tọa độ mới và trangThai = 1
            $newLocation = new ViTri();
            $newLocation->kinhDo = $latitude;
            $newLocation->viDo = $longitude;
            $newLocation->trangThai = 1;
            $newLocation->maCongTy = $maCongTy;
            $newLocation->maND = $maND;
            $newLocation->save();
        } else {
            // Nếu chưa có maCongTy, thêm bản ghi mới với trạng thái 1
            $newLocation = new ViTri();
            $newLocation->kinhDo = $latitude;
            $newLocation->viDo = $longitude;
            $newLocation->trangThai = 1;
            $newLocation->maCongTy = $maCongTy;
            $newLocation->maND = $maND;
            $newLocation->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Location saved successfully',
        ]);
    }
    public function getActiveLocation(Request $request)
{
    $validatedData = $request->validate([
        'maCongTy' => 'required|integer',
    ]);

    $maCongTy = $validatedData['maCongTy'];

    // Lấy vị trí với trạng thái hoạt động cho maCongTy
    $location = ViTri::where('maCongTy', $maCongTy)
        ->where('trangThai', 1)
        ->first(['kinhDo', 'viDo']);

    if ($location) {
        return response()->json([
            'success' => true,
            'data' => $location,
        ]);
    } else {
        return response()->json([
            'success' => false,
            'message' => 'No active location found for this company.',
        ], 404);
    }
}

}
