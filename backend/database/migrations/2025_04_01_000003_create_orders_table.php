<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('tailor_id')->constrained('users')->cascadeOnDelete();
            $table->string('category');
            $table->text('description')->nullable();
            $table->date('deadline')->nullable();
            $table->string('delivery_mode')->default('dropoff');
            $table->string('status')->default('waiting_confirmation');
            $table->decimal('estimated_price_min', 12, 2)->nullable();
            $table->decimal('estimated_price_max', 12, 2)->nullable();
            $table->decimal('agreed_price', 12, 2)->nullable();
            $table->decimal('final_price', 12, 2)->nullable();
            $table->decimal('confidence', 5, 2)->nullable();
            $table->text('tailor_notes')->nullable();
            $table->timestamps();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
