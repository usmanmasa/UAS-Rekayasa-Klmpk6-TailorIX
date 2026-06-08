<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class TailorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tailors = [
            [
                'name' => 'Admin TailoriX',
                'email' => 'admin@tailorix.com',
                'password' => Hash::make('admin123'),
                'phone' => '081122334455',
                'address' => 'Jakarta',
                'role' => 'admin',
                'is_verified' => true,
            ],
            [
                'name' => 'Melvy Sari',
                'email' => 'melvy.tailor@example.com',
                'password' => Hash::make('password'),
                'phone' => '081234567890',
                'address' => 'Jl. Sudirman No. 45, Jakarta',
                'profile_photo_url' => 'https://ui-avatars.com/api/?name=Melvy+Sari',
                'role' => 'tailor',
                'shop_name' => 'Melvy Sewing Studio',
                'location_lat' => -6.200000,
                'location_lng' => 106.816666,
                'specializations' => ['jahitan wanita', 'jahitan pria', 'batik', 'kebaya'],
                'portfolio' => [
                    'Pembuatan dress custom',
                    'Jasa jahit jas pria',
                    'Konveksi kebaya modern',
                ],
                'is_available' => true,
                'rating' => 4.8,
                'rating_count' => 132,
                'verification_document_url' => 'https://example.com/documents/melvy-id.jpg',
                'is_verified' => true,
            ],
            [
                'name' => 'Dewi Permata',
                'email' => 'dewi.tailor@example.com',
                'password' => Hash::make('password'),
                'phone' => '082345678901',
                'address' => 'Jl. Braga No. 12, Bandung',
                'profile_photo_url' => 'https://ui-avatars.com/api/?name=Dewi+Permata',
                'role' => 'tailor',
                'shop_name' => "Dewi's Fashion House",
                'location_lat' => -6.914744,
                'location_lng' => 107.609810,
                'specializations' => ['gaun pesta', 'kebaya', 'jahit bordir'],
                'portfolio' => [
                    'Gaun pesta custom',
                    'Kebaya wisuda',
                    'Jahit bordir detail',
                ],
                'is_available' => true,
                'rating' => 4.7,
                'rating_count' => 95,
                'verification_document_url' => 'https://example.com/documents/dewi-id.jpg',
                'is_verified' => true,
            ],
            [
                'name' => 'Raka Putra',
                'email' => 'raka.tailor@example.com',
                'password' => Hash::make('password'),
                'phone' => '083456789012',
                'address' => 'Jl. Pemuda No. 77, Surabaya',
                'profile_photo_url' => 'https://ui-avatars.com/api/?name=Raka+Putra',
                'role' => 'tailor',
                'shop_name' => 'Raka Tailor & Repair',
                'location_lat' => -7.257472,
                'location_lng' => 112.752088,
                'specializations' => ['jas pria', 'seragam kantor', 'perbaikan pakaian'],
                'portfolio' => [
                    'Jas custom premium',
                    'Seragam kantor rapi',
                    'Layanan perbaikan pakaian',
                ],
                'is_available' => true,
                'rating' => 4.6,
                'rating_count' => 88,
                'verification_document_url' => 'https://example.com/documents/raka-id.jpg',
                'is_verified' => true,
            ],
            [
                'name' => 'Intan Lestari',
                'email' => 'intan.tailor@example.com',
                'password' => Hash::make('password'),
                'phone' => '085678901234',
                'address' => 'Jl. Malioboro No. 14, Yogyakarta',
                'profile_photo_url' => 'https://ui-avatars.com/api/?name=Intan+Lestari',
                'role' => 'tailor',
                'shop_name' => 'Intan Bridal Tailor',
                'location_lat' => -7.797068,
                'location_lng' => 110.370529,
                'specializations' => ['bridal', 'kebaya', 'gaun malam'],
                'portfolio' => [
                    'Kebaya pengantin',
                    'Gaun malam elegan',
                    'Bridal makeup garment',
                ],
                'is_available' => true,
                'rating' => 4.9,
                'rating_count' => 158,
                'verification_document_url' => 'https://example.com/documents/intan-id.jpg',
                'is_verified' => true,
            ],
            [
                'name' => 'Arif Santoso',
                'email' => 'arif.tailor@example.com',
                'password' => Hash::make('password'),
                'phone' => '081987654321',
                'address' => 'Jl. Pemuda No. 5, Semarang',
                'profile_photo_url' => 'https://ui-avatars.com/api/?name=Arif+Santoso',
                'role' => 'tailor',
                'shop_name' => 'Arif Konveksi',
                'location_lat' => -6.966667,
                'location_lng' => 110.416664,
                'specializations' => ['seragam', 'jahit kantor', 'kemeja'],
                'portfolio' => [
                    'Seragam kantor tahan lama',
                    'Kemeja formal',
                    'Konveksi pesanan besar',
                ],
                'is_available' => true,
                'rating' => 4.5,
                'rating_count' => 74,
                'verification_document_url' => 'https://example.com/documents/arif-id.jpg',
                'is_verified' => true,
            ],
        ];

        foreach ($tailors as $tailor) {
            User::updateOrCreate([
                'email' => $tailor['email'],
            ], $tailor);
        }
    }
}
