<?php

namespace App\Http\Controllers;

use App\Models\MlEstimation;
use Illuminate\Http\Request;

class MlController extends Controller
{
    public function estimate(Request $request)
    {
        $request->validate([
            'photos' => 'required|array|min:1|max:5',
            'photos.*' => 'required|string',
            'category' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
        ]);

        $estimation = $this->generateEstimate($request->photos, $request->category, $request->description);

        $record = MlEstimation::create(array_merge($estimation, [
            'category' => $request->category,
            'description' => $request->description,
            'photos' => $request->photos,
        ]));

        return response()->json([
            'status' => 'success',
            'message' => 'Estimasi ML berhasil dibuat.',
            'data' => [
                'id' => $record->id,
                'min_price' => (float) $record->min_price,
                'max_price' => (float) $record->max_price,
                'confidence' => (float) $record->confidence,
                'analysis' => $record->analysis,
            ],
        ]);
    }

    public function feedback(Request $request)
    {
        $request->validate([
            'estimation_id' => 'required|exists:ml_estimations,id',
            'actual_price' => 'required|numeric|min:0',
            'rating' => 'required|integer|min:1|max:5',
        ]);

        $estimation = MlEstimation::findOrFail($request->estimation_id);
        $estimation->update(['analysis' => array_merge($estimation->analysis ?? [], [
            'feedback' => [
                'actual_price' => $request->actual_price,
                'rating' => $request->rating,
            ],
        ])]);

        return response()->json([
            'status' => 'success',
            'message' => 'Feedback estimasi berhasil disimpan.',
            'data' => null,
        ], 201);
    }

    private function generateEstimate(array $photos, string $category, ?string $description): array
    {
        $base = match (strtolower($category)) {
            'ubah ukuran' => 70000,
            'ganti ritsleting' => 55000,
            'tambah' => 85000,
            'sulam' => 65000,
            default => 60000,
        };

        $variation = count($photos) * 0.12;
        $min = $base * (1 - $variation);
        $max = $base * (1 + $variation);
        $confidence = min(95, 70 + count($photos) * 5);

        return [
            'min_price' => (float) round($min, 2),
            'max_price' => (float) round($max, 2),
            'confidence' => (float) round($confidence, 2),
            'analysis' => [
                'category' => $category,
                'photo_count' => count($photos),
                'description_length' => strlen($description ?? ''),
            ],
        ];
    }
}
