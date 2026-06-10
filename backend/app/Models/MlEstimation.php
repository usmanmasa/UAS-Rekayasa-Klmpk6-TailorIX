<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MlEstimation extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'category',
        'description',
        'photos',
        'min_price',
        'max_price',
        'confidence',
        'analysis',
    ];

    protected $casts = [
        'photos' => 'array',
        'analysis' => 'array',
        'min_price' => 'float',
        'max_price' => 'float',
        'confidence' => 'float',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
