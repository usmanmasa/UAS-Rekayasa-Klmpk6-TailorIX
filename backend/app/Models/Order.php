<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'tailor_id',
        'category',
        'description',
        'deadline',
        'delivery_mode',
        'status',
        'estimated_price_min',
        'estimated_price_max',
        'agreed_price',
        'final_price',
        'confidence',
        'tailor_notes',
        'accepted_at',
        'cancelled_at',
    ];

    protected $casts = [
        'deadline' => 'date',
        'accepted_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'estimated_price_min' => 'decimal:2',
        'estimated_price_max' => 'decimal:2',
        'agreed_price' => 'decimal:2',
        'final_price' => 'decimal:2',
        'confidence' => 'decimal:2',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function tailor()
    {
        return $this->belongsTo(User::class, 'tailor_id');
    }

    public function photos()
    {
        return $this->hasMany(OrderPhoto::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function timelines()
    {
        return $this->hasMany(OrderTimeline::class);
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }
}
