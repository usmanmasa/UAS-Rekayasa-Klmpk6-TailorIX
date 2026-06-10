<?php

use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MlController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\PenjahitController;
use App\Http\Controllers\TailorController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/penjahit', [PenjahitController::class, 'index']);

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/ml/estimate', [MlController::class, 'estimate']);
    Route::post('/ml/feedback', [MlController::class, 'feedback']);
    Route::post('/payments/webhook', [PaymentController::class, 'webhook']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::post('/auth/refresh', [AuthController::class, 'refresh']);
        Route::put('/profile', [ProfileController::class, 'update']);
        Route::patch('/profile/device-token', [ProfileController::class, 'updateDeviceToken']);

        Route::get('/tailors', [TailorController::class, 'index']);
        Route::get('/tailors/{id}', [TailorController::class, 'show']);
        Route::post('/customers/favorites', [TailorController::class, 'addFavorite']);
        Route::delete('/customers/favorites/{id}', [TailorController::class, 'removeFavorite']);

        Route::post('/orders', [OrderController::class, 'store']);
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/orders/{id}', [OrderController::class, 'show']);
        Route::patch('/orders/{id}/confirm', [OrderController::class, 'confirm']);
        Route::patch('/orders/{id}/accept', [OrderController::class, 'accept']);
        Route::patch('/orders/{id}/reject', [OrderController::class, 'reject']);
        Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);
        Route::delete('/orders/{id}', [OrderController::class, 'destroy']);

        Route::middleware('role:admin')->prefix('admin')->group(function () {
            Route::get('/summary', [AdminController::class, 'summary']);
            Route::get('/users', [AdminController::class, 'users']);
            Route::get('/users/{id}', [AdminController::class, 'showUser']);
            Route::put('/users/{id}', [AdminController::class, 'updateUser']);
            Route::delete('/users/{id}', [AdminController::class, 'destroyUser']);
            Route::get('/tailors', [AdminController::class, 'tailors']);
            Route::post('/tailors', [AdminController::class, 'storeTailor']);
            Route::put('/tailors/{id}', [AdminController::class, 'updateTailor']);
            Route::delete('/tailors/{id}', [AdminController::class, 'destroyTailor']);
            Route::get('/orders', [AdminController::class, 'orders']);
        });

        Route::post('/payments', [PaymentController::class, 'store']);
        Route::get('/payments/{id}', [PaymentController::class, 'show']);
        Route::post('/payments/{id}/refund', [PaymentController::class, 'refund']);

        Route::post('/reviews', [ReviewController::class, 'store']);
        Route::get('/reviews/{id}', [ReviewController::class, 'show']);
        Route::put('/reviews/{id}', [ReviewController::class, 'update']);
        Route::post('/reviews/{id}/reply', [ReviewController::class, 'reply']);
        Route::post('/reviews/{id}/report', [ReviewController::class, 'report']);
    });
});
