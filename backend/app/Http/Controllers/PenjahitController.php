<?php

namespace App\Http\Controllers;

use App\Models\Penjahit;
use Illuminate\Http\Request;

class PenjahitController extends Controller
{
    public function index(Request $request)
    {
        $penjahits = Penjahit::all();

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar penjahit berhasil diambil.',
            'data' => [
                'penjahits' => $penjahits,
            ],
        ]);
    }
}
