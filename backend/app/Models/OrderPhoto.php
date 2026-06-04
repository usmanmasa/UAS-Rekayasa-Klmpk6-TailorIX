<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderPhoto extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'path',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
