<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'customer_id',
        'tailor_id',
        'rating',
        'comment',
        'photos',
        'reply_text',
        'reported',
        'status',
    ];

    protected $casts = [
        'photos' => 'array',
        'reported' => 'boolean',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function tailor()
    {
        return $this->belongsTo(User::class, 'tailor_id');
    }
}
