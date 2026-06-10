<?php

namespace App\Models;

use App\Models\Penjahit;
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
        'estimated_price_min' => 'float',
        'estimated_price_max' => 'float',
        'agreed_price' => 'float',
        'final_price' => 'float',
        'confidence' => 'float',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function tailor()
    {
        return $this->belongsTo(Penjahit::class, 'tailor_id');
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
