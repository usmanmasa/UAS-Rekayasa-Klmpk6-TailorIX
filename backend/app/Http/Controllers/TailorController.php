<?php

namespace App\Http\Controllers;

use App\Models\FavoriteTailor;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class TailorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::query()->where('role', 'tailor')->where('is_verified', true);

        if ($request->filled('q')) {
            $keyword = '%' . $request->q . '%';
            $query->where(function ($sub) use ($keyword, $request) {
                $sub->where('name', 'like', $keyword)
                    ->orWhere('shop_name', 'like', $keyword)
                    ->orWhere('city', 'like', $keyword)
                    ->orWhereJsonContains('specializations', $request->q);
            });
        }

        if ($request->filled('category')) {
            $query->whereJsonContains('specializations', $request->category);
        }

        if ($request->filled('min_rating')) {
            $query->where('rating', '>=', floatval($request->min_rating));
        }

        if ($request->filled(['lat', 'lng', 'radius'])) {
            $lat = floatval($request->lat);
            $lng = floatval($request->lng);
            $radius = floatval($request->radius);

            $query->selectRaw('users.*, (
                6371 * acos(
                    cos(radians(?)) * cos(radians(location_lat)) * cos(radians(location_lng) - radians(?)) +
                    sin(radians(?)) * sin(radians(location_lat))
                )
            ) AS distance', [$lat, $lng, $lat])
            ->having('distance', '<=', $radius)
            ->orderBy('distance');
        }

        $tailors = $query->paginate(20);

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar penjahit berhasil diambil.',
            'data' => [
                'tailors' => $tailors->items(),
                'meta' => [
                    'current_page' => $tailors->currentPage(),
                    'per_page' => $tailors->perPage(),
                    'total' => $tailors->total(),
                ],
            ],
        ]);
    }

    public function show(User $tailor): JsonResponse
    {
        $tailor->load(['reviewsAsTailor', 'favoriteTailors']);

        return response()->json([
            'status' => 'success',
            'message' => 'Detail penjahit berhasil diambil.',
            'data' => [
                'tailor' => $tailor,
                'portfolio' => $tailor->portfolio ?? [],
                'reviews' => $tailor->reviewsAsTailor,
            ],
        ]);
    }

    public function addFavorite(Request $request): JsonResponse
    {
        $request->validate(['tailor_id' => 'required|exists:users,id']);

        $favorite = FavoriteTailor::firstOrCreate([
            'customer_id' => $request->user()->id,
            'tailor_id' => $request->tailor_id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Penjahit ditambahkan ke favorit.',
            'data' => ['favorite' => $favorite],
        ], 201);
    }

    public function favorites(Request $request): JsonResponse
    {
        $favorites = FavoriteTailor::with('tailor')
            ->where('customer_id', $request->user()->id)
            ->get()
            ->map(fn ($favorite) => $favorite->tailor);

        return response()->json([
            'status' => 'success',
            'message' => 'Favorit berhasil diambil.',
            'data' => ['favorites' => $favorites],
        ]);
    }

    public function removeFavorite(Request $request, FavoriteTailor $favorite): JsonResponse
    {
        if ($favorite->customer_id !== $request->user()->id) {
            return response()->json(['status' => 'error', 'message' => 'Akses ditolak.', 'data' => null], 403);
        }

        $favorite->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Penjahit dihapus dari favorit.',
            'data' => null,
        ]);
    }
}
