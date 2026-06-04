<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ml_estimations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->string('category');
            $table->text('description')->nullable();
            $table->json('photos')->nullable();
            $table->decimal('min_price', 12, 2);
            $table->decimal('max_price', 12, 2);
            $table->decimal('confidence', 5, 2);
            $table->json('analysis')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ml_estimations');
    }
};
