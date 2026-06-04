<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('customer')->after('id');
            $table->string('phone')->nullable()->after('email');
            $table->string('address')->nullable()->after('phone');
            $table->string('profile_photo_url')->nullable()->after('address');
            $table->boolean('is_verified')->default(false)->after('profile_photo_url');
            $table->string('shop_name')->nullable()->after('is_verified');
            $table->decimal('location_lat', 10, 7)->nullable()->after('shop_name');
            $table->decimal('location_lng', 10, 7)->nullable()->after('location_lat');
            $table->json('specializations')->nullable()->after('location_lng');
            $table->json('portfolio')->nullable()->after('specializations');
            $table->boolean('is_available')->default(true)->after('portfolio');
            $table->decimal('rating', 3, 2)->default(0)->after('is_available');
            $table->unsignedInteger('rating_count')->default(0)->after('rating');
            $table->string('verification_document_url')->nullable()->after('rating_count');
            $table->string('remember_token', 100)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'role',
                'phone',
                'address',
                'profile_photo_url',
                'is_verified',
                'shop_name',
                'location_lat',
                'location_lng',
                'specializations',
                'portfolio',
                'is_available',
                'rating',
                'rating_count',
                'verification_document_url',
            ]);
        });
    }
};
