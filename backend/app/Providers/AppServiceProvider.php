<?php

namespace App\Providers;

use Database\Seeders\PenjahitSeeder;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (Schema::hasTable('penjahits')) {
            try {
                if (\App\Models\Penjahit::count() === 0) {
                    (new PenjahitSeeder())->run();
                }
            } catch (\Throwable $e) {
                // Jika tabel belum siap atau migrasi sedang berjalan, abaikan.
            }
        }
    }
}
