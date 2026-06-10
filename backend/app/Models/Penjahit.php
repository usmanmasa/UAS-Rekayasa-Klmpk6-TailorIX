<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Penjahit extends Model
{
    use HasFactory;

    protected $table = 'penjahits';

    protected $fillable = [
        'nama',
        'alamat',
        'latitude',
        'longitude',
        'kategori',
        'rating',
        'harga',
        'status',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'rating' => 'float',
        'harga' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'id', 'id');
    }

    public function getDeviceTokenAttribute($value)
    {
        return $value ?: $this->user?->device_token;
    }
}
