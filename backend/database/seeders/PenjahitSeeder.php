<?php

namespace Database\Seeders;

use App\Models\Penjahit;
use Illuminate\Database\Seeder;

class PenjahitSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $penjahits = [
            [
                'nama' => 'Bu Sari Taylor',
                'alamat' => 'Jl. Sudirman No.12, Bandung',
                'latitude' => -6.9175,
                'longitude' => 107.6191,
                'kategori' => 'Alterasi',
                'rating' => 4.9,
                'harga' => 80000,
                'status' => 'buka',
            ],
            [
                'nama' => 'Pak Andi Tailor',
                'alamat' => 'Jl. Dago No.45, Bandung',
                'latitude' => -6.8951,
                'longitude' => 107.6099,
                'kategori' => 'Jahit Custom',
                'rating' => 4.7,
                'harga' => 150000,
                'status' => 'tutup',
            ],
            [
                'nama' => 'Jahit Cepat Mba Rina',
                'alamat' => 'Jl. Cihampelas No.78, Bandung',
                'latitude' => -6.8983,
                'longitude' => 107.6066,
                'kategori' => 'Permak',
                'rating' => 4.8,
                'harga' => 100000,
                'status' => 'buka',
            ],
            [
                'nama' => 'Tailor Mang Ujang',
                'alamat' => 'Jl. Braga No.22, Bandung',
                'latitude' => -6.9214,
                'longitude' => 107.6079,
                'kategori' => 'Jas Formal',
                'rating' => 4.6,
                'harga' => 90000,
                'status' => 'buka',
            ],
            [
                'nama' => 'Bu Dewi Fashion',
                'alamat' => 'Jl. Buah Batu No.33, Bandung',
                'latitude' => -6.9401,
                'longitude' => 107.6318,
                'kategori' => 'Kebaya',
                'rating' => 4.5,
                'harga' => 120000,
                'status' => 'tutup',
            ],
            [
                'nama' => 'Tailor Pak Hendra',
                'alamat' => 'Jl. Setiabudhi No.101, Bandung',
                'latitude' => -6.8711,
                'longitude' => 107.5997,
                'kategori' => 'Seragam',
                'rating' => 4.8,
                'harga' => 110000,
                'status' => 'buka',
            ],
        ];

        foreach ($penjahits as $penjahit) {
            Penjahit::updateOrCreate([
                'nama' => $penjahit['nama'],
            ], $penjahit);
        }
    }
}
